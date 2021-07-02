package com.voximplant.demos.messaging.ui.conversations

import com.voximplant.demos.messaging.entity.Conversation
import com.voximplant.demos.messaging.entity.ConversationType
import com.voximplant.demos.messaging.entity.User
import com.voximplant.demos.messaging.repository.utils.image
import com.voximplant.demos.messaging.repository.utils.type

data class ConversationModel(
    val uuid: String,
    val type: ConversationType,
    val title: String,
    val pictureName: String?,
    val lastUpdated: Long?
) {
    companion object {
        fun buildGroup(conversation: Conversation): ConversationModel {
            return ConversationModel(
                conversation.uuid,
                ConversationType.from(conversation.customData.type ?: ConversationType.CHAT.stringValue),
                conversation.title,
                conversation.customData.image,
                conversation.lastUpdated,
            )
        }

        fun buildDirect(conversation: Conversation, user: User): ConversationModel {
            return ConversationModel(
                conversation.uuid,
                ConversationType.from(conversation.customData.type ?: ConversationType.CHAT.stringValue),
                user.displayName,
                user.customData.image,
                conversation.lastUpdated,
            )
        }
    }
}