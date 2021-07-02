package com.voximplant.demos.messaging.repository.remote

import com.voximplant.demos.messaging.repository.utils.CustomData
import com.voximplant.demos.messaging.utils.payload.Payload
import com.voximplant.sdk.messaging.*
import kotlin.Result.Companion.failure
import kotlin.Result.Companion.success

class VoximplantService(private val messenger: IMessenger) : IMessengerListener {
    private var listener: VoximplantServiceListener? = null

    val myUsername: String?
        get() = if (messenger.me.split(".").size == 2) {
            messenger.me
        } else {
            messenger.me.substringBeforeLast(".")
        }

    init {
        this.messenger.addMessengerListener(this)
    }

    fun setListener(listener: VoximplantServiceListener) {
        this.listener = listener
    }

    //region Users
    fun requestUser(imID: Long, completion: (Result<IUser>) -> Unit) {
        messenger.getUser(imID, object : IMessengerCompletionHandler<IUserEvent> {
            override fun onSuccess(event: IUserEvent) {
                completion(success(event.user))
            }

            override fun onError(event: IErrorEvent) {
                completion(failure(buildError(event)))
            }
        })
    }

    fun requestUser(username: String, completion: (Result<IUser>) -> Unit) {
        messenger.getUser(username, object : IMessengerCompletionHandler<IUserEvent> {
            override fun onSuccess(event: IUserEvent) {
                completion(success(event.user))
            }

            override fun onError(event: IErrorEvent) {
                completion(failure(buildError(event)))
            }
        })
    }

    fun requestUsers(imIDs: List<Long>, completion: (Result<List<IUser>>) -> Unit) {
        messenger.getUsersByIMId(imIDs, object : IMessengerCompletionHandler<List<IUserEvent>> {
            override fun onSuccess(userEvents: List<IUserEvent>) {
                completion(success(userEvents.map { it.user }))
            }

            override fun onError(errorEvent: IErrorEvent) {
                completion(failure(buildError(errorEvent)))
            }
        })
    }

    fun editUser(customData: CustomData, completion: (Result<IUserEvent>) -> Unit) {
        messenger.editUser(customData, null, object : IMessengerCompletionHandler<IUserEvent> {
            override fun onSuccess(userEvent: IUserEvent) {
                completion(success(userEvent))
            }

            override fun onError(errorEvent: IErrorEvent) {
                completion(failure(buildError(errorEvent)))
            }
        })
    }
    //endregion

    //region Conversations
    fun createConversation(
        config: ConversationConfig,
        completion: (Result<IConversationEvent>) -> Unit
    ) {
        messenger.createConversation(
            config,
            object : IMessengerCompletionHandler<IConversationEvent> {
                override fun onSuccess(conversationEvent: IConversationEvent) {
                    completion(success(conversationEvent))
                }

                override fun onError(errorEvent: IErrorEvent) {
                    completion(failure(buildError(errorEvent)))
                }
            })
    }

    fun requestMultipleConversations(
        uuids: List<String>,
        completion: (Result<List<IConversation>>) -> Unit
    ) {
        messenger.getConversations(
            uuids,
            object : IMessengerCompletionHandler<List<IConversationEvent>> {
                override fun onSuccess(conversationEvents: List<IConversationEvent>) {
                    completion(success(conversationEvents.map { it.conversation }))
                }

                override fun onError(errorEvent: IErrorEvent) {
                    completion(failure(buildError(errorEvent)))
                }
            })
    }

    fun recreateMessage(uuid: String, conversationUUID: String): IMessage? =
        messenger.recreateMessage(uuid, conversationUUID, null, null, 0)


    fun recreateConversation(
        uuid: String,
        config: ConversationConfig,
        lastSequence: Long?
    ): IConversation? =
        messenger.recreateConversation(config, uuid, lastSequence ?: 0, 0, 0)


    fun addParticipants(
        participants: List<ConversationParticipant>,
        conversation: IConversation,
        completion: (Result<IConversationEvent>) -> Unit
    ) {
        conversation.addParticipants(
            participants,
            object : IMessengerCompletionHandler<IConversationEvent> {
                override fun onSuccess(conversationEvent: IConversationEvent) {
                    completion(success(conversationEvent))
                }

                override fun onError(errorEvent: IErrorEvent) {
                    completion(failure(buildError(errorEvent)))
                }
            })
    }

    fun editParticipants(
        participants: List<ConversationParticipant>,
        conversation: IConversation,
        completion: (Result<IConversationEvent>) -> Unit
    ) {
        conversation.editParticipants(
            participants,
            object : IMessengerCompletionHandler<IConversationEvent> {
                override fun onSuccess(conversationEvent: IConversationEvent) {
                    completion(success(conversationEvent))
                }

                override fun onError(errorEvent: IErrorEvent) {
                    completion(failure(buildError(errorEvent)))
                }
            })
    }

    fun removeParticipants(
        participants: List<ConversationParticipant>,
        conversation: IConversation,
        completion: (Result<IConversationEvent>) -> Unit
    ) {
        conversation.removeParticipants(
            participants,
            object : IMessengerCompletionHandler<IConversationEvent> {
                override fun onSuccess(conversationEvent: IConversationEvent) {
                    completion(success(conversationEvent))
                }

                override fun onError(errorEvent: IErrorEvent) {
                    completion(failure(buildError(errorEvent)))
                }
            })
    }

    fun updateConversation(
        conversation: IConversation,
        completion: (Result<IConversationEvent>) -> Unit
    ) {
        conversation.update(object : IMessengerCompletionHandler<IConversationEvent> {
            override fun onSuccess(conversationEvent: IConversationEvent) {
                completion(success(conversationEvent))
            }

            override fun onError(errorEvent: IErrorEvent) {
                completion(failure(buildError(errorEvent)))
            }
        })
    }

    fun leaveConversation(uuid: String, completion: (Result<IConversationEvent>) -> Unit) {
        messenger.leaveConversation(uuid, object : IMessengerCompletionHandler<IConversationEvent> {
            override fun onSuccess(conversationEvent: IConversationEvent) {
                completion(success(conversationEvent))
            }

            override fun onError(errorEvent: IErrorEvent) {
                completion(failure(buildError(errorEvent)))
            }
        })
    }

    //endregion

    fun requestMessengerEvents(
        conversation: IConversation,
        numberOfEvents: Int,
        sequence: Long,
        completion: (Result<List<IMessengerEvent>>) -> Unit
    ) {
        conversation.retransmitEventsTo(
            sequence,
            numberOfEvents,
            object : IMessengerCompletionHandler<IRetransmitEvent> {
                override fun onSuccess(retransmitEvents: IRetransmitEvent) {
                    completion(success(retransmitEvents.events))
                }

                override fun onError(errorEvent: IErrorEvent) {
                    completion(failure(buildError(errorEvent)))
                }
            })
    }

    fun sendMessage(
        text: String,
        payload: Payload?, conversation: IConversation,
        completion: (Result<IMessageEvent>) -> Unit
    ) {
        conversation.sendMessage(
            text,
            payload,
            object : IMessengerCompletionHandler<IMessageEvent> {
                override fun onSuccess(messageEvent: IMessageEvent) {
                    completion(success(messageEvent))
                }

                override fun onError(errorEvent: IErrorEvent) {
                    completion(failure(buildError(errorEvent)))
                }
            })
    }

    fun markAsRead(sequence: Long, conversation: IConversation) {
        conversation.markAsRead(sequence, null)
    }

    fun sendTyping(conversation: IConversation) {
        conversation.typing(null)
    }

    fun removeMessage(message: IMessage, completion: (Result<IMessageEvent>) -> Unit) {
        message.remove(object : IMessengerCompletionHandler<IMessageEvent> {
            override fun onSuccess(messageEvent: IMessageEvent) {
                completion(success(messageEvent))
            }


            override fun onError(errorEvent: IErrorEvent) {
                completion(failure(buildError(errorEvent)))
            }
        })
    }

    fun editMessage(message: IMessage, text: String, completion: (Result<IMessageEvent>) -> Unit) {
        message.update(text, null, object : IMessengerCompletionHandler<IMessageEvent> {
            override fun onSuccess(messageEvent: IMessageEvent) {
                completion(success(messageEvent))
            }

            override fun onError(errorEvent: IErrorEvent) {
                completion(failure(buildError(errorEvent)))
            }
        })
    }

    //region IMessengerListener
    override fun onSendMessage(event: IMessageEvent) {
        listener?.onMessageEvent(event)
    }

    override fun onEditMessage(event: IMessageEvent) {
        listener?.onMessageEvent(event)
    }

    override fun onRemoveMessage(event: IMessageEvent) {
        listener?.onMessageEvent(event)
    }

    override fun onCreateConversation(event: IConversationEvent) {
        listener?.onConversationEvent(event)
    }

    override fun onRemoveConversation(event: IConversationEvent) {
        listener?.onConversationEvent(event)
    }

    override fun onEditConversation(event: IConversationEvent) {
        listener?.onConversationEvent(event)
    }

    override fun onTyping(event: IConversationServiceEvent) {
        listener?.onServiceEvent(event)
    }

    override fun isRead(event: IConversationServiceEvent) {
        listener?.onServiceEvent(event)
    }

    override fun onEditUser(event: IUserEvent) {
        listener?.onUserEvent(event)
    }

    override fun onGetUser(p0: IUserEvent?) {

    }

    override fun onGetPublicConversations(p0: IConversationListEvent?) {}

    override fun onSetStatus(p0: IStatusEvent?) {}

    override fun onGetConversation(p0: IConversationEvent?) {}

    override fun onGetSubscriptionList(p0: ISubscriptionEvent?) {}

    override fun onUnsubscribe(p0: ISubscriptionEvent?) {}

    override fun onRetransmitEvents(p0: IRetransmitEvent?) {}

    override fun onSubscribe(p0: ISubscriptionEvent?) {}

    override fun onError(p0: IErrorEvent?) {}
//endregion

    private fun buildError(event: IErrorEvent): Error {
        return Error(event.errorDescription)
    }
}