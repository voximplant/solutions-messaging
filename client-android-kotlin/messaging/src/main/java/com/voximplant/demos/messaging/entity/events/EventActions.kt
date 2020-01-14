package com.voximplant.demos.messaging.entity.events

enum class ConversationEventAction {
    ADD_PARTICIPANTS,
    EDIT_PARTICIPANTS,
    REMOVE_PARTICIPANTS,
    EDIT_CONVERSATION,
    JOIN_CONVERSATION,
    LEAVE_CONVERSATION,
    CREATE_CONVERSATION,
    REMOVE_CONVERSATION
}

enum class MessageEventAction {
    SEND,
    EDIT,
    REMOVE
}

enum class ServiceEventAction {
    READ,
    TYPING
}

enum class UserEventAction {
    EDIT
}