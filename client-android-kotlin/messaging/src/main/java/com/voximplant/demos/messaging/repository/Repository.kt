package com.voximplant.demos.messaging.repository

import android.content.Context
import android.util.Log
import androidx.lifecycle.MutableLiveData
import androidx.room.Room
import com.voximplant.demos.messaging.entity.*
import com.voximplant.demos.messaging.entity.ConversationType.*
import com.voximplant.demos.messaging.entity.events.MessageEventAction.*
import com.voximplant.demos.messaging.entity.events.MessengerEvent
import com.voximplant.demos.messaging.entity.events.MessengerEvent.ConversationEvent
import com.voximplant.demos.messaging.entity.events.MessengerEvent.MessageEvent
import com.voximplant.demos.messaging.manager.VoxClientManagerListener
import com.voximplant.demos.messaging.repository.Repository.RefreshState.READY
import com.voximplant.demos.messaging.repository.Repository.RefreshState.REFRESHING
import com.voximplant.demos.messaging.repository.local.AppDatabase
import com.voximplant.demos.messaging.repository.remote.VoxAPIService
import com.voximplant.demos.messaging.repository.remote.VoximplantService
import com.voximplant.demos.messaging.repository.remote.VoximplantServiceListener
import com.voximplant.demos.messaging.repository.utils.*
import com.voximplant.demos.messaging.utils.APP_TAG
import com.voximplant.demos.messaging.utils.contains
import com.voximplant.demos.messaging.utils.ifNull
import com.voximplant.demos.messaging.utils.permissions.Permissions
import com.voximplant.demos.messaging.utils.permissions.defaultAdminPermissions
import com.voximplant.demos.messaging.utils.permissions.defaultPermissions
import com.voximplant.demos.messaging.utils.preferences.getLongFromPrefs
import com.voximplant.demos.messaging.utils.preferences.removeKeyFromPrefs
import com.voximplant.demos.messaging.utils.preferences.saveToPrefs
import com.voximplant.sdk.Voximplant
import com.voximplant.sdk.messaging.*
import com.voximplant.sdk.messaging.MessengerAction.IS_READ
import kotlinx.coroutines.*
import kotlin.coroutines.CoroutineContext
import kotlin.coroutines.resume
import kotlin.coroutines.suspendCoroutine

interface RepositoryDataStateNotifier {
    fun dataUpdated()
}

class Repository(private val context: Context) : VoximplantServiceListener, VoxClientManagerListener, CoroutineScope {

    override val coroutineContext: CoroutineContext
        get() = Dispatchers.IO + job

    private val job = Job()

    private val local = Room
        .databaseBuilder(context, AppDatabase::class.java, "messaging-database")
        .build()
    private val remote = VoximplantService(Voximplant.getMessenger())
    private val apiService = VoxAPIService()
    private val builder = ModelBuilder()

    private var dataStateNotifier: RepositoryDataStateNotifier? = null
    private var listener: RepositoryListener? = null

    val users = local.userDao().getAll()
    val conversations = local.conversationDao().getAll()

    val activeConversation = MutableLiveData<Conversation?>()

    var me: Long?
        get() = MY_IMID.getLongFromPrefs(context)
        set(value) {
            value?.saveToPrefs(context, MY_IMID) ?: MY_IMID.removeKeyFromPrefs(context)
        }

    private enum class RefreshState { READY, REFRESHING }
    private var needsRefresh: Boolean = false
    private var refreshState: RefreshState = READY

    init {
        remote.setListener(this)
    }

    fun setListener(listener: RepositoryListener) {
        this.listener = listener
    }

    fun setDataNotifier(dataNotifier: RepositoryDataStateNotifier) {
        this.dataStateNotifier = dataNotifier
    }

    fun changeStoredActiveConversation(uuid: String?) {
        if (uuid == null) {
            activeConversation.postValue(null)
        } else {
            activeConversation.postValue(conversations.value?.first { it.uuid == uuid })
        }
    }

    //region VoxClientManagerListener
    override fun onLoginSuccess(displayName: String) {
        launch {
            super.onLoginSuccess(displayName)

            refreshData()
        }
    }

    override fun onLogout() {
        launch {
            super.onLogout()

            local.participantDao().deleteAll()
            local.conversationEventDao().deleteAll()
            local.messageEventDao().deleteAll()
            local.conversationDao().deleteAll()
            local.userDao().deleteAll()
            me = null

            refreshState = READY
            needsRefresh = false

            Log.e(APP_TAG, "data removed")
        }
    }
    //endregion

    //region Data updates
    suspend fun refreshData() {
        withContext(coroutineContext) {
            if (refreshState == REFRESHING) {
                return@withContext
            }
            refreshState = REFRESHING

            val usernames = apiService.getVoxUsernames()
                .takeIf { it.isNotEmpty() }
                .ifNull {
                    refreshState = READY
                    listener?.failedToConnectToBackend()
                    return@withContext
                }

            val voxUsers = requestVoxUsers(usernames)
                .ifNull { return@withContext }

            if (needsRefresh) {
                refreshState = READY
                needsRefresh = false
                refreshData()
                return@withContext
            }

            local.userDao().deleteAll()
            local.userDao().insertAllUsers(voxUsers.map { builder.buildUser(it) })

            val username = remote.myUsername
                .ifNull { return@withContext }

            val me = voxUsers.first {
                it.name == username
            }

            me.imId.saveToPrefs(context, MY_IMID)

            val list = me.conversationList ?: return@withContext

            if (list.size == 0) {
                local.conversationDao().deleteAll()
                return@withContext
            }

            val voxConversations = requestVoxConversations(list)
                .ifNull { return@withContext }

            if (needsRefresh) {
                refreshState = READY
                needsRefresh = false
                refreshData()
                return@withContext
            }

            val actualConversations = voxConversations.map { builder.buildConversation(it) }
            local.conversationDao().deleteAll()
            local.conversationDao().insertAllConversations(actualConversations)

            voxConversations.forEach { voxConversation ->
                local.participantDao().deleteAllWithUUID(voxConversation.uuid)
                local.participantDao().insertAll(voxConversation.participants.map {
                    builder.buildParticipant(it, voxConversation.uuid)
                })
            }

            refreshState = READY
            needsRefresh = false
        }
    }

    private suspend fun requestVoxUsers(
        usernames: List<String>
    ) = suspendCoroutine<List<IUser>?> { continuation ->
        remote.requestUsersWithUsernames(usernames) { result ->
            result.onFailure {
                continuation.resume(null)
                return@requestUsersWithUsernames
            }
            result.onSuccess { continuation.resume(it) }
        }
    }

    private suspend fun requestVoxConversations(
        uuids: List<String>
    ) = suspendCoroutine<List<IConversation>?> { continuation ->
        val requestChunk = 30 // maximum conversations per request on Voximplant SDK is 30

        val numberOfIterations = if (uuids.size % requestChunk > 0) {
            uuids.size / requestChunk + 1
        } else {
            uuids.size / requestChunk
        }

        var iterationsLeft = numberOfIterations

        val allVoxConversations: MutableList<IConversation> = mutableListOf()

        for (iteration in 0 until numberOfIterations) {

            val min = iteration * requestChunk
            var max = (uuids.size - 1) - (uuids.size - ((iteration + 1) * requestChunk))

            while (max >= uuids.size) {
                max -= 1
            }

            val croppedList = uuids.subList(min, max + 1)

            remote.requestMultipleConversations(croppedList) { result ->
                iterationsLeft--

                result.onSuccess { voxConversations ->
                    allVoxConversations.addAll(voxConversations)
                }

                if (iterationsLeft == 0) {
                    continuation.resume(allVoxConversations)
                }
            }
        }
    }
    //endregion

    //region Create Conversation
    suspend fun createDirectConversation(
        user: User
    ) = withContext(coroutineContext) {
        val voxParticipants = listOf(builder.buildDefaultVoxParticipant(user.imId, DIRECT))

        val customData: CustomData = mutableMapOf()
        customData.type = DIRECT.stringValue
        customData.permissions = defaultPermissions(DIRECT)

        val builder = ConversationConfig.createBuilder()
            .setTitle("")
            .setDirect(true)
            .setUber(false)
            .setPublicJoin(false)
            .setParticipants(voxParticipants)
            .setCustomData(customData)

        createConversation(builder.build())
    }

    suspend fun createGroupConversation(
        title: String,
        users: List<User>,
        description: String?,
        pictureName: String?,
        isPublic: Boolean,
        isUber: Boolean
    ) = withContext(coroutineContext) {
        val builder = ConversationConfig.createBuilder()
            .setTitle(title)
            .setDirect(false)
            .setUber(isUber)
            .setPublicJoin(isPublic)
            .setParticipants(users.map { builder.buildDefaultVoxParticipant(it.imId, CHAT) })
            .setCustomData(builder.buildCustomData(CHAT, pictureName, description))

        createConversation(builder.build())
    }

    suspend fun createChannel(
        title: String,
        users: List<User>,
        description: String?,
        pictureName: String?
    ) = withContext(coroutineContext) {
        val builder = ConversationConfig.createBuilder()
            .setTitle(title)
            .setDirect(false)
            .setUber(false)
            .setPublicJoin(true)
            .setParticipants(users.map { builder.buildDefaultVoxParticipant(it.imId, CHAT) })
            .setCustomData(builder.buildCustomData(CHANNEL, pictureName, description))

        createConversation(builder.build())
    }

    private suspend fun createConversation(
        config: ConversationConfig
    ) = suspendCoroutine<Boolean> { continuation ->
        remote.createConversation(config) { result ->
            result.onFailure { continuation.resume(false) }
            result.onSuccess { voxConversationEvent ->
                local.conversationEventDao()
                    .insert(builder.buildConversationEvent(voxConversationEvent))
                local.conversationDao()
                    .insert(builder.buildConversation(voxConversationEvent.conversation))
                local.participantDao()
                    .deleteAllWithUUID(voxConversationEvent.conversation.uuid)
                local.participantDao()
                    .insertAll(voxConversationEvent.conversation.participants
                        .map { builder.buildParticipant(it, voxConversationEvent.conversation.uuid) })
                continuation.resume(true)
            }
        }
    }
    //endregion

    //region Participants
    suspend fun requestParticipant(
        conversationUUID: String,
        imId: Long
    ) = withContext(coroutineContext) {
        local.participantDao().getByImId(imId, conversationUUID)
    }

    suspend fun requestParticipants(
        conversationUUID: String,
        imIDs: List<Long>
    ) = withContext(coroutineContext) {
        local.participantDao().getAllByImId(imIDs, conversationUUID)
    }

    suspend fun requestParticipants(
        conversationUUID: String
    ) = withContext(coroutineContext) {
        local.participantDao().getAllByConversation(conversationUUID)
    }
    //endregion

    //region Edit Participants
    suspend fun addUsersToConversation(
        users: List<User>,
        conversation: Conversation
    ) = suspendCoroutine<Boolean> { continuation ->
        val voxConversation = recreateConversation(conversation)
            .ifNull {
                continuation.resume(false)
                return@suspendCoroutine
            }

        val conversationType = ConversationType.from(
            conversation.customData.type ?: CHAT.stringValue
        )

        val voxParticipants = users
            .map { builder.buildDefaultVoxParticipant(it.imId, conversationType) }

        remote.addParticipants(voxParticipants, voxConversation) { result ->
            result.onFailure { continuation.resume(false) }
            result.onSuccess { voxConversationEvent ->
                local.conversationEventDao()
                    .insert(builder.buildConversationEvent(voxConversationEvent))
                local.conversationDao()
                    .insert(builder.buildConversation(voxConversationEvent.conversation))
                local.participantDao()
                    .insertAll(voxParticipants
                        .map {builder.buildParticipant(it, voxConversationEvent.conversation.uuid) })

                if (activeConversation.value?.uuid == voxConversationEvent.conversation.uuid) {
                    activeConversation.postValue(
                        local.conversationDao().loadByUUID(
                            voxConversationEvent.conversation.uuid
                        )
                    )
                }

                continuation.resume(true)
            }
        }
    }

    suspend fun removeUsersFromConversation(
        users: List<User>, conversation: Conversation
    ) = withContext(coroutineContext) {
        async {
            val participants = requestParticipants(conversation.uuid, users.map { it.imId })

            if (participants.size != users.size) {
                return@async false
            }

            return@async removeParticipants(participants, conversation)
        }.await()
    }

    suspend fun addAdmins(
        users: List<User>, conversation: Conversation
    ) = withContext(coroutineContext) {
        async {
            val participants = requestParticipants(conversation.uuid, users.map { it.imId })
            if (participants.size != users.size) {
                return@async false
            }

            participants.forEach { participant ->
                participant.isOwner = true
                participant.permissions = defaultAdminPermissions()
            }

            return@async editParticipants(participants, conversation)
        }.await()
    }

    suspend fun removeAdmins(
        users: List<User>, conversation: Conversation
    ) = withContext(coroutineContext) {
        async {
            val participants = requestParticipants(conversation.uuid, users.map { it.imId })
            if (participants.size != users.size) {
                return@async false
            }

            participants.forEach { participant ->
                participant.isOwner = false
                participant.permissions =
                    conversation.customData.permissions ?: return@async false
            }

            return@async editParticipants(participants, conversation)
        }.await()
    }

    private suspend fun removeParticipants(
        participants: List<Participant>,
        conversation: Conversation
    ) = suspendCoroutine<Boolean> { continuation ->
        val voxConversation = recreateConversation(conversation)
            .ifNull {
                continuation.resume(false)
                return@suspendCoroutine
            }

        val voxParticipants = participants
            .map { builder.buildVoxParticipant(it) }

        remote.removeParticipants(voxParticipants, voxConversation) { result ->
            result.onFailure { continuation.resume(false) }
            result.onSuccess { voxConversationEvent ->
                local.conversationEventDao()
                    .insert(builder.buildConversationEvent(voxConversationEvent))
                local.conversationDao()
                    .insert(builder.buildConversation(voxConversationEvent.conversation))
                local.participantDao()
                    .deleteAllWithImIds(voxParticipants.map { it.imUserId }, voxConversation.uuid)

                if (activeConversation.value?.uuid == voxConversationEvent.conversation.uuid) {
                    activeConversation.postValue(
                        local.conversationDao().loadByUUID(
                            voxConversationEvent.conversation.uuid
                        )
                    )
                }

                continuation.resume(true)
            }
        }
    }

    private suspend fun editParticipants(
        participants: List<Participant>,
        conversation: Conversation
    ) = suspendCoroutine<Boolean> { continuation ->
        val voxConversation = recreateConversation(conversation)
            .ifNull {
                continuation.resume(false)
                return@suspendCoroutine
            }

        val voxParticipants = participants.map { builder.buildVoxParticipant(it) }

        remote.editParticipants(voxParticipants, voxConversation) { result ->
            result.onFailure { continuation.resume(false) }
            result.onSuccess { voxConversationEvent ->
                local.conversationEventDao()
                    .insert(builder.buildConversationEvent(voxConversationEvent))
                local.conversationDao()
                    .insert(builder.buildConversation(voxConversationEvent.conversation))
                local.participantDao()
                    .insertAll(participants)

                if (activeConversation.value?.uuid == voxConversationEvent.conversation.uuid) {
                    activeConversation.postValue(
                        local.conversationDao().loadByUUID(
                            voxConversationEvent.conversation.uuid
                        )
                    )
                }

                continuation.resume(true)
            }
        }
    }
    //endregion

    //region Update Conversation
    suspend fun updateConversation(
        conversation: Conversation,
        title: String,
        description: String?,
        pictureName: String?,
        isPublic: Boolean
    ) = withContext(coroutineContext) {

        val voxConversation = recreateConversation(conversation)
            .ifNull { return@withContext false }

        voxConversation.title = title
        voxConversation.isPublicJoin = isPublic
        voxConversation.customData.image = pictureName
        voxConversation.customData.chatDescription = description

        updateConversation(voxConversation)
    }

    suspend fun updateConversation(
        conversation: Conversation,
        permissions: Permissions
    ) = withContext(coroutineContext) {

        if (conversation.customData.permissions == permissions) {
            return@withContext false
        }

        val voxConversation = recreateConversation(conversation)
            .ifNull { return@withContext false }

        voxConversation.customData.permissions = permissions

        updateConversation(voxConversation)
    }

    private suspend fun updateConversation(
        voxConversation: IConversation
    ) = suspendCoroutine<Boolean> { continuation ->
        remote.updateConversation(voxConversation) { result ->
            result.onFailure { continuation.resume(false) }
            result.onSuccess { voxConversationEvent ->
                local.conversationEventDao()
                    .insert(builder.buildConversationEvent(voxConversationEvent))
                local.conversationDao()
                    .insert(builder.buildConversation(voxConversationEvent.conversation))

                if (activeConversation.value?.uuid == voxConversationEvent.conversation.uuid) {
                    activeConversation.postValue(
                        local.conversationDao().loadByUUID(
                            voxConversationEvent.conversation.uuid
                        )
                    )
                }

                continuation.resume(true)
            }
        }
    }
    //endregion

    //region Leave Conversation
    suspend fun leaveConversation(
        uuid: String
    ) = suspendCoroutine<Boolean> { continuation ->
        remote.leaveConversation(uuid) { result ->
            result.onFailure { continuation.resume(false) }
            result.onSuccess { voxConversationEvent ->
                needsRefresh = true
                local.conversationEventDao()
                    .insert(builder.buildConversationEvent(voxConversationEvent))
                local.conversationDao()
                    .delete(builder.buildConversation(voxConversationEvent.conversation))

                continuation.resume(true)
            }
        }
    }
    //endregion

    //region Request User
    suspend fun requestUser(
        imId: Long
    ) = withContext(coroutineContext) {
        local.userDao().loadUserByImId(imId)
    }

    suspend fun requestUsers(
        imIDs: List<Long>
    ) = withContext(coroutineContext) {

        if (imIDs.isEmpty()) {
            return@withContext listOf<User>()
        }

        local.userDao().loadAllByImIds(imIDs)
    }
    //endregion

    //region Edit User
    suspend fun editUser(
        status: String?, imageName: String?
    ) = suspendCoroutine<Boolean> { continuation ->

        val customData: CustomData = mutableMapOf()
        customData.image = imageName
        customData.status = status

        remote.editUser(customData) { result ->
            result.onFailure { continuation.resume(false) }
            result.onSuccess {
                local.userDao().insertUser(builder.buildUser(it.user))
                continuation.resume(true)
            }
        }
    }
    //endregion

    //region Message
    suspend fun sendMessage(
        text: String,
        conversation: Conversation
    ) = suspendCoroutine<Boolean> { continuation ->

        val voxConversation = recreateConversation(conversation)
            .ifNull {
                continuation.resume(false)
                return@suspendCoroutine
            }

        remote.sendMessage(text, voxConversation) { result ->
            result.onFailure { continuation.resume(false) }
            result.onSuccess { voxMessageEvent ->

                local.conversationDao().updateLastUpdated(
                    voxMessageEvent.timestamp,
                    voxMessageEvent.sequence,
                    voxMessageEvent.message.conversation
                )

                local.participantDao().updateLastRead(
                    voxMessageEvent.sequence,
                    voxMessageEvent.imUserId,
                    voxMessageEvent.message.conversation
                )

                local.messageEventDao().insert(builder.buildMessageEvent(voxMessageEvent))

                if (voxMessageEvent.message.conversation == activeConversation.value?.uuid) {
                    activeConversation
                        .postValue(
                            local.conversationDao().loadByUUID(voxMessageEvent.message.conversation)
                        )
                    dataStateNotifier?.dataUpdated()
                }

                needsRefresh = true

                continuation.resume(true)
            }
        }
    }

    suspend fun findMessage(
        sequence: Long,
        conversationUUID: String
    ) = withContext(coroutineContext) {
        val message = (requestMessengerEvent(conversationUUID, sequence) as? MessageEvent)?.message
            .ifNull { return@withContext null }

        val messageMentions = local.messageEventDao().getAll(conversationUUID)
            .takeIf { it.isNotEmpty() }
            .ifNull { return@withContext null }
            .map { it.message }
            .filter { it.uuid == message.uuid }
            .sortedBy { it.sequence }

        return@withContext messageMentions.last()
    }

    suspend fun findAndRemoveMessage(
        sequence: Long,
        conversation: Conversation
    ) = withContext(coroutineContext) {

        val message = findMessage(sequence, conversation.uuid)
            .ifNull { return@withContext false }

        removeMessage(message.uuid, conversation)
    }

    suspend fun findAndEditMessage(
        sequence: Long,
        text: String,
        conversation: Conversation
    ) = withContext(coroutineContext) {

        val message = findMessage(sequence, conversation.uuid)
            ?.takeIf { it.text != text }
            .ifNull { return@withContext false }

        editMessage(message.uuid, conversation, text)
    }

    private suspend fun removeMessage(
        uuid: String,
        conversation: Conversation
    ) = suspendCoroutine<Boolean> { continuation ->

        val voxMessage = recreateMessage(uuid, conversation.uuid)
            .ifNull {
                continuation.resume(false)
                return@suspendCoroutine
            }

        remote.removeMessage(voxMessage) { result ->
            result.onFailure { continuation.resume(false) }
            result.onSuccess { voxMessageEvent ->

                local.conversationDao().updateLastUpdated(
                    voxMessageEvent.timestamp,
                    voxMessageEvent.sequence,
                    voxMessageEvent.message.conversation
                )

                local.messageEventDao().insert(builder.buildMessageEvent(voxMessageEvent))

                if (voxMessageEvent.message.conversation == activeConversation.value?.uuid) {
                    activeConversation
                        .postValue(
                            local.conversationDao().loadByUUID(voxMessageEvent.message.conversation)
                        )
                    dataStateNotifier?.dataUpdated()
                }

                needsRefresh = true

                continuation.resume(true)
            }
        }
    }

    private suspend fun editMessage(
        uuid: String,
        conversation: Conversation,
        text: String
    ) = suspendCoroutine<Boolean> { continuation ->

        val voxMessage = recreateMessage(uuid, conversation.uuid)
            .ifNull {
                continuation.resume(false)
                return@suspendCoroutine
            }

        remote.editMessage(voxMessage, text) { result ->
            result.onFailure { continuation.resume(false) }
            result.onSuccess { voxMessageEvent ->

                local.conversationDao().updateLastUpdated(
                    voxMessageEvent.timestamp,
                    voxMessageEvent.sequence,
                    voxMessageEvent.message.conversation
                )

                local.messageEventDao().insert(builder.buildMessageEvent(voxMessageEvent))

                if (voxMessageEvent.message.conversation == activeConversation.value?.uuid) {
                    activeConversation
                        .postValue(
                            local.conversationDao().loadByUUID(voxMessageEvent.message.conversation)
                        )
                    dataStateNotifier?.dataUpdated()
                }

                needsRefresh = true

                continuation.resume(true)
            }
        }
    }
    //endregion

    //region Recreate
    private fun recreateMessage(uuid: String, conversationUUID: String) =
        remote.recreateMessage(uuid, conversationUUID)

    private fun recreateConversation(conversation: Conversation) =
        remote.recreateConversation(conversation.uuid, builder.buildConfig(conversation), conversation.lastSequence)
    //endregion

    //region Send Service Event
    fun markAsRead(sequence: Long, conversation: Conversation) {
        launch {
            if (conversation.checkLastRead(true) < sequence) {
                recreateConversation(conversation)?.let {
                    remote.markAsRead(sequence, it)
                }
            }
        }
    }

    fun sendTyping(conversation: Conversation) {
        launch {
            recreateConversation(conversation)?.let {
                remote.sendTyping(it)
            }
        }
    }
    //endregion

    //region Retransmit Events
    private suspend fun requestMessengerEvent(
        conversationUUID: String,
        sequence: Long
    ) = withContext(coroutineContext) {
        local.messageEventDao().get(conversationUUID, sequence)
            ?: local.conversationEventDao().get(conversationUUID, sequence)
    }

    suspend fun requestMessengerEvents(
        conversation: Conversation,
        numberOfEvents: Int,
        sequence: Long
    ) = withContext(coroutineContext) {

        val localEvents = getAllStoredEvents(conversation.uuid)

        if (localEvents.isEmpty()) {
            val remoteEvents = retransmitEvents(conversation, numberOfEvents, sequence)
                .ifNull { return@withContext Pair(listOf<EventWithAssociatedData>(), 1.toLong()) }

            saveEvents(remoteEvents)
            return@withContext Pair(
                prepareEventAssociatedData(processEvents(remoteEvents)),
                conversation.checkLastRead(false)
            )
        }

        val neededRangeMin = if (sequence - numberOfEvents > 1) {
            sequence - (numberOfEvents - 1)
        } else {
            1
        }
        val localEventsRange = LongRange(localEvents.first().sequence, localEvents.last().sequence)
        val neededEventsRange = LongRange((neededRangeMin), sequence)

        localEventsRange.contains(localEventsRange.first)

        if (localEventsRange.contains(neededEventsRange)) {
            val firstEventIndex = localEvents.indexOfFirst { it.sequence == neededEventsRange.first }
            val lastEventIndex = localEvents.indexOfFirst { it.sequence == neededEventsRange.last }

            val processedEvents = processEvents(localEvents.subList(
                firstEventIndex,
                lastEventIndex + 1)
            )
            return@withContext Pair(
                prepareEventAssociatedData(processedEvents),
                conversation.checkLastRead(false)
            )

        } else {
            val remoteEvents = retransmitEvents(conversation, numberOfEvents, sequence)
                .ifNull { return@withContext Pair(listOf<EventWithAssociatedData>(), 1.toLong()) }

            saveEvents(remoteEvents)

            return@withContext Pair(
                prepareEventAssociatedData(processEvents(remoteEvents)),
                conversation.checkLastRead(false)
            )
        }
    }

    private fun getAllStoredEvents(conversationUUID: String): List<MessengerEvent> {
        val messageEvents = local.messageEventDao().getAll(conversationUUID)
        val conversationEvents = local.conversationEventDao().getAll(conversationUUID)
        return (messageEvents + conversationEvents).sortedBy { it.sequence }
    }

    private fun saveEvents(events: List<MessengerEvent>) {
        val messageEvents: MutableList<MessageEvent> = mutableListOf()
        val conversationEvents: MutableList<ConversationEvent> = mutableListOf()

        events.forEach { event ->
            event.either(
                isMessageEvent = { messageEvents.add(it) },
                isConversationEvent = { conversationEvents.add(it) }
            )
        }

        local.messageEventDao().insertAll(messageEvents)
        local.conversationEventDao().insertAll(conversationEvents)
    }

    private suspend fun retransmitEvents(
        conversation: Conversation,
        numberOfEvents: Int,
        sequence: Long
    ) = suspendCoroutine<List<MessengerEvent>?> { continuation ->

        val voxConversation = recreateConversation(conversation)
            .ifNull {
                continuation.resume(null)
                return@suspendCoroutine
            }

        remote.requestMessengerEvents(voxConversation, numberOfEvents, sequence) { result ->
            result.onFailure { continuation.resume(null) }
            result.onSuccess { voxEvents ->
                continuation.resume(voxEvents.map { builder.buildMessengerEvent(it) })
            }
        }
    }

    private fun processEvents(events: List<MessengerEvent>): List<MessengerEvent> {
        val processedEvents: MutableList<MessengerEvent> = mutableListOf()
        val messageEvents: MutableList<MessageEvent> = mutableListOf()

        events.forEach { event ->
            event.either(
                isMessageEvent = { messageEvents.add(it) },
                isConversationEvent = { processedEvents.add(it) }
            )
        }

        val messageEventsCopy = messageEvents.toMutableList()

        messageEvents.forEach { event ->
            when (event.action) {
                SEND -> { }
                REMOVE -> messageEventsCopy.removeAll { it.message.uuid == event.message.uuid }
                EDIT -> {
                    val messageMentions = messageEventsCopy
                        .filter { it.message.uuid == event.message.uuid }
                        .sortedBy { it.sequence }

                    if (messageMentions.size <= 1) { return@forEach }

                    val last = messageMentions.last()
                    val first = messageMentions.first()

                    val message = Message(
                        uuid = last.message.uuid,
                        text = last.message.text,
                        conversation = last.message.conversation,
                        sequence = first.message.sequence
                    )

                    val updatedEvent = MessageEvent(
                        initiatorImId = first.initiatorImId,
                        action = EDIT,
                        message = message,
                        sequence = first.sequence,
                        timestamp = first.timestamp
                    )

                    messageEventsCopy.removeAll { it.message.uuid == event.message.uuid }
                    messageEventsCopy.add(updatedEvent)
                }
            }
        }

        processedEvents.addAll(messageEventsCopy)
        processedEvents.sortBy { it.sequence }
        return processedEvents
    }

    private suspend fun prepareEventAssociatedData(
        events: List<MessengerEvent>
    ) = withContext(coroutineContext) {
        val users = requestUsers(events.map { it.initiatorImId }.distinct())
            .ifNull { return@withContext listOf<EventWithAssociatedData>() }

        return@withContext events
            .map { event ->
                val user = users.first { it.imId == event.initiatorImId }
                EventWithAssociatedData(event, user.displayName, user.imId == me)
            }
    }
    //endregion

    //region VoximplantServiceListener
    override fun onConversationEvent(voxEvent: IConversationEvent) {
        launch {
            super.onConversationEvent(voxEvent)

            val me = me
                .ifNull { return@launch }

            val conversation = builder.buildConversation(voxEvent.conversation)

            var isStillInTheParticipantsList = false

            conversation.participants.forEach {
                if (it == me) {
                    isStillInTheParticipantsList = true
                }
            }

            if (isStillInTheParticipantsList) {
                local.conversationDao().insert(conversation)
                local.conversationEventDao().insert(builder.buildConversationEvent(voxEvent))
                local.participantDao().insertAll(voxEvent.conversation.participants.map {
                    builder.buildParticipant(it, voxEvent.conversation.uuid)
                })
            } else {
                activeConversation.postValue(null)
                local.conversationDao().delete(conversation)
                local.conversationEventDao().deleteAllWithUUID(voxEvent.conversation.uuid)
                local.participantDao().deleteAllWithUUID(conversation.uuid)
            }

            if (activeConversation.value?.uuid == voxEvent.conversation.uuid) {
                activeConversation.postValue(if (isStillInTheParticipantsList) {
                    conversation
                } else {
                    null
                })

                dataStateNotifier?.dataUpdated()
            }
        }
    }

    override fun onMessageEvent(voxEvent: IMessageEvent) {
        launch {
            Log.e(APP_TAG, "onMessageEvent ${voxEvent.sequence}")
            super.onMessageEvent(voxEvent)

            local.conversationDao().updateLastUpdated(
                voxEvent.timestamp,
                voxEvent.sequence,
                voxEvent.message.conversation
            )

            local.messageEventDao().insert(builder.buildMessageEvent(voxEvent))

            if (voxEvent.message.conversation == activeConversation.value?.uuid) {
                activeConversation.postValue(local.conversationDao().loadByUUID(voxEvent.message.conversation))
                dataStateNotifier?.dataUpdated()
            }
        }
    }

    override fun onServiceEvent(voxEvent: IConversationServiceEvent) {
        launch {
            super.onServiceEvent(voxEvent)

            if (voxEvent.messengerAction == IS_READ) {
                val conversation = local.conversationDao().loadByUUID(voxEvent.conversationUUID)
                    .ifNull { return@launch }

                if (conversation.checkLastRead(false) < voxEvent.sequence) {

                    local.participantDao()
                        .updateLastRead(
                            voxEvent.sequence,
                            voxEvent.imUserId,
                            voxEvent.conversationUUID
                        )

                    if (voxEvent.imUserId == me) { return@launch }

                    dataStateNotifier?.dataUpdated()
                }
            } else {
                if (voxEvent.imUserId == me) { return@launch }
            }

            listener?.onServiceEvent(builder.buildServiceEvent(voxEvent))
        }
    }

    override fun onUserEvent(voxEvent: IUserEvent) {
        launch {
            super.onUserEvent(voxEvent)

            local.userDao().insertUser(builder.buildUser(voxEvent.user))
        }
    }
    //endregion

    private fun Conversation.checkLastRead(includeMe: Boolean): Long {
        var lastReadSequence: Long = 1

        val IDs = this.participants
        val participants = local.participantDao().getAllByImId(IDs, this.uuid)

        participants
            .takeIf { it.isNotEmpty() }
            .ifNull { return lastReadSequence }

        participants
            .forEach { participant ->
                if (includeMe) {
                    participant.lastReadSequence
                        .takeIf { it > lastReadSequence }
                        ?.let { lastReadSequence = it }
                } else {
                    if (participant.userImId != me) {
                        participant.lastReadSequence
                            .takeIf { it > lastReadSequence }
                            ?.let { lastReadSequence = it }
                    }
                }
            }

        return lastReadSequence
    }

    companion object {
        private const val MY_IMID = "myImId"
    }
}

data class EventWithAssociatedData(val event: MessengerEvent, val initiatorName: String, val isMy: Boolean)