package com.voximplant.demos.messaging.repository.utils

import com.voximplant.demos.messaging.entity.*
import com.voximplant.demos.messaging.entity.events.*
import com.voximplant.demos.messaging.entity.events.MessengerEvent.*
import com.voximplant.demos.messaging.utils.permissions.*
import com.voximplant.sdk.messaging.*

class ModelBuilder {

    //region User
    fun buildUser(voxUser: IUser): User {
        return User(
            imId = voxUser.imId,
            name = voxUser.name,
            displayName = voxUser.displayName,
            customData = voxUser.customData
        )
    }
    //endregion

    //region Conversation
    fun buildConversation(voxConversation: IConversation) : Conversation {
        return Conversation(
            uuid = voxConversation.uuid,
            title = voxConversation.title,
            participants = voxConversation.participants.map { it.imUserId }.toMutableList(),
            lastUpdated = voxConversation.lastUpdateTime,
            lastSequence = voxConversation.lastSequence,
            isDirect = voxConversation.isDirect,
            isPublic = voxConversation.isPublicJoin,
            isUber = voxConversation.isUber,
            customData = voxConversation.customData
        )
    }

    fun buildConfig(conversation: Conversation) : ConversationConfig {
        return ConversationConfig
            .createBuilder()
            .setTitle(conversation.title)
            .setDirect(conversation.isDirect)
            .setUber(conversation.isUber)
            .setPublicJoin(conversation.isPublic)
            .setParticipants(conversation.participants.map { ConversationParticipant(it) })
            .setCustomData(conversation.customData)
            .build()
    }

    fun buildCustomData(type: ConversationType, pictureName: String? = null, description: String? = null) : CustomData {
        val customData: CustomData = mutableMapOf()
        customData.type = type.stringValue
        customData.permissions = type.defaultPermissions
        pictureName?.let { customData.image = it}
        description?.let { customData.chatDescription = it}
        return customData
    }
    //endregion

    //region Participant
    fun buildVoxParticipant(participant: Participant) : ConversationParticipant {
        return ConversationParticipant(participant.userImId)
            .setOwner(participant.isOwner)
            .setCanManageParticipants(participant.permissions.canManageParticipants)
            .setCanWrite(participant.permissions.canWrite)
            .setCanEditMessages(participant.permissions.canEditMessages)
            .setCanEditAllMessages(participant.permissions.canEditAllMessages)
            .setCanRemoveMessages(participant.permissions.canRemoveMessages)
            .setCanRemoveAllMessages(participant.permissions.canRemoveAllMessages)
    }
    
    fun buildDefaultVoxParticipant(ImId: Long, conversationType: ConversationType) : ConversationParticipant {
        return ConversationParticipant(ImId)
            .setOwner(false)
            .setCanManageParticipants(conversationType.defaultPermissions.canManageParticipants)
            .setCanWrite(conversationType.defaultPermissions.canWrite)
            .setCanEditMessages(conversationType.defaultPermissions.canEditMessages)
            .setCanEditAllMessages(conversationType.defaultPermissions.canEditAllMessages)
            .setCanRemoveMessages(conversationType.defaultPermissions.canRemoveMessages)
            .setCanRemoveAllMessages(conversationType.defaultPermissions.canRemoveAllMessages)
    }

    fun buildParticipant(voxParticipant: ConversationParticipant, conversationUUID: String) : Participant {
        return Participant(
            isOwner = voxParticipant.isOwner,
            userImId = voxParticipant.imUserId,
            permissions = buildPermissions(voxParticipant),
            lastReadSequence = voxParticipant.lastReadEventSequence,
            conversationUUID = conversationUUID
        )
    }
    //endregion

    //region Permissions
    private fun buildPermissions(voxParticipant: ConversationParticipant) : Permissions {
        val permissions: Permissions = mutableMapOf()
        permissions.canWrite              = voxParticipant.canWrite()
        permissions.canEditMessages       = voxParticipant.canEditMessages()
        permissions.canEditAllMessages    = voxParticipant.canEditAllMessages()
        permissions.canRemoveMessages     = voxParticipant.canRemoveMessages()
        permissions.canRemoveAllMessages  = voxParticipant.canRemoveAllMessages()
        permissions.canManageParticipants = voxParticipant.canManageParticipants()
        return permissions
    }
    //endregion

    //region Events
    fun buildMessengerEvent(voxEvent: IMessengerEvent): MessengerEvent {
        return when (voxEvent) {
            is IMessageEvent -> buildMessageEvent(voxEvent)
            is IConversationEvent -> buildConversationEvent(voxEvent)
            is IConversationServiceEvent -> buildServiceEvent(voxEvent)
            is IUserEvent -> buildUserEvent(voxEvent)
            else -> throw IllegalArgumentException("$voxEvent is Unknown")
        }
    }
    //region Conversation
    fun buildConversationEvent(voxEvent: IConversationEvent): ConversationEvent {
        return ConversationEvent(
            initiatorImId = voxEvent.imUserId,
            action = translateConversationEventAction(voxEvent.messengerAction),
            sequence = voxEvent.sequence,
            conversation = voxEvent.conversation.uuid,
            timestamp = voxEvent.timestamp
        )
    }

    private fun translateConversationEventAction(voxAction: MessengerAction): ConversationEventAction {
        return when (voxAction) {
            MessengerAction.ADD_PARTICIPANTS    -> ConversationEventAction.ADD_PARTICIPANTS
            MessengerAction.EDIT_PARTICIPANTS   -> ConversationEventAction.EDIT_PARTICIPANTS
            MessengerAction.REMOVE_PARTICIPANTS -> ConversationEventAction.REMOVE_PARTICIPANTS
            MessengerAction.EDIT_CONVERSATION   -> ConversationEventAction.EDIT_CONVERSATION
            MessengerAction.JOIN_CONVERSATION   -> ConversationEventAction.JOIN_CONVERSATION
            MessengerAction.LEAVE_CONVERSATION  -> ConversationEventAction.LEAVE_CONVERSATION
            MessengerAction.CREATE_CONVERSATION -> ConversationEventAction.CREATE_CONVERSATION
            MessengerAction.REMOVE_CONVERSATION -> ConversationEventAction.REMOVE_CONVERSATION
            else -> throw IllegalArgumentException("$voxAction is Unknown")
        }
    }
    //endregion

    //region Message
    fun buildMessageEvent(voxEvent: IMessageEvent) : MessageEvent {
        return MessageEvent(
            initiatorImId = voxEvent.imUserId,
            action = translateMessageEventAction(voxEvent.messengerAction),
            sequence = voxEvent.sequence,
            message = buildMessage(voxEvent.message),
            timestamp = voxEvent.timestamp
        )
    }

    private fun buildMessage(voxMessage: IMessage) : Message {
        return Message(
            uuid = voxMessage.uuid,
            text = voxMessage.text ?: "empty string!!",
            conversation = voxMessage.conversation,
            sequence = voxMessage.sequence
        )
    }

    private fun translateMessageEventAction(voxAction: MessengerAction) : MessageEventAction {
        return when (voxAction) {
            MessengerAction.SEND_MESSAGE   -> MessageEventAction.SEND
            MessengerAction.EDIT_MESSAGE   -> MessageEventAction.EDIT
            MessengerAction.REMOVE_MESSAGE -> MessageEventAction.REMOVE
            else -> throw IllegalArgumentException("$voxAction is Unknown")
        }
    }
    //endregion

    //region Service
    fun buildServiceEvent(voxEvent: IConversationServiceEvent) : ServiceEvent {
        return ServiceEvent(
            initiatorImId = voxEvent.imUserId,
            action = translateServiceAction(voxEvent.messengerAction),
            sequence = voxEvent.sequence,
            conversationUUID = voxEvent.conversationUUID
        )
    }

    private fun translateServiceAction(voxAction: MessengerAction) : ServiceEventAction {
        return when (voxAction) {
            MessengerAction.IS_READ -> ServiceEventAction.READ
            MessengerAction.TYPING_MESSAGE -> ServiceEventAction.TYPING
            else  -> throw IllegalArgumentException("$voxAction is Unknown")
        }
    }
    //endregion

    //region User
    private fun buildUserEvent(voxEvent: IUserEvent) : UserEvent {
        return UserEvent(
            initiatorImId = voxEvent.imUserId,
            action = translateUserAction(voxEvent.messengerAction)
        )
    }

    private fun translateUserAction(voxAction: MessengerAction) : UserEventAction {
        return when (voxAction) {
            MessengerAction.EDIT_USER -> UserEventAction.EDIT
            else -> throw IllegalArgumentException("$voxAction is Unknown")
        }
    }
    //endregion
    //endregion
}