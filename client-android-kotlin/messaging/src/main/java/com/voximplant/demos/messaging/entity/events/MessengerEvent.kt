package com.voximplant.demos.messaging.entity.events

import androidx.room.Embedded
import androidx.room.Entity
import com.voximplant.demos.messaging.entity.Message

sealed class MessengerEvent {

    abstract val initiatorImId: Long
    abstract val sequence: Long

    @Entity(primaryKeys = ["sequence", "conversation"])
    data class ConversationEvent(
        override val initiatorImId: Long,
        val action: ConversationEventAction,
        override val sequence: Long,
        val conversation: String,
        val timestamp: Long
    ) : MessengerEvent()

    @Entity(primaryKeys = ["sequence", "conversation"])
    data class MessageEvent(
        override val initiatorImId: Long,
        var action: MessageEventAction,
        override val sequence: Long,
        @Embedded var message: Message,
        val timestamp: Long
    ) : MessengerEvent()

    data class ServiceEvent(
        override val initiatorImId: Long,
        val action: ServiceEventAction,
        override val sequence: Long,
        val conversationUUID: String
    ) : MessengerEvent()

    data class UserEvent(
        override val initiatorImId: Long,
        val action: UserEventAction
    ) : MessengerEvent() {
        override val sequence: Long
            get() = 0
    }

    fun either(
        isConversationEvent: ((ConversationEvent) -> Unit)? = null,
        isMessageEvent: ((MessageEvent) -> Unit)? = null,
        isServiceEvent: ((ServiceEvent) -> Unit)? = null,
        isUserEvent: ((UserEvent) -> Unit)? = null
    ) {
        when (this) {
            is ConversationEvent -> isConversationEvent?.invoke(this)
            is MessageEvent -> isMessageEvent?.invoke(this)
            is ServiceEvent -> isServiceEvent?.invoke(this)
            is UserEvent -> isUserEvent?.invoke(this)
        }
    }
}
