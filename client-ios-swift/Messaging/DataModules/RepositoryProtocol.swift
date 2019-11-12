/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import Foundation
import VoxImplant

protocol MessagingDataSource {
    func set(delegate: VoximplantServiceDelegate)
    
    var me: VIUser? { get }
    func requestMe(completion: @escaping VIUserCompletion)
    func removeMe()
    
    func requestUser(with imID: NSNumber, completion: @escaping VIUserCompletion)
    func requestUsers(with usernameArray: [String], completion: @escaping VIUserArrayCompletion)
    func requestUsers(with imIDArray: [NSNumber], completion: @escaping VIUserArrayCompletion)
    func editUser(with customData: [String: NSObject], completion: @escaping VIUserCompletion)
    
    func createConversation(with config: VIConversationConfig, completion: @escaping VIConversationCompletion)
    
    func requestSingleConversation(with uuid: String, completion: @escaping VIConversationCompletion)
    func requestMultipleConversations(with uuids: [String], completion: @escaping VIConversationArrayCompletion)
    func recreateConversation(with UUID: String, and config: VIConversationConfig, _ lastSequence: Int?) -> VIConversation?
    
    func update(conversation: VIConversation, completion: @escaping VIConversationEventCompletion)
    func add(participants: [VIConversationParticipant], to conversation: VIConversation,
             completion: @escaping VIConversationEventCompletion)
    func edit(participants: [VIConversationParticipant], in conversation: VIConversation,
              completion: @escaping VIConversationEventCompletion)
    func remove(participants: [VIConversationParticipant], from conversation: VIConversation,
                completion: @escaping VIConversationEventCompletion)
    func leaveConversation(with UUID: String, completion: @escaping VIConversationEventCompletion)
    
    func sendMessage(with text: String, in conversation: VIConversation, completion: @escaping VIMessageEventCompletion)
    func edit(message: VIMessage, with text: String, completion: @escaping VIMessageEventCompletion)
    func remove(message: VIMessage, completion: @escaping VIMessageEventCompletion)
    func recreateMessage(with UUID: String, and conversationUUID: String) -> VIMessage?
    
    func requestMessengerEvents(for conversation: VIConversation, completion: @escaping VIEventArrayCompletion)

    func markAsRead(sequence: Int64, in conversation: VIConversation)
    func sendTyping(in conversation: VIConversation)
}

extension MessagingDataSource {
    func set(delegate: VoximplantServiceDelegate) { }
    func recreateConversation(with UUID: String, and config: VIConversationConfig, _ lastSequence: Int?) -> VIConversation? { return nil }
    func recreateMessage(with UUID: String, and conversationUUID: String) -> VIMessage? { return nil }
}

protocol Repository {
    func set(delegate: RepositoryDelegate)
    
    var me: User? { get }
    func removeMe()

    func requestUser(with imID: NSNumber, completion: @escaping UserCompletion)
    func requestUsers(with imIDs: [NSNumber], completion: @escaping UserArrayCompletion)
    func requestAllUsers(completion: @escaping UserArrayCompletion)
    func editUser(with profilePictureName: String?, and status: String?, completion: @escaping UserCompletion)
    
    func createDirectConversation(with user: User, completion: @escaping ConversationCompletion)
    func createGroupConversation(with title: String, and userModelArray: [User], description: String, pictureName: String?,
                                 isPublic: Bool, isUber: Bool, completion: @escaping ConversationCompletion)
    func createChannel(with title: String, and userModelArray: [User], description: String,
                       pictureName: String?, completion: @escaping ConversationCompletion)
    
    func requestMyConversations(completion: @escaping ConversationArrayCompletion)
    func requestConversation(with uuid: String, completion: @escaping ConversationCompletion)
    
    func add(participants: [User], to conversation: Conversation, completion: @escaping ConversationCompletion)
    func edit(participants: [Participant], in conversation: Conversation, completion: @escaping EmptyCompletion)
    func remove(participant: User, from conversation: Conversation, completion: @escaping EmptyCompletion)
    
    func update(conversation: Conversation, title: String, description: String?, pictureName: String?, isPublic: Bool?,
                            completion: @escaping EmptyCompletion)
    func update(conversation: Conversation, permissions: Permissions, completion: @escaping EmptyCompletion)
    func leave(conversation: Conversation, completion: @escaping EmptyCompletion)
    
    func requestMessengerEvents(for conversation: Conversation, completion: @escaping EventArrayCompletion)
    
    func sendMessage(with text: String, in conversation: Conversation, completion: @escaping MessageEventCompletion)
    func markAsRead(sequence: Int64, in conversation: Conversation)
    func sendTyping(to conversation: Conversation)
    
    func remove(message: Message, completion: @escaping MessageEventCompletion)
    func edit(message: Message, with text: String, completion: @escaping MessageEventCompletion)
}
