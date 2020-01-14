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
    let state = client.clientState

    if state == .disconnected || state  == .connecting {
        client.connect()
    } else {
        completion(.success(()))
    }
}

func login(
    with user: String,
    and password: String,
    completion: @escaping (Result<String, Error>) -> Void
) {
    connect() { result in
        if case .failure(let error) = result {
            completion(.failure(error))
        }
        if case .success = result {
            self.client.login(withUser: user,
                              password: password,
                              success: { displayName, tokens in
                                completion(.success(displayName)) },
                              failure: { error in
                                completion(.failure(error)) })
        }
    }
}

func login(
    with user: String,
    and token: String,
    completion: @escaping (Result<String, Error>) -> Void
) {
    connect() { result in
        if case .failure(let error) = result {
            completion(.failure(error))
        }
        if case .success = result {
            self.client.login(withUser: user,
                              token: token,
                              success: { displayName, tokens in
                                completion(.success(displayName)) },
                              failure: { error in
                                completion(.failure(error)) })
        }
    }
}
```

----
>Android client

**(MessagingApplication.kt)**
```kotlin
val client = Voximplant.getClientInstance(
    Executors.newSingleThreadExecutor(),
    applicationContext,
    ClientConfig()
)
val clientManager = VoxClientManager(client)
```

**(VoxClientManager.kt)**
```kotlin
fun login(
    username: String,
    password: String
) {
    when (client.clientState) {
        ClientState.DISCONNECTED ->
            try {
                client.connect()
            } catch (e: IllegalStateException) {
                Log.e(APP_TAG, "exception on connect $e")
            }

        ClientState.CONNECTED ->
            client.login(username, password)

        else -> return
    }
}

fun loginWithToken(
    username: String,
    token: String
) {
    when (client.clientState) {
        ClientState.DISCONNECTED ->
            try {
                client.connect()
            } catch (e: IllegalStateException) {
                Log.e(APP_TAG, "exception on connect $e")
            }

        ClientState.CONNECTED ->
            client.loginWithAccessToken(username, token)

        else -> return
    }
}

// Login result will be sent via the IClientLoginListener methods;
// e.g., if login is successfully completed,
// onLoginSuccessful(displayName:authParams:)
// will be called
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

**(AppDelegate.swift)**
```swift
let voximplantService =  VoximplantService(with: client.messenger)
```
**(VoximplantService.swift)**
```swift
private let messenger: VIMessenger

init(with messenger: VIMessenger) {
    self.messenger = messenger
    super.init()
    self.messenger.addDelegate(self)
}

// Call requestUser(with:completion:) with messenger.me as a username
// to get the VIUser instance for the current user
func requestUser(
    with username: String,
    completion: @escaping (Result<VIUser, Error>) -> Void
) {
    messenger.getUserByName(username, completion:
        VIMessengerCompletion<VIUserEvent> (
            success: { userEvent in
                completion(.success(userEvent.user))
            },
            failure: { errorEvent in
                completion(.failure(NSError.buildError(from: errorEvent)))
            }
        )
    )
}

// Get conversationList from the VIUser instance
// of the current user (user.conversationList).
// Call requestMultipleConversations(with:completion:) with a conversationList array
// to get all the conversations where the current user belongs to
func requestMultipleConversations(
    with uuids: [String],
    completion: @escaping (Result<[VIConversation], Error>) -> Void
) {
    messenger.getConversations(uuids, completion:
        VIMessengerCompletion<NSArray> (
            success: { conversationEvents in
                let conversations =
                    (conversationEvents as! [VIConversationEvent])
                        .map { $0.conversation }
                completion(.success(conversations))
            },
            failure: { errorEvent in
                completion(.failure(NSError.buildError(from: errorEvent)))
            }
        )
    )
}

// Get participants from each 
// VIConversation instance (conversation.participants).
// Call requestUsers(with:completion:) with a participants ImIds array 
// to get all the participants of the conversation
func requestUsers(
    with imIDArray: [NSNumber],
    completion: @escaping (Result<[VIUser], Error>) -> Void
) {
    messenger.getUsersByIMId(imIDArray, completion:
        VIMessengerCompletion<NSArray> (
            success: { event in
                let users = (event as! [VIUserEvent]).map { $0.user }
                completion(.success(users))
            },
            failure: { errorEvent in
                completion(.failure(NSError.buildError(from: errorEvent)))
            }
        )
    )
}
```

----

>Android client:

**(Repository.kt)**
```kotlin
private val remote = VoximplantService(Voximplant.getMessenger())
```

**(VoximplantService.kt)**
```kotlin
private val messenger: IMessenger

constructor(messenger: IMessenger) {
    this.messenger = messenger
    this.messenger.addMessengerListener(this)
}

// Call requestUser(username:completion:) with messenger.me as a username
// to get the IUser instance for the current user
fun requestUser(
    username: String,
    completion: (Result<IUser>) -> Unit
) {
    messenger.getUser(
        username,
        object : IMessengerCompletionHandler<IUserEvent> {
            override fun onSuccess(event: IUserEvent) {
                completion(success(event.user))
            }
            override fun onError(event: IErrorEvent) {
                completion(failure(buildError(event)))
            }
        }
    )
}

// Get conversationList from the IUser instance
// of the current user (user.conversationList).
// Call requestMultipleConversations(uuids:completion:) with conversationList 
// to get all the conversations where the current user belongs to
fun requestMultipleConversations(
    uuids: List<String>,
    completion: (Result<List<IConversation>>) -> Unit
) {
    messenger.getConversations(uuids, object :
        IMessengerCompletionHandler<List<IConversationEvent>> {
        override fun onSuccess(conversationEvents: List<IConversationEvent>) {
            completion(success(conversationEvents.map { it.conversation }))
        }
        override fun onError(errorEvent: IErrorEvent) {
            completion(failure(buildError(errorEvent)))
        }
    })
}

// Get participants from each
// IConversation instance (conversation.participants).
// Call requestUsers(imIDs:completion:) with a participants ImIds array 
// to get all the participants of the conversation
fun requestUsers(
    imIDs: List<Long>,
    completion: (Result<List<IUser>>) -> Unit
) {
    messenger.getUsersByIMId(
        imIDs,
        object : IMessengerCompletionHandler<List<IUserEvent>> {
            override fun onSuccess(userEvents: List<IUserEvent>) {
                completion(success(userEvents.map { it.user }))
            }
            override fun onError(errorEvent: IErrorEvent) {
                completion(failure(buildError(errorEvent)))
            }
        }
    )
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
func requestMultipleConversations(
    with uuids: [String],
    completion: @escaping (Result<[VIConversation], Error>) -> Void
) {
    messenger.getConversations(uuids, completion:
        VIMessengerCompletion<NSArray> (
            success: { conversationEvents in
                let conversations =
                    (conversationEvents as! [VIConversationEvent])
                        .map { $0.conversation }
                completion(.success(conversations))
            },
            failure: { errorEvent in
                completion(.failure(NSError.buildError(from: errorEvent)))
            }
        )
    )
}
```

----

>Android client **(VoximplantService.kt)**:
```kotlin
fun requestMultipleConversations(
    uuids: List<String>,
    completion: (Result<List<IConversation>>) -> Unit
) {
    messenger.getConversations(uuids, object :
        IMessengerCompletionHandler<List<IConversationEvent>> {
        override fun onSuccess(conversationEvents: List<IConversationEvent>) {
            completion(success(conversationEvents.map { it.conversation }))
        }
        override fun onError(errorEvent: IErrorEvent) {
            completion(failure(buildError(errorEvent)))
        }
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
func createConversation(
    with title: String, and userImids: [NSNumber],
    description: String, pictureName: String?,
    isPublic: Bool, isUber: Bool, permissions: Permissions,
    completion: @escaping (Result<VIConversation, Error>) -> Void
) {
    let config = VIConversationConfig()
    config.title = title
    config.isDirect = false
    config.isUber = isUber
    config.isPublicJoin = isPublic
    config.participants = userImIds
        .map { self.builder.buildVIParticipant(with: $0, and: permissions) }
    config.customData = builder
        .buildCustomData(for: .chat, with: pictureName, and: description)
    
    messenger.createConversation(config, completion:
        VIMessengerCompletion<VIConversationEvent> (
            success: { conversationEvent in
                completion(.success(conversationEvent.conversation))
            },
            failure: { errorEvent in
                completion(.failure(NSError.buildError(from: errorEvent)))
            }
        )
    )
}
```

----
>Android client (**VoximplantService.kt**):
```kotlin
fun createConversation(
    title: String, userImIds: List<Long>, description: String,
    pictureName: String?, isPublic: Boolean, isUber: Boolean,
    permissions: Permissions, completion: (Result<IConversationEvent>) -> Unit
) {
    val config = ConversationConfig.createBuilder()
        .setTitle(title)
        .setDirect(false)
        .setUber(isUber)
        .setPublicJoin(isPublic)
        .setParticipants(
            userImIds
                .map { builder.buildParticipant(it, permissions) }
        )
        .setCustomData(
            builder.buildCustomData(
                ConversationType.CHAT, pictureName, description
            )
        )
        .build()

    messenger.createConversation(
        config,
        object : IMessengerCompletionHandler<IConversationEvent> {
            override fun onSuccess(conversationEvent: IConversationEvent) {
                completion(success(conversationEvent))
            }
            override fun onError(errorEvent: IErrorEvent) {
                completion(failure(buildError(errorEvent)))
            }
        }
    )
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
// Update the VIConversation instance properties and
// call update(conversation:completion:) to update this conversation;
// for example:
// conversation.title = “newTitle”
// conversation.isPublicJoin = true
// update(conversation: conversation) { result in
//     // handle result
// }
func update(
    conversation: VIConversation,
    completion: @escaping (Result<VIConversationEvent, Error>) -> Void
) {
    conversation.update(completion:
        VIMessengerCompletion<VIConversationEvent> (
            success: { conversationEvent in
                completion(.success(conversationEvent))
            },
            failure: { errorEvent in
                completion(.failure(NSError.buildError(from: errorEvent)))
            }
        )
    )
}
```

----
>Android client (**VoximplantService.kt**):
```kotlin
// Update the IConversation instance properties and
// call updateConversation(conversation:completion:) to update this conversation;
// for example:
// conversation.title = “newTitle”
// conversation.isPublicJoin = true
// updateConversation(conversation) { result ->
//     // handle result
// }
fun updateConversation(
    conversation: IConversation,
    completion: (Result<IConversationEvent>) -> Unit
) {
    conversation.update(
        object : IMessengerCompletionHandler<IConversationEvent> {
            override fun onSuccess(conversationEvent: IConversationEvent) {
                completion(success(conversationEvent))
            }
            override fun onError(errorEvent: IErrorEvent) {
                completion(failure(buildError(errorEvent)))
            }
        }
    )
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
func edit(
    participants: [VIConversationParticipant],
    in conversation: VIConversation,
    completion: @escaping (Result<VIConversationEvent, Error>) -> Void
) {
    conversation.editParticipants(participants, completion:
        VIMessengerCompletion<VIConversationEvent> (
            success: { conversationEvent in
                completion(.success(conversationEvent))
            },
            failure: { errorEvent in
                completion(.failure(NSError.buildError(from: errorEvent)))
            }
        )
    )
}
```
----
>Android client (**VoximplantService.kt**):
```kotlin
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
        }
    )
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
func add(
    participants: [VIConversationParticipant],
    to conversation: VIConversation,
    completion: @escaping (Result<VIConversationEvent, Error>) -> Void
) {
    conversation.addParticipants(participants, completion:
        VIMessengerCompletion<VIConversationEvent> (
            success: { conversationEvent in
                completion(.success(conversationEvent))
            },
            failure: { errorEvent in
                completion(.failure(NSError.buildError(from: errorEvent)))
            }
        )
    )
}

func remove(
    participants: [VIConversationParticipant],
    from conversation: VIConversation,
    completion: @escaping (Result<VIConversationEvent, Error>) -> Void
) {
    conversation.removeParticipants(participants, completion:
        VIMessengerCompletion<VIConversationEvent> (
            success: { conversationEvent in
                completion(.success(conversationEvent))
            },
            failure: { errorEvent in
                completion(.failure(NSError.buildError(from: errorEvent)))
            }
        )
    )
}
```
----
>Android client (**VoximplantService.kt**):
```kotlin
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
        }
    )
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
        }
    )
}
```

And this is the method that allows users to leave a conversation:

>Web client (**messenger.service.ts**)
```typescript
public leaveConversation(currentConversationUuid: string) {
    MessengerService.messenger.leaveConversation(currentConversationUuid)
      .catch(logError);
  }
```
----
>iOS client (**VoximplantService.swift**):
```swift
func leaveConversation(
    with UUID: String,
    completion: @escaping (Result<VIConversationEvent, Error>) -> Void
) {
    messenger.leaveConversation(UUID, completion:
        VIMessengerCompletion<VIConversationEvent> (
            success: { conversationEvent in
                completion(.success(conversationEvent))
            },
            failure: { errorEvent in
                completion(.failure(NSError.buildError(from: errorEvent)))
            }
        )
    )
}
```
----
>Android client (**VoximplantService.kt**):
```kotlin
fun leaveConversation(
    uuid: String,
    completion: (Result<IConversationEvent>) -> Unit
) {
    messenger.leaveConversation(
        uuid,
        object : IMessengerCompletionHandler<IConversationEvent> {
            override fun onSuccess(conversationEvent: IConversationEvent) {
                completion(success(conversationEvent))
            }
            override fun onError(errorEvent: IErrorEvent) {
                completion(failure(buildError(errorEvent)))
            }
        }
    )
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

We’ve added delegate on VoximplantService initialization step:
```swift
self.messenger.addDelegate(self)
```

Send messages and receive didSendMessage events:
```swift
// Note that if a completion block is specified in a method call,
// the didSendMessage event won’t be triggered
func sendMessage(
    with text: String,
    in conversation: VIConversation,
    completion: @escaping (Result<VIMessageEvent, Error>) -> Void
) {
    conversation.sendMessage(text, payload: nil, completion:
        VIMessengerCompletion<VIMessageEvent> (
            success: { messageEvent in
                completion(.success(messageEvent))
            },
            failure: { errorEvent in
                completion(.failure(NSError.buildError(from: errorEvent)))
            }
        )
    )
}

func messenger(_ messenger: VIMessenger,
               didSendMessage event: VIMessageEvent) {
    delegate?.didReceive(messageEvent: event)
}
```

See the listing of the **VIMessengerDelegate** functions below:
```swift
func messenger(_ messenger: VIMessenger,
               didEditMessage event: VIMessageEvent) {
    delegate?.didReceive(messageEvent: event)
}

func messenger(_ messenger: VIMessenger,
               didSendMessage event: VIMessageEvent) {
    delegate?.didReceive(messageEvent: event)
}

func messenger(_ messenger: VIMessenger,
               didRemoveMessage event: VIMessageEvent) {
    delegate?.didReceive(messageEvent: event)
}

func messenger(_ messenger: VIMessenger,
               didCreateConversation event: VIConversationEvent) {
    delegate?.didReceive(conversationEvent: event)
}

func messenger(_ messenger: VIMessenger,
               didRemoveConversation event: VIConversationEvent) {
    delegate?.didReceive(conversationEvent: event)
}

func messenger(_ messenger: VIMessenger,
               didEditConversation event: VIConversationEvent) {
    delegate?.didReceive(conversationEvent: event)
}

func messenger(_ messenger: VIMessenger,
               didReceiveTypingNotification event: VIConversationServiceEvent) {
    delegate?.didReceive(serviceEvent: event)
}

func messenger(_ messenger: VIMessenger,
               didReceiveReadConfirmation event: VIConversationServiceEvent) {
    delegate?.didReceive(serviceEvent: event)
}

func messenger(_ messenger: VIMessenger,
               didEditUser event: VIUserEvent) {
    delegate?.didReceive(userEvent: event)
}
```

----
>Android client (**VoximplantService.kt**):

We’ve added listener on VoximplantService initialization step:
```kotlin
this.messenger.addMessengerListener(this)
```
Send messages and receive onSendMessage events:
```kotlin
// Note that if a completion block is specified in a method call,
// the onSendMessage event won’t be triggered
fun sendMessage(
    text: String,
    conversation: IConversation,
    completion: (Result<IMessageEvent>) -> Unit
) {
    conversation.sendMessage(
        text,
        null,
        object : IMessengerCompletionHandler<IMessageEvent> {
            override fun onSuccess(messageEvent: IMessageEvent) {
                completion(success(messageEvent))
            }
            override fun onError(errorEvent: IErrorEvent) {
                completion(failure(buildError(errorEvent)))
            }
        }
    )
}

override fun onSendMessage(event: IMessageEvent) {
    listener?.onMessageEvent(event)
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

Edit messages and receive didEditMessage events:
```swift
// Note that if a completion block is specified in a method call,
// the didEditMessage event won’t be triggered:
func edit(
    message: VIMessage,
    with text: String,
    completion: @escaping (Result<VIMessageEvent, Error>) -> Void
) {
    message.update(text, payload: nil, completion:
        VIMessengerCompletion<VIMessageEvent> (
            success: { messageEvent in
                completion(.success(messageEvent))
            },
            failure: { errorEvent in
                completion(.failure(NSError.buildError(from: errorEvent)))
            }
        )
    )
}

func messenger(_ messenger: VIMessenger,
               didEditMessage event: VIMessageEvent) {
    delegate?.didReceive(messageEvent: event)
}
```
----
>Android client (**VoximplantService.kt**):

Edit messages and receive onEditMessage events:
```kotlin
// Note that if a completion block is specified in a method call,
// the onEditMessage event won’t be triggered:
fun editMessage(
    message: IMessage,
    text: String,
    completion: (Result<IMessageEvent>) -> Unit
) {
    message.update(
        text,
        null,
        object : IMessengerCompletionHandler<IMessageEvent> {
            override fun onSuccess(messageEvent: IMessageEvent) {
                completion(success(messageEvent))
            }
            override fun onError(errorEvent: IErrorEvent) {
                completion(failure(buildError(errorEvent)))
            }
        }
    )
}

override fun onEditMessage(event: IMessageEvent) {
    listener?.onMessageEvent(event)
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

Remove messages and receive didRemoveMessage events:
```swift
// Note that if a completion block is specified in a method call,
// the didRemoveMessage event won’t be triggered:
func remove(
    message: VIMessage,
    completion: @escaping (Result<VIMessageEvent, Error>) -> Void
) {
    message.remove(completion:
        VIMessengerCompletion<VIMessageEvent> (
            success: { messageEvent in
                completion(.success(messageEvent))
            },
            failure: { errorEvent in
                completion(.failure(NSError.buildError(from: errorEvent)))
            }
        )
    )
}

func messenger(_ messenger: VIMessenger,
               didRemoveMessage event: VIMessageEvent) {
    delegate?.didReceive(messageEvent: event)
}
```
----
>Android client (**VoximplantService.kt**):

Remove messages and receive onRemoveMessage events:
```kotlin
// Note that if a completion block is specified in a method call,
// the onRemoveMessage event won’t be triggered:
fun removeMessage(
    message: IMessage,
    completion: (Result<IMessageEvent>) -> Unit
) {
    message.remove(
        object : IMessengerCompletionHandler<IMessageEvent> {
            override fun onSuccess(messageEvent: IMessageEvent) {
                completion(success(messageEvent))
            }
            override fun onError(errorEvent: IErrorEvent) {
                completion(failure(buildError(errorEvent)))
            }
        }
    )
}

override fun onRemoveMessage(event: IMessageEvent) {
    listener?.onMessageEvent(event)
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

In the Web SDK, there is a **retransmitEvents** method that returns maximum 100 events. 

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

In the iOS SDK, there are three methods, each of them returns maximum 100 events:
**retransmitEvents
retransmitEventsFrom
retransmitEventsTo**

In example of **retransmitEvents**, it accepts two required parameters, **to** and **count**, in order to specify the range of events. The **to** value should be retrieved from the lastSequence property of a conversation and **count** is just a number of maximum of 100.

Implement this code to enable retransmitting:

```swift
func requestMessengerEvents(
    for conversation: VIConversation,
    completion: @escaping (Result<[VIMessengerEvent], Error>) -> Void
) {
    conversation.retransmitEvents(
        to: conversation.lastSequence,
        count: UInt(100),
        completion: VIMessengerCompletion<VIRetransmitEvent> (
            success: { retransmitEvents in
                completion(.success(retransmitEvents.events))
            },
            failure: { errorEvent in
                completion(.failure(NSError.buildError(from: errorEvent)))
            }
        )
    )
}
```
----
>Android client (**VoximplantService.kt**):

In the Android SDK, there are three methods, each of them returns maximum 100 events:
**retransmitEvents
retransmitEventsFrom
retransmitEventsTo**

In example of **retransmitEventsTo**, it accepts two required parameters, **to** and **count**, in order to specify the range of events.

Implement this code to enable retransmitting:

```kotlin
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
        }
    )
}
```
