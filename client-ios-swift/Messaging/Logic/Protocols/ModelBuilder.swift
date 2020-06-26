/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import VoxImplantSDK

protocol ModelBuilder {
    func buildVIParticipant(from model: Participant) -> VIConversationParticipant
    func buildVIParticipant(with imID: NSNumber, for conversationType: Conversation.ConversationType) -> VIConversationParticipant
    func buildCustomData(for type: Conversation.ConversationType, _ pictureName: String?, and description: String?) -> [String: NSObject]
    func buildConfig(for conversationModel: Conversation) -> VIConversationConfig
}

extension ModelBuilder {
    func buildConfig(for conversationModel: Conversation) -> VIConversationConfig {
        let config = VIConversationConfig()
        config.title = conversationModel.title
        config.isDirect = conversationModel.type == .direct
        config.isUber = conversationModel.isUber
        config.isPublicJoin = conversationModel.isPublic
        config.participants = conversationModel.participants.map { VIConversationParticipant(imUserId: NSNumber(value: $0.user.imID)) }
        config.customData = buildCustomData(for: conversationModel.type, conversationModel.pictureName, and: conversationModel.description)
        return config
    }
    
    func buildCustomData(for type: Conversation.ConversationType, _ pictureName: String?, and description: String?) -> [String: NSObject] {
        var customData: CustomData = [:]
        customData.type = type
        customData.permissions = Permissions.defaultPermissions(for: type).nsDictionary
        if let pictureName = pictureName { customData.image = pictureName }
        if let description = description { customData.chatDescription = description }
        return customData
    }
    
    func buildVIParticipant(from model: Participant) -> VIConversationParticipant {
        let participant = VIConversationParticipant(imUserId: NSNumber(value: model.user.imID))
        participant.isOwner = model.isOwner
        participant.canWrite = model.permissions.canWrite
        participant.canRemoveMessages = model.permissions.canRemoveMessages
        participant.canRemoveAllMessages = model.permissions.canRemoveAllMessages
        participant.canEditMessages = model.permissions.canEditMessages
        participant.canEditAllMessages = model.permissions.canEditAllMessages
        participant.canManageParticipants = model.permissions.canManageParticipants
        return participant
    }
    
    func buildVIParticipant(with imID: NSNumber, for conversationType: Conversation.ConversationType) -> VIConversationParticipant {
        let participant = VIConversationParticipant(imUserId: imID)
        let permissions = Permissions.defaultPermissions(for: conversationType)
        participant.isOwner = false
        participant.canManageParticipants = permissions.canManageParticipants
        participant.canWrite = permissions.canWrite
        participant.canEditMessages = permissions.canEditMessages
        participant.canEditAllMessages = permissions.canEditAllMessages
        participant.canRemoveMessages = permissions.canRemoveMessages
        participant.canRemoveAllMessages = permissions.canRemoveAllMessages
        return participant
    }
}
