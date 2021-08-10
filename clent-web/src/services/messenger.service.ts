// @ts-ignore
import * as VoxImplant from '@/libs/voximplant.js';
import { log, logError, logHelp } from '@/utils';
import { MY_APP, URL_NEW_USERS } from '@/config';
import store from '@/store/store';
import { Conversation, NewChatData, Permissions, User } from '@/types/src/conversations';

const TIME_NOTIFICATION = 300000;

export default class MessengerService {
  public static messenger: any = null;

  public static get() {
    if (!MessengerService.inst) {
      MessengerService.inst = new MessengerService();
    }
    return MessengerService.inst;
  }

  private static inst: any;
  private setStatusTimer: any;
  private conversationEvents: any = {};

  /***********************************************************************************************
   * INIT VOXIMPLANT.MESSENGER && GET INITIAL DATA
   **********************************************************************************************/

  public async init() {
    // Get Voximplant Messenger instance
    try {
      MessengerService.messenger = VoxImplant.getMessenger();
      log('Messenger v2', MessengerService.messenger);
      log('VoxImplant.Messaging v2', VoxImplant.Messaging);
    } catch (e)  {
      // Most common error 'Not authorised', so redirect to login
      logError(e);
      await store.dispatch('auth/relogin');
    }

    // Get the current user data
    const initialData: {
      currentUser: any,
      conversations: any,
      users: any,
    } = {
      currentUser: {},
      conversations: [],
      users: [],
    };

    await MessengerService.messenger.getUser(MessengerService.messenger.getMe())
      .then((evt: any) => {
        logHelp('Current user data received', evt);
        initialData.currentUser = evt.user;

        return this.getCurrentConversations(evt.user.conversationsList);
      })
      .then((evts: any) => {
        logHelp('Current user conversations received', evts);

        initialData.conversations = evts.length ? evts.map((e: any) => e.conversation) : [];
        const directUsersId = initialData.conversations.filter((conversation: any) => conversation.direct).map((conversation: any) => {
          const directUser = conversation.participants.find((participant: any) => participant.userId !== initialData.currentUser.userId)
          return directUser.userId;
        })
        return MessengerService.messenger.getUsersById(directUsersId);
      })
      .then((evts: any) => {
        logHelp('Conversation participants user info received', evts);
        initialData.users = evts.map((e: any) => e.user);
      })
      .catch(logError);

    this.addMessengerEventListeners();

    /**
     * You have to send user presence status periodically to notify the new coming users if you are online
     * TODO You can implement invisible mode by sending setStatus(false)
     */
    const sendStatus = () => setTimeout(() => {
      MessengerService.messenger.setStatus(true);
      this.setStatusTimer = sendStatus();
    }, TIME_NOTIFICATION);

    this.setStatusTimer = sendStatus();

    return initialData;
  }

  /**
   * Some VoxImplant.Messaging.MessengerEvents are better to use by passing a callback to the event listener function.
   * This way you're able update the current user's store and interface if the event is triggered by another user or by the current one on a different device.
   * The other VoxImplant.Messaging.MessengerEvents are more handy to deal with in a .then() function as they all return a Promise.
   * These are methods that affect only this user and this application instance, like subscribing to or unsubscribing from other users, retransmitting events or getting other data.
   */
  private addMessengerEventListeners() {
    // Listen to other users presence status event
    MessengerService.messenger.on(VoxImplant.Messaging.MessengerEvents.SetStatus, (e: any) => store.dispatch('conversations/onOnlineReceived', e));

    // Listen to CreateConversation event called by this or another user
    MessengerService.messenger.on(VoxImplant.Messaging.MessengerEvents.CreateConversation, (e: any) => store.dispatch('conversations/onConversationCreated', e));

    // Listen to EditConversation event called by this or another user
    MessengerService.messenger.on(VoxImplant.Messaging.MessengerEvents.EditConversation, (e: any) => store.dispatch('conversations/onConversationEdited', e));

    // Listen to incoming messages
    MessengerService.messenger.on(VoxImplant.Messaging.MessengerEvents.SendMessage, (e: any) => store.dispatch('conversations/onMessageSent', e));

    // Listen to edited messages
    MessengerService.messenger.on(VoxImplant.Messaging.MessengerEvents.EditMessage, (e: any) => store.dispatch('conversations/onMessageEdited', e));

    // Listen to deleted messages
    MessengerService.messenger.on(VoxImplant.Messaging.MessengerEvents.RemoveMessage, (e: any) => store.dispatch('conversations/onMessageDeleted', e));

    // Listen to markAsRead message
    MessengerService.messenger.on(VoxImplant.Messaging.MessengerEvents.Read, (e: any) => store.dispatch('conversations/onMessageMarkAsRead', e));

    // Listen to typing event
    MessengerService.messenger.on(VoxImplant.Messaging.MessengerEvents.Typing, (e: any) => store.dispatch('conversations/onNotifyTyping', e));
  }
  private getCurrentConversations(conversationsList: Conversation[]) {
    /**
     * The maximum number of conversations that SDK enables to get at once is 30
     * This method resolves to an array of VoxImplant.Messaging.MessengerEvents.GetConversation events
     */
    // TODO add param for amount of conversations
    // @ts-ignore
    return MessengerService.messenger.getConversations(conversationsList).catch((e: any) => {
      logError('MessengerService.getCurrentConversations', e);
      return [];
    });
  }

  /**
   * Get all available users names through additional PHP server
   */
  private async getAllUsers() {
    const getAllUsers = await fetch(URL_NEW_USERS);
    let jsonAllUsers;

    if (getAllUsers.ok) {
      jsonAllUsers = await getAllUsers.json();
    } else {
      logError('Error HTTP: ' + getAllUsers.status);
    }
    const usersNames = jsonAllUsers.result.map((u: any) => `${u.user_name}@${MY_APP}`);
    return  this.getUserIds(usersNames);
  }

  /**
   * All Messenger methods except for GetUser and GetUsers accept only Messaging user ids, so you often need to map user names to user ids.
   * Messenger.GetUser and Messenger.GetUsers accept user names.
   */
  public getUserIds(filteredUserNames: string[]) {
    return MessengerService.messenger.getUsers(filteredUserNames);
  }

  /***********************************************************************************************
   * CREATE CONVERSATIONS
   **********************************************************************************************/

  public createDirect(userId: number) {
    return this.createNewConversation(
      [{ userId }],
      '',
      true,
      false,
      false,
      { type: 'direct' });
  }
  public createChat(newChatData: NewChatData) {
    const permissions: Permissions = {
      canWrite: true,
      canEdit: true,
      canRemove: true,
      canManageParticipants: true,
      canEditAll: false,
      canRemoveAll: false,
    };

    const participants = newChatData.usersId.map( (userId: number) => {
      return {
        userId,
        ...permissions,
      };
    });

    return this.createNewConversation(
      participants,
      newChatData.title,
      false,
      newChatData.isPublic,
      newChatData.isUber,
      {
        type: 'chat',
        image: newChatData.avatar,
        description: newChatData.description,
        permissions,
      });
  }
  public createChannel(newChatData: NewChatData) {
    const permissions: Permissions = {
      canWrite: false,
      canEdit: false,
      canRemove: false,
      canManageParticipants: true,
      canEditAll: false,
      canRemoveAll: false,
    };

    const participants = newChatData.usersId.map( (userId) => {
      return {
        userId,
        ...permissions,
      };
    });

    return this.createNewConversation(
      participants,
      newChatData.title,
      false,
      newChatData.isPublic,
      newChatData.isUber,
      {
        type: 'channel',
        image: newChatData.avatar,
        description: newChatData.description,
        permissions,
      });
  }

  /**
   * Messenger.createConversation method takes 6 arguments
   * @param participants {Array<{userId: number, canWrite: boolean, canEdit: boolean, canRemove: boolean, canManageParticipants: boolean, canEditAll: boolean, canRemoveAll: boolean}>} - Array of participants
   * @param title {string} - Conversation name
   * @param direct {boolean} - True you create a conversation between two users
   * @param publicJoin {boolean} - True if anyone can join the conversation
   * @param uber {boolean} - True if anyone can join the conversation
   * @param customData {Array<object>} - Array of any objects with custom data
   */
  private createNewConversation(participants: any[], title: string, direct:boolean, publicJoin:boolean, uber:boolean, customData:object) {
    return MessengerService.messenger.createConversation(participants, title, direct, publicJoin, uber, customData);
  }

  /***********************************************************************************************
   * EDIT/LEAVE CONVERSATIONS
   **********************************************************************************************/

  /**
   * These methods triggers VoxImplant.Messaging.MessengerEvents.EditConversation event
   * VoxImplant.Messaging method takes an array of {userId: number, canWrite: boolean, canEdit: boolean, canRemove: boolean, canManageParticipants: boolean, canEditAll: boolean, canRemoveAll: boolean}
   */
  public addParticipants(currentConversation: any, userIds: number[]) {
    return currentConversation.addParticipants(userIds.map((userId) => ({
      userId,
      ...currentConversation.customData.permissions,
    }))).catch(logError);
  }
  public removeParticipants(currentConversation: any, userIds: number[]) {
    return currentConversation.removeParticipants(userIds.map((userId) => ({userId}))).catch(logError);
  }
  public addAdmins(currentConversation: any, userIds: number[]) {
    return currentConversation.editParticipants(userIds.map((userId) => ({
      userId,
      canWrite: true,
      canEdit: true,
      canRemove: true,
      canManageParticipants: true,
      canEditAll: true,
      canRemoveAll: true,
      isOwner: true,
    }))).catch(logError);
  }
  public removeAdmins(currentConversation: any, userIds: number[]) {
    // default chat permissions from custom data
    return currentConversation.editParticipants(userIds.map((userId) => ({
      userId,
      ...currentConversation.customData.permissions,
    }))).catch(logError);
  }
  public editPermissions(currentConversation: any, permissions: Permissions, allUserIds: number[]) {
    // NOTE! Must merge previous custom data with new
    // Method setCustomData REPLACE data
    currentConversation.setCustomData({ ...currentConversation.customData, permissions });
    return currentConversation.editParticipants(allUserIds.map((userId) => ({
      userId,
      ...permissions,
    }))).catch(logError);
  }
  public leaveConversation(currentConversationUuid: string) {
    MessengerService.messenger.leaveConversation(currentConversationUuid)
      .catch(logError);
  }

  /**
   * Notify other that current user typing in conversation. This method trigger VoxImplant.Messaging.MessengerEvents.Typing event
   * Subscribe it to resolve events, min time between notifications 10sec
   * @param currentConversation
   */
  public notifyTyping(currentConversation: any) {
    return currentConversation.typing();
  }

  /***********************************************************************************************
   * MESSAGES
   **********************************************************************************************/

  /**
   * The maximum number of events you can retransmit at once is 100.
   * retransmitEvents method resolves to the event containing an array of VoxImplant.Messaging.MessengerEvents
   * params => eventsFrom: number, eventsTo: number, count?: number
   */
  public retransmitMessageEvents(currentConversation: any, lastEvent?: number) {
    lastEvent = lastEvent ? lastEvent : currentConversation.lastSeq;
    const eventFrom = lastEvent - 100 > 0 ? lastEvent - 100 : 1;
    store.commit('conversations/updateLastEvent', eventFrom - 1);

    return currentConversation.retransmitEvents(eventFrom, lastEvent)
      .then((e: any) => {
        let allEvents = this.conversationEvents[currentConversation.uuid];
        this.conversationEvents[currentConversation.uuid] = [...e.events, ...(allEvents || [])];

        const sendAction = VoxImplant.Messaging.MessengerAction.sendMessage;
        const editAction = VoxImplant.Messaging.MessengerAction.editMessage;
        const deleteAction = VoxImplant.Messaging.MessengerAction.removeMessage;
        const messageEvents = [];
        const filteredEvents = this.conversationEvents[currentConversation.uuid].filter((e: any) => e.messengerAction === sendAction || e.messengerAction === editAction || e.messengerAction === deleteAction );

        if (!filteredEvents.length) return [];

        // Group by message.uuid
        const groupByUuidEvents = filteredEvents.reduce((res: any, evt: any) => {
          res[evt.message.uuid] = res[evt.message.uuid] || [];
          res[evt.message.uuid].push(evt);
          return res;
        }, Object.create(null));

        // tslint:disable-next-line:forin
        // Get only relevant events for message.uuid
        for (const messageUuid in groupByUuidEvents) {
          const arrEvtsMessage = groupByUuidEvents[messageUuid];
          const isDeleted = arrEvtsMessage.find((m: any) => m.messengerAction === deleteAction);
          const isEdited = arrEvtsMessage.find((m: any) => m.messengerAction === editAction);
          if (isDeleted) {
            continue;
          } else if (isEdited) {
            if (!arrEvtsMessage.find((m: any) => m.messengerAction === sendAction)) continue;

            const sorted = arrEvtsMessage.sort((m: any) => m.timestamp);
            const initialMessage = sorted[0];
            let lastUpdated = sorted[sorted.length - 1];
            lastUpdated.message.editedAt = lastUpdated.timestamp;
            lastUpdated.timestamp = initialMessage.timestamp;
            lastUpdated.message.editedBy = lastUpdated.initiator;
            lastUpdated.initiator = initialMessage.initiator;
            logHelp('retransmit edited', initialMessage, lastUpdated);
            messageEvents.push(lastUpdated);
          } else {
            messageEvents.push(...arrEvtsMessage);
          }
        }

        logHelp(`All events in conversation ${currentConversation.title}`, this.conversationEvents[currentConversation.uuid]);

        return messageEvents;
      })
      // @ts-ignore
      .catch((e: any) => {
        logError('Retransmit message events fail', e);
        return [];
      });
  }
  public sendMessage(currentConversation: any, text: string) {
    return currentConversation.sendMessage(text, [{}])
      .catch(logError);
  }
  public removeMessage(message: any) {
    return message.remove()
      .catch(logError);
  }
  public updateMessage(message: any) {
    return message.update()
      .catch(logError);
  }
  public markAsRead(currentConversation: any, lastSeq: number) {
    return currentConversation.markAsRead(lastSeq)
      .catch(logError);
  }

  /***********************************************************************************************
   * EDIT USERS INFO
   **********************************************************************************************/

  public editUserCustomData(customData: { image: string, status: string }) {
    return MessengerService.messenger.editUser(customData);
  }
}
