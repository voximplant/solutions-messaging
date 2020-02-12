/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import Foundation
import VoxImplantSDK

final class CoreDataManager: MessagingDataSource {
    var me: VIUser?
    
    func requestMe(completion: @escaping VIUserCompletion) {
        
    }
    
    func removeMe() {
        
    }
    
    func requestUser(with imID: NSNumber, completion: @escaping VIUserCompletion) {
        
    }
    
    func requestUsers(with usernameArray: [String], completion: @escaping VIUserArrayCompletion) {
        
    }
    
    func requestUsers(with imIDArray: [NSNumber], completion: @escaping VIUserArrayCompletion) {
        
    }
    
    func editUser(with customData: [String : NSObject], completion: @escaping VIUserCompletion) {
        
    }
    
    func createConversation(with config: VIConversationConfig, completion: @escaping VIConversationCompletion) {
        
    }
    
    func requestSingleConversation(with uuid: String, completion: @escaping VIConversationCompletion) {
        
    }
    
    func requestMultipleConversations(with uuids: [String], completion: @escaping VIConversationArrayCompletion) {
        
    }
    
    func update(conversation: VIConversation, completion: @escaping VIConversationEventCompletion) {
        
    }
    
    func add(participants: [VIConversationParticipant], to conversation: VIConversation, completion: @escaping VIConversationEventCompletion) {
        
    }
    
    func edit(participants: [VIConversationParticipant], in conversation: VIConversation, completion: @escaping VIConversationEventCompletion) {
        
    }
    
    func remove(participants: [VIConversationParticipant], from conversation: VIConversation, completion: @escaping VIConversationEventCompletion) {
        
    }
    
    func leaveConversation(with UUID: String, completion: @escaping VIConversationEventCompletion) {
        
    }
    
    func sendMessage(with text: String, in conversation: VIConversation, completion: @escaping VIMessageEventCompletion) {
        
    }
    
    func edit(message: VIMessage, with text: String, completion: @escaping VIMessageEventCompletion) {
        
    }
    
    func remove(message: VIMessage, completion: @escaping VIMessageEventCompletion) {
        
    }
    
    func requestMessengerEvents(for conversation: VIConversation, completion: @escaping VIEventArrayCompletion) {
        
    }
    
    func markAsRead(sequence: Int64, in conversation: VIConversation) {
        
    }
    
    func sendTyping(in conversation: VIConversation) {
        
    }
}
