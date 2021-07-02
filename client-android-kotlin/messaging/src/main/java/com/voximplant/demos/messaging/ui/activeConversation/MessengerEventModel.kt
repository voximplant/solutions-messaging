package com.voximplant.demos.messaging.ui.activeConversation

import com.google.android.gms.maps.model.LatLng
import com.voximplant.demos.messaging.entity.events.ConversationEventAction
import com.voximplant.demos.messaging.entity.events.MessageEventAction
import com.voximplant.demos.messaging.entity.events.MessengerEvent
import com.voximplant.demos.messaging.utils.payload.locationLatitude
import com.voximplant.demos.messaging.utils.payload.locationLongitude
import java.text.SimpleDateFormat
import java.util.*

sealed class MessengerEventModel {
    abstract val sequence: Long

    data class MessageCellModel(
        override val sequence: Long,
        val time: String,
        var text: String,
        var senderName: String,
        val isMy: Boolean,
        var isRead: Boolean = false,
        var isEdited: Boolean = false,
        var isFailed: Boolean = false,
    ) : MessengerEventModel()

    data class EventCellModel(
        override val sequence: Long,
        val initiatorName: String,
        val text: String,
    ) : MessengerEventModel()

    data class LocationCellModel(
        override val sequence: Long,
        val time: String,
        val isMy: Boolean,
        var senderName: String,
        val location: LatLng,
        var isRead: Boolean = false
    ) : MessengerEventModel()

    companion object {
        fun buildWith(
            event: MessengerEvent,
            initiatorDisplayName: String,
            isMy: Boolean,
            isRead: Boolean,
        ) = when (event) {
            is MessengerEvent.ConversationEvent -> buildWith(event, initiatorDisplayName)
            is MessengerEvent.MessageEvent -> {
                val lat = event.message.payload?.locationLatitude
                val lon = event.message.payload?.locationLongitude
                if (lat != null && lon != null) {
                    buildLocationCellWith(
                        event,
                        initiatorDisplayName,
                        isMy,
                        isRead
                    )
                } else {
                    buildWith(
                        event,
                        initiatorDisplayName,
                        isMy,
                        isRead,
                    )
                }
            }
            else -> throw IllegalArgumentException()
        }

        private fun buildWith(
            conversationEvent: MessengerEvent.ConversationEvent,
            initiatorDisplayName: String,
        ) = EventCellModel(
            sequence = conversationEvent.sequence,
            initiatorName = initiatorDisplayName,
            text = "$initiatorDisplayName ${
                when (conversationEvent.action) {
                    ConversationEventAction.ADD_PARTICIPANTS -> "added participants"
                    ConversationEventAction.EDIT_PARTICIPANTS -> "edited participants"
                    ConversationEventAction.REMOVE_PARTICIPANTS -> "removed participants"
                    ConversationEventAction.EDIT_CONVERSATION -> "edited conversation"
                    ConversationEventAction.JOIN_CONVERSATION -> "joined"
                    ConversationEventAction.LEAVE_CONVERSATION -> "left"
                    ConversationEventAction.CREATE_CONVERSATION -> "created conversation"
                    ConversationEventAction.REMOVE_CONVERSATION -> "removed conversation"
                }
            }",
        )

        private fun buildWith(
            messageEvent: MessengerEvent.MessageEvent,
            initiatorDisplayName: String,
            isMy: Boolean,
            isRead: Boolean,
        ) = MessageCellModel(
            sequence = messageEvent.message.sequence,
            time = buildTime(messageEvent.timestamp),
            text = messageEvent.message.text,
            senderName = initiatorDisplayName,
            isRead = isRead,
            isMy = isMy,
            isEdited = messageEvent.action == MessageEventAction.EDIT,
        )

        private fun buildLocationCellWith(
            messageEvent: MessengerEvent.MessageEvent,
            initiatorDisplayName: String,
            isMy: Boolean,
            isRead: Boolean
        ) = LocationCellModel(
            sequence = messageEvent.message.sequence,
            time = buildTime(messageEvent.timestamp),
            senderName = initiatorDisplayName,
            isMy = isMy,
            location = LatLng(messageEvent.message.payload?.locationLatitude!!, messageEvent.message.payload?.locationLongitude!!),
            isRead = isRead
        )

        private fun buildTime(timestamp: Long): String {
            val date = Date(timestamp * 1000)
            val format = SimpleDateFormat("HH:mm", Locale.getDefault())
            return format.format(date)
        }
    }
}