Messaging allows you to implement text communications within main Voximplant developer account: account users can log in via Voximplant SDKs and become participants in conversations. Follow this tutorial to learn how to create your own web and mobile messaging client based on our SDKs.

## WHAT YOU NEED
* Voximplant developer account. If you don’t have one, [sign up here](https://voximplant.com/sign-up/).
* Voximplant application, JS scenario, rule, and two users. Those will be created during this tutorial.
* Client for users to log in. We’ll use our demo clients for Web and iOS.
* Backend server for storing users of a Voximplant application. 

## BACKEND SERVER
It’s for the better to make a request for all available users within a Voximplant application at each client’s start. In order to do so, the client has to request all users related to already created conversation by using your Voximplant account credentials.
This is where the backend server is in need: we don’t want to store private authorization on the client side since it’s totally insecure (chances are you don’t want it either), so we can delegate it to backend. We’ve implemented a backend server using PHP, check the full listing of it [here](https://github.com/voximplant/solutions-messaging/blob/master/server/index.php). You’re free to either use our solution or implement your own server using another programming language.

## 1. VOXIMPLANT APPLICATION SETTINGS
First, log in to your account here: https://manage.voximplant.com/auth. On the left menu, select **Applications**, click **New application** and create a **messaging** application. 
Next, you have to create at least two users for your application. Switch to the **Users** tab, click **Create user**, set username (e.g., user1) and password, then select the **Create another** checkbox and click **Create**. The same window for creating the second user will appear in which you should unselect **Create another** as we don’t need more users. We’ll need these users’ login-password pairs to authenticate in the clients.

## 2. CLIENT
### Connect to Voximplant and login

Initialize your project depending on what type of client you are going to use. 

First, you have to make the login screen to work properly. The client has to know what credentials to use for authentication. 

>Web client

Open the **vox.service.ts** and use the following code for connection and authentication to the Voximplant cloud:

```typescript
// Create Voximplant Web SDK instance
    VoxService.inst = VoxImplant.getInstance();

    // Reconnect to the Voximplant cloud when disconnected
    VoxService.inst.on(VoxImplant.Events.ConnectionClosed, () => {
      log('Connection was closed');
      this.connectToVoxCloud();
    });

    // Init Voximplant
    VoxService.inst.init({
      experiments: {
        messagingV2: true,
      },
    })
      .then(() => {
        log('SDK initialized');
        // Connect to the Voximplant cloud
        this.connectToVoxCloud();
      })
      .catch(logError);

public onLogin(loginForm, accessToken) {
    if (!accessToken) {
      return VoxService.inst.login(loginForm.user, loginForm.password);
    } else {
      return VoxService.inst.loginWithToken(loginForm.user, accessToken);
    }
  }
```
----
>iOS client

Open the **AuthService.swift** and use the following code for connection and authentication to the Voximplant cloud:


**(AppDelegate.swift)**
```swift
let client = VIClient(delegateQueue: DispatchQueue.main)
let authService = AuthService(client: client)
```

**(AuthService.swift)**
```swift
func connect(_ completion: @escaping (Result<(), Error>) -> Void) {
       if client.clientState == .disconnected || client.clientState == .connecting {
           connectCompletion = completion
           client.connect()
       } else {
           completion(.success(()))
       }
   }

func login(with user: String, and password: String, completion: @escaping (Result<String, Error>) -> Void) {
       connect() { result in
           if case .failure(let error) = result { completion(.failure(error)) }
           if case .success = result {
               self.client.login(withUser: user, password: password, success: { displayName, tokens in
                   completion(.success(displayName))
               }) { error in
                   completion(.failure(error))
               }
           }
       }
   }

func login(with user: String, and token: String, completion: @escaping (Result<String, Error>) -> Void) {
       connect() { result in
           if case .failure(let error) = result { completion(.failure(error)) }
           if case .success = result {
               self.client.login(withUser: user, token: token, success: { displayName, tokens in
                   completion(.success(displayName))
               }) { error in
                   completion(.failure(error))
               }
           }
       }
   }
```

After successful initialization the client renders the login screen where you specify credentials, click **Sign in** and after that the client can log in to the Messaging module.  

We suggest that this part of the code should do the following:
- initiates a messaging instance
- gets the current user info
- gets all the conversation where the current user belong to
- receive other users from backend
- add listeners for events that will be triggering over WebSockets


>Web client

All the methods related to communication with Messaging are comprised in the **messenger.service.ts** file. 

```typescript
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
    const initialData = {
      currentUser: {},
      conversations: [],
      users: [],
    };

    await MessengerService.messenger.getUser(MessengerService.messenger.getMe())
      .then((evt) => {
        logHelp('Current user data received', evt);
        initialData.currentUser = evt.user;

        return this.getCurrentConversations(evt.user.conversationsList);
      })
      .then((evts) => {
        logHelp('Current user conversations received', evts);

        initialData.conversations = evts.length ? evts.map((e) => e.conversation) : [];
        return this.getAllUsers();
      })
      .then((evts) => {
        logHelp('Conversation participants user info received', evts);
        initialData.users = evts.map((e) => e.user);
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
```
----

>iOS client:
```swift
(AppDelegate.swift)
let voximplantService =  VoximplantService(with: client.messenger)

 (VoximplantService.swift)
private let messenger: VIMessenger
   init(with messenger: VIMessenger) {
       self.messenger = messenger
       super.init()
       self.messenger.addDelegate(self)
   }

func requestUser(with username: String, completion: @escaping VIUserCompletion) {
       messenger.getUserByName(username, completion: VIMessengerCompletion<VIUserEvent> (success:
           { userEvent in
               completion(.success(userEvent.user)) })
           { errorEvent in
               completion(.failure(NSError.buildError(from: errorEvent)))
           })
   }
```

From now on, your login screen allows users to authenticate in your client. 

### Retrieve conversations
The client can retrieve all conversations that your user belongs to via the **getConversations** method:

>Web client (**messenger.service.ts**):
```typescript
private getCurrentConversations(conversationsList) {
    return MessengerService.messenger.getConversations(conversationsList).catch((e) => {
      logError('MessengerService.getCurrentConversations', e);
      return [];
    });
  }
```
----
>iOS client (**VoximplantService.swift**):
```swift
func requestMultipleConversations(with uuids: [String], completion: @escaping (Result<[VIConversation], Error>) -> Void) {
       messenger.getConversations(uuids, completion: VIMessengerCompletion<NSArray> (success:
           { conversationEvents in
               let conversationEvents = conversationEvents as! [VIConversationEvent]
               let conversations = conversationEvents.map { conversationEvent in conversationEvent.conversation }
               completion(.success(conversations))
           })
           { errorEvent in
               completion(.failure(NSError.buildError(from: errorEvent)))
           })
   }
```
## Create conversations

Voximplant Messaging allows creating different types of conversations: regular (public and non-public) and direct ones, see the details here.  In these particular demo clients they are implemented as chat, direct and broadcast. To create a conversation, there is a **createConversation** method, whereas demo clients have appropriate wrappers for it.

>**Client-specific note**
>
>Permissions that are specified on creating a conversation become **default permissions** for this particular conversation; this means that all new participants will inherit them. If none of permissions is specified on creating a conversation, the following ones will be applied: **canRead**, **canWrite**, **canRemove**.

Here is an example of how to create a chat where all members can write and see messages of each other:

>Web client (**messenger.service.ts**)
```typescript
private createNewConversation(participants, title: string, direct:boolean, publicJoin:boolean, uber:boolean, customData:object) {
    return MessengerService.messenger.createConversation(participants, title, direct, publicJoin, uber, customData);
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
```
----
>iOS client (**VoximplantService.swift**):
```swift
func createConversation(with config: VIConversationConfig, completion: @escaping (Result<VIConversation, Error>) -> Void) {
       messenger.createConversation(config, completion: VIMessengerCompletion<VIConversationEvent> (success:
           { conversationEvent in
               completion(.success(conversationEvent.conversation)) })
           { errorEvent in
               completion(.failure(NSError.buildError(from: errorEvent)))
           })
   }
```


Pay attention that conversations are created on behalf of a user which is currently logged in on your client. That means this user becomes the owner and the very first admin of a newly created application with all possible permissions (see the details on permissions here).

Once a conversation is created, others can join it or be joined by administrators of the conversation.

### Managing conversations
Being an administrator, your user can edit conversations and also leave them. It’s possible due to the **addParticipants**, **removeParticipants**, **addAdmins**, **removeAdmins**, **editPermissions** and **leaveConversation** methods. 

Editing includes changing of:
- the title
- users’ permissions
- number of users (add/remove users)
- custom data

Let’s assume that the administrator wants to change all the mentioned aspects – this is how you can handle it by calling the appropriate methods.

The method to change the title and custom data. Custom data changing has a nuance: you can’t just pass changes of one field, you have to copy all other fields, otherwise, other fields will be deleted.

>Web client (**actionConversations.ts**)
```typescript
editConversation: ({ getters }, newData) => {
    if (newData.title && newData.title !== getters.currentConversation.title) {
      getters.currentConversation.setTitle(newData.title)
        .catch(logError);
    }

    if (newData.customData) {
      getters.currentConversation.setCustomData({...getters.currentConversation.customData, ...newData.customData})
        .catch(logError);
    }
  }
```
----
>iOS client (**VoximplantService.swift**):

```swift
func update(conversation: VIConversation, title: String, customData: CustomData, completion: @escaping (Result<(), Error>) -> Void) {
       conversation.title = title
       conversation.customData = customData
       remoteDataSource.update(conversation: conversation) { result in
           if case .failure (let error) = result { completion(.failure(error)) }
           if case .success = result { completion(.success(())) }
       }
   }

func update(conversation: VIConversation, completion: @escaping (Result<VIConversationEvent, Error>) -> Void) {
       conversation.update(completion: VIMessengerCompletion<VIConversationEvent> (success:
           { conversationEvent in
               completion(.success(conversationEvent))
           })
           { errorEvent in
               completion(.failure(NSError.buildError(from: errorEvent)))
           })
   }
```

The method to change some of the user’s permissions

>Web client (**messenger.service.ts**)
```typescript
public editPermissions(currentConversation: Conversation, permissions: Permissions, allUserIds: number[]) {
    currentConversation.setCustomData({ ...currentConversation.customData, permissions });
    return currentConversation.editParticipants(allUserIds.map((userId) => ({
      userId,
      ...permissions,
    }))).catch(logError);
  }
```
----
>iOS client (**VoximplantService.swift**):
```swift
func edit(participants: [VIConversationParticipant], in conversation: VIConversation, completion: @escaping (Result<VIConversationEvent, Error>) -> Void) {
       conversation.editParticipants(participants, completion: VIMessengerCompletion<VIConversationEvent> (success:
           { conversationEvent in
               completion(.success(conversationEvent))
           })
           { errorEvent in
               completion(.failure(NSError.buildError(from: errorEvent)))
           })
   }
```

The methods for adding and removing users

>Web client (**messenger.service.ts**)

```typescript
public addParticipants(currentConversation: Conversation, userIds: number[]) {
    return currentConversation.addParticipants(userIds.map((userId) => ({
      userId,
      ...currentConversation.customData.permissions,
    }))).catch(logError);
  }

public removeParticipants(currentConversation: Conversation, userIds: number[]) {
    return currentConversation.removeParticipants(userIds.map((userId) => ({userId}))).catch(logError);
  }
```
----
>iOS client (**VoximplantService.swift**):
```swift
func add(participants: [VIConversationParticipant], to conversation: VIConversation, completion: @escaping (Result<VIConversationEvent, Error>) -> Void) {
       conversation.addParticipants(participants, completion: VIMessengerCompletion<VIConversationEvent> (success:
           { conversationEvent in
               completion(.success(conversationEvent))
           })
           { errorEvent in
               completion(.failure(NSError.buildError(from: errorEvent)))
           })
   }

func remove(participants: [VIConversationParticipant], from conversation: VIConversation, completion: @escaping (Result<VIConversationEvent, Error>) -> Void) {
       conversation.removeParticipants(participants, completion: VIMessengerCompletion<VIConversationEvent> (success:
           { conversationEvent in
               completion(.success(conversationEvent))
           })
           { errorEvent in
               completion(.failure(NSError.buildError(from: errorEvent)))
           })
   }
```

And this is the method that allows users to leave a conversation:

Web client (**messenger.service.ts**)
```typescript
public leaveConversation(currentConversationUuid: string) {
    MessengerService.messenger.leaveConversation(currentConversationUuid)
      .catch(logError);
  }
```
----
iOS client (**VoximplantService.swift**):
```swift
func leaveConversation(with UUID: String, completion: @escaping (Result<VIConversationEvent, Error>) -> Void) {
       messenger.leaveConversation(UUID, completion: VIMessengerCompletion<VIConversationEvent> (success:
           { conversationEvent in
               completion(.success(conversationEvent))
           })
           { errorEvent in
               completion(.failure(NSError.buildError(from: errorEvent)))
           })
   }
```
The last method could come in handy if you need to remove the conversation: the owner can remove all other participants, then leave the conversation and that is how it would be deleted.

### Send/receive messages
The following method is responsible for sending messages: **sendMessage**.

To receive messages, you have to handle the event on message sending. Sending messages works in the same, event-driven way.


>Web client (**messenger.service.ts**)

We’ve added this on initialization step (**addMessengerEventListeners**).
See the listing of the **addMessengerEventListeners** function below:

```typescript
private addMessengerEventListeners() {
    // Listen to other users presence status event
    MessengerService.messenger.on(VoxImplant.Messaging.MessengerEvents.SetStatus, (e) => store.dispatch('conversations/onOnlineReceived', e));

    // Listen to CreateConversation event called by this or another user
    MessengerService.messenger.on(VoxImplant.Messaging.MessengerEvents.CreateConversation, (e) => store.dispatch('conversations/onConversationCreated', e));

    // Listen to EditConversation event called by this or another user
    MessengerService.messenger.on(VoxImplant.Messaging.MessengerEvents.EditConversation, (e) => store.dispatch('conversations/onConversationEdited', e));

    // Listen to incoming messages
    MessengerService.messenger.on(VoxImplant.Messaging.MessengerEvents.SendMessage, (e) => store.dispatch('conversations/onMessageSent', e));

    // Listen to edited messages
    MessengerService.messenger.on(VoxImplant.Messaging.MessengerEvents.EditMessage, (e) => store.dispatch('conversations/onMessageEdited', e));

    // Listen to deleted messages
    MessengerService.messenger.on(VoxImplant.Messaging.MessengerEvents.RemoveMessage, (e) => store.dispatch('conversations/onMessageDeleted', e));

    // Listen to markAsRead message
    MessengerService.messenger.on(VoxImplant.Messaging.MessengerEvents.Read, (e) => store.dispatch('conversations/onMessageMarkAsRead', e));

    // Listen to typing event
    MessengerService.messenger.on(VoxImplant.Messaging.MessengerEvents.Typing, (e) => store.dispatch('conversations/onNotifyTyping', e));
  }
```
----
>iOS client (**VoximplantService.swift**):

We’ve added this on initialization step.
See the listing of the **VIMessengerDelegate** functions below:
```swift
func messenger(_ messenger: VIMessenger, didEditMessage event: VIMessageEvent) {
       delegate?.didReceive(messageEvent: event)
   }
   func messenger(_ messenger: VIMessenger, didSendMessage event: VIMessageEvent) {
       delegate?.didReceive(messageEvent: event)
   }
   func messenger(_ messenger: VIMessenger, didRemoveMessage event: VIMessageEvent) {
       delegate?.didReceive(messageEvent: event)
   }
   func messenger(_ messenger: VIMessenger, didCreateConversation event: VIConversationEvent) {
       delegate?.didReceive(conversationEvent: event)
   }
   func messenger(_ messenger: VIMessenger, didRemoveConversation event: VIConversationEvent) {
       delegate?.didReceive(conversationEvent: event)
   }
   func messenger(_ messenger: VIMessenger, didEditConversation event: VIConversationEvent) {
       delegate?.didReceive(conversationEvent: event)
   }
   func messenger(_ messenger: VIMessenger, didReceiveTypingNotification event: VIConversationServiceEvent) {
       if event.imUserId == me?.imId { return }
       delegate?.didReceive(serviceEvent: event)
   }
   func messenger(_ messenger: VIMessenger, didReceiveReadConfirmation event: VIConversationServiceEvent) {
       if event.imUserId == me?.imId { return }
       delegate?.didReceive(serviceEvent: event)
   }
   func messenger(_ messenger: VIMessenger, didEditUser event: VIUserEvent) {
       delegate?.didReceive(userEvent: event)
   }
```


### Edit/remove messages
To track changes of other messages, you have to subscribe to the **EditMessage** / **didEditMessage** and **RemoveMessage** / **didRemoveMessage** events as has been shown above.

To edit your messages, use the appropriate method:

>Web client (**actionMessages.ts**)
```typescript
editMessage: (context, newData) => {
    newData.message.text = newData.newText;
    MessengerService.get().updateMessage(newData.message)
      .catch(logError);
  },
```
----
>iOS client (**VoximplantService.swift**):
```swift
func edit(message: VIMessage, with text: String, completion: @escaping (Result<VIMessageEvent, Error>) -> Void) {
       message.update(text, payload: nil, completion: VIMessengerCompletion<VIMessageEvent> (success:
           { messageEvent in
               completion(.success(messageEvent))
           })
           { errorEvent in
               completion(.failure(NSError.buildError(from: errorEvent)))
           })
   }
```

To remove your messages, use the following method:

>Web client (**actionMessages.ts**)

```typescript
deleteMessage: (context, message) => {
    MessengerService.get().removeMessage(message)
      .catch(logError);
  },
```
----
>iOS client (**VoximplantService.swift**):
```swift
func remove(message: VIMessage, completion: @escaping (Result<VIMessageEvent, Error>) -> Void) {
       message.remove(completion: VIMessengerCompletion<VIMessageEvent> (success:
           { messageEvent in
               completion(.success(messageEvent))
           })
           { errorEvent in
               completion(.failure(NSError.buildError(from: errorEvent)))
           })
   }
```

### Retransmit events
There is a great variety of possible actions in a conversation and each of them triggers an appropriate event:
- new user has been added
- users’ permissions have been changed
- conversation type has been changed
- a new message has been sent to a conversation
- and so on.

If a user is logged in to a client, each and every one of these events can be tracked by using listeners, but it won’t work if a user hasn’t been logged in. For example, the admin added a new participant to a conversation. There possibly could be a lot of other events between the adding itself and the moment when a newly added user will log in to messaging. How to ensure that the client with this user will retrieve all events that had triggered before the login? Retransmitting events is the answer.

Each time when a user logs in, you have to retransmit events that triggered before – this is the way to keep users up to date. 

There is a **retransmitEvents** method that returns maximum 100 events. 

>Web client (**messenger.service.ts**)

It accepts two required parameters, **eventFrom** and **lastEvent**, in order to specify the range of events. As each conversation object has the **lastSeq** field, it could be passed to the **lastEvent** parameter; **eventFrom** should be retrieved from the **seq** field of an event.

Implement this code to enable retransmitting:
```typescript
public retransmitMessageEvents(currentConversation: any, lastEvent?: number) {
    lastEvent = lastEvent ? lastEvent : currentConversation.lastSeq;
    const eventFrom = lastEvent - 100 > 0 ? lastEvent - 100 : 1;
    store.commit('conversations/updateLastEvent', eventFrom - 1);
 
    return currentConversation.retransmitEvents(eventFrom, lastEvent)
      .then(async (e) => {
        // event handling
      })
      .catch(logError);
  }
```
----
>iOS client (**VoximplantService.swift**):

It accepts two required parameters, **to** and **count**, in order to specify the range of events. The **eventFrom** value should be retrieved from the **seq** field of an event and **count** is just a number of maximum of 100.

Implement this code to enable retransmitting:

```swift
func requestMessengerEvents(for conversation: VIConversation, completion: @escaping (Result<[VIMessengerEvent], Error>) -> Void) {
       conversation.retransmitEvents(to: conversation.lastSequence, count: UInt(100),completion: VIMessengerCompletion<VIRetransmitEvent> (success:
           { retransmitEvents in
               completion(.success(retransmitEvents.events)) })
           { errorEvent in
               completion(.failure(NSError.buildError(from: errorEvent)))
           })
   }
```