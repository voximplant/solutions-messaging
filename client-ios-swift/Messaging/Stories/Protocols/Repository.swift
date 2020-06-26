/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import VoxImplantSDK

typealias ConversationCompletion = (Result<Conversation, Error>) -> Void

protocol Repository: AnyObject {
    var typingObserver: ((Participant) -> Void)? { get set }
    
    func editUser(with profilePictureName: String?,
                  and status: String?,
                  completion: @escaping (Error?) -> Void)
    
    func createDirectConversation(with userID: User.ID,
                                  completion: @escaping ConversationCompletion)
    
    func createGroupConversation(with title: String, and users: Set<User.ID>,
                                 description: String, pictureName: String?,
                                 isPublic: Bool, isUber: Bool,
                                 completion: @escaping ConversationCompletion)
    
    func createChannel(with title: String, and users: Set<User.ID>,
                       description: String, pictureName: String?,
                       completion: @escaping ConversationCompletion)
    
    func updateConversation(_ conversation: Conversation, title: String,
                            description: String?, pictureName: String?,
                            isPublic: Bool?, completion: @escaping (Error?) -> Void)
    
    func updateConversation(_ conversation: Conversation,
                            permissions: Permissions,
                            completion: @escaping (Error?) -> Void)
    
    func addUsers(to conversation: Conversation,
                  users: Set<User.ID>,
                  completion: @escaping (Error?) -> Void)
    
    func editParticipants(_ participants: [Participant],
                          in conversation: Conversation,
                          completion: @escaping (Error?) -> Void)
    
    func removeUser(from conversation: Conversation,
                    _ user: User.ID,
                    completion: @escaping (Error?) -> Void)
    
    func leaveConversation(_ conversation: Conversation,
                           completion: @escaping (Error?) -> Void)
    
    func markAsRead(sequence: Int64, conversation: Conversation)
    
    func sendTyping(to conversation: Conversation)
    
    func sendMessage(with text: String, conversation: Conversation,
                     completion: @escaping (Error?) -> Void)
    
    func editMessage(with uuid: String, conversation: Conversation.ID,
                     text: String, completion: @escaping (Error?) -> Void)
    
    func removeMessage(with uuid: String, conversation: Conversation.ID,
                       completion: @escaping (Error?) -> Void)
}
