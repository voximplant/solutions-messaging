/*
*  Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
*/

import VoxImplantSDK

typealias ConversationDataBase = ConversationDataBaseInput & ConversationDataBaseOutput

protocol ConversationDataBaseInput {
    func saveConversation(_ viConversation: VIConversation, completion: @escaping (Error?) -> Void)
    func updateConversationLastSequence(_ id: ConversationObject.ID, lastUpdateTime: TimeInterval,
                                        lastSequence: Int64, completion: @escaping (Error?) -> Void)
    func updateConversationParticipants(_ viConversation: VIConversation,
                                        completion: @escaping (Error?) -> Void)
    func updateConversation(_ viConversation: VIConversation,
                            completion: @escaping (Error?) -> Void)
    func removeConversation(_ id: ConversationObject.ID, completion: @escaping (Error?) -> Void)
}

protocol ConversationDataBaseOutput {
    var conversationDataSource: ConversationDataSource { get }
}
