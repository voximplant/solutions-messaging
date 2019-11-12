import { ActionTree } from 'vuex';
import { ConversationsState, Participant, User } from '@/types/src/conversations';
import { logError, logHelp } from '@/utils';
import MessengerService from '@/services/messenger.service';
import { MessageEvents } from '@/types/src/events';

const actionsMessages: ActionTree<ConversationsState, any> = {
  getConversationHistory: async (context) => {
    const lastEvent = context.getters.currentConversationHistory && context.getters.currentConversationHistory.length ?
      context.getters.currentConversation.lastEvent
      : context.getters.currentConversation.lastSeq;

    if (lastEvent !== 0 ) {
      await MessengerService.get().retransmitMessageEvents(context.getters.currentConversation, lastEvent)
        .then((messageEvents: MessageEvents[]) => {
          const messages = messageEvents.map((e) => {
            e.message.timestamp = e.timestamp;
            e.message.seq = e.seq;

            if (e.message.sender === context.state.currentUser.userId) {
              e.message.user = context.state.currentUser;
            } else {
              e.message.user = context.state.users.find((c: User) => c.userId === e.message.sender);
            }

            // TODO 'll highlight to singular dispatch
            // if one participant read a message, it marked as read
            const arrLastRead = context.getters.currentConversation.participants.map((p: Participant) => {
              return p.userId !== context.state.currentUser.userId ?  p.lastRead : 0;
            });

            if (Math.max(...arrLastRead) >= e.seq) {
              e.message.markAsRead = true;
            }

            return e.message;
          });

          context.commit('addMessagesToConversation', messages);
          context.dispatch('markedAsRead', context.getters.currentConversation.lastSeq);
        });
    }
  },

  sendNewMessage: ({ getters }, text) => {
    MessengerService.get().sendMessage(getters.currentConversation, text)
      .catch(logError);
  },

  deleteMessage: (context, message) => {
    MessengerService.get().removeMessage(message)
      .catch(logError);
  },

  editMessage: (context, newData) => {
    newData.message.text = newData.newText;
    MessengerService.get().updateMessage(newData.message)
      .catch(logError);
  },

  markedAsRead: ({ getters }, lastSeq) => {
    MessengerService.get().markAsRead(getters.currentConversation, lastSeq)
      .catch(logError);
  },

  /**
   * Resolvers for MessengerService listeners
   */

  onMessageSent: (context, e) => {
    e.message.timestamp = e.timestamp;
    e.message.seq = e.seq;
    if (e.message.sender === context.state.currentUser.userId) {
      e.message.user = context.state.currentUser;
    } else {
      e.message.user = context.state.users.find((c: User) => c.userId === e.message.sender);
    }

    context.commit('updateMessagesInConversation', e.message);
    context.commit('SCROLLING_START', false, {root: true});
  },

  onMessageDeleted: (context, evt) => {
    context.commit('deleteMessageFromConversation', evt.message);
  },

  onMessageEdited: (context, e) => {
    e.message.timestamp = e.timestamp;
    e.message.seq = e.seq;
    if (e.message.sender === context.state.currentUser.userId) {
      e.message.user = context.state.currentUser;
    } else {
      e.message.user = context.state.users.find((c: User) => c.userId === e.message.sender);
    }

    context.commit('updateMessagesInConversation', e.message);
  },

  onMessageMarkAsRead: (context, evt) => {
    if (evt.initiator !== context.state.currentUser.userId) {
      context.commit('updateMessageAsRead', evt.seq);
    }
  },
};

export default actionsMessages;
