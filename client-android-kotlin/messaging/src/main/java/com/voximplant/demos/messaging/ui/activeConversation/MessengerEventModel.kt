package com.voximplant.demos.messaging.ui.activeConversation

import com.voximplant.demos.messaging.entity.events.ConversationEventAction
import com.voximplant.demos.messaging.entity.events.MessageEventAction
import com.voximplant.demos.messaging.entity.events.MessengerEvent
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
        var isFailed: Boolean = false
    ) : MessengerEventModel()

    data class EventCellModel(
        override val sequence: Long,
        val initiatorName: String,
        val text: String
    ) : MessengerEventModel()

    companion object {
        fun buildWith(
            event: MessengerEvent,
            initiatorDisplayName: String,
            isMy: Boolean,
            isRead: Boolean
        ) = when (event) {
            is MessengerEvent.ConversationEvent -> buildWith(event, initiatorDisplayName)
            is MessengerEvent.MessageEvent -> buildWith(
                event,
                initiatorDisplayName,
                isMy,
                isRead
            )
            else -> throw IllegalArgumentException()
        }

        private fun buildWith(
            conversationEvent: MessengerEvent.ConversationEvent,
            initiatorDisplayName: String
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
            }"
        )

        private fun buildWith(
            messageEvent: MessengerEvent.MessageEvent,
            initiatorDisplayName: String,
            isMy: Boolean,
            isRead: Boolean
        ) = MessageCellModel(
            sequence = messageEvent.message.sequence,
            time = buildTime(messageEvent.timestamp),
            text = messageEvent.message.text,
            senderName = initiatorDisplayName,
            isRead = isRead,
            isMy = isMy,
            isEdited = messageEvent.action == MessageEventAction.EDIT
        )

        private fun buildTime(timestamp: Long): String {
            val date = Date(timestamp * 1000)
            val format = SimpleDateFormat("HH:mm", Locale.getDefault())
            return format.format(date)
        }
    }
}