/*
 *  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
 */

import VoxImplantSDK

typealias VIUserCompletion              = (Result<VIUser, Error>)              -> Void
typealias VIUserArrayCompletion         = (Result<[VIUser], Error>)            -> Void
typealias VIConversationCompletion      = (Result<VIConversation, Error>)      -> Void
typealias VIConversationArrayCompletion = (Result<[VIConversation], Error>)    -> Void
typealias VIEventCompletion             = (Result<VIMessengerEvent, Error>)    -> Void
typealias VIEventArrayCompletion        = (Result<[VIMessengerEvent], Error>)  -> Void
typealias VIConversationEventCompletion = (Result<VIConversationEvent, Error>) -> Void
typealias VIMessageEventCompletion      = (Result<VIMessageEvent, Error>)      -> Void

protocol VoximplantDataSource: AnyObject {
    var delegate: VoximplantEventDelegate? { get set }
    
    var myUsername: String? { get }
    
    func requestUser(with username: String, completion: @escaping VIUserCompletion)
    
    func requestUsers(with usernames: [String], completion: @escaping VIUserArrayCompletion)
    
    func editUser(with customData: [String: NSObject], completion: @escaping VIUserCompletion)
    
    func createConversation(with config: VIConversationConfig,
                            completion: @escaping VIConversationEventCompletion)
    
    func updateConversation(_ conversation: VIConversation,
                            completion: @escaping VIConversationEventCompletion)
    
    func requestConversations(with uuids: [String],
                              completion: @escaping VIConversationArrayCompletion)
    
    func recreateConversation(with UUID: String,
                              and config: VIConversationConfig) -> VIConversation?
    
    func addParticipants(_ participants: [VIConversationParticipant],
                         to conversation: VIConversation,
                         completion: @escaping VIConversationEventCompletion)
    
    func editParticipants(_ participants: [VIConversationParticipant],
                          in conversation: VIConversation,
                          completion: @escaping VIConversationEventCompletion)
    
    func removeParticipants(_ participants: [VIConversationParticipant],
                            from conversation: VIConversation,
                            completion: @escaping VIConversationEventCompletion)
    
    func leaveConversation(_ uuid: String, completion: @escaping VIConversationEventCompletion)
    
    func sendMessage(text: String,
                     to conversation: VIConversation,
                     completion: @escaping VIMessageEventCompletion)
    
    func editMessage(_ message: VIMessage,
                     with text: String,
                     completion: @escaping VIMessageEventCompletion)
    
    func removeMessage(_ message: VIMessage,
                       completion: @escaping VIMessageEventCompletion)
    
    func recreateMessage(_ UUID: String,
                         conversation conversationUUID: String) -> VIMessage?
    
    func requestMessengerEvents(for conversation: VIConversation,
                                events sequenceArray: [Int64],
                                completion: @escaping VIEventArrayCompletion)
    
    func markAsRead(sequence: Int64,
                    in conversation: VIConversation,
                    completion: @escaping (Error?) -> Void)
    
    func sendTyping(in conversation: VIConversation)
}
