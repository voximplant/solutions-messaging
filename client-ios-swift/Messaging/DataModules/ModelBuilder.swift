/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import Foundation
import VoxImplantSDK

protocol ModelBuilderProtocol {
    func buildUser(from viUser: VIUser) -> User
    
    func buildConversation(from viConversation: VIConversation, and viUsers: [VIUser]) -> Conversation
    func buildConversation(from viConversation: VIConversation, and users: [User]) -> Conversation
    
    func buildParticipant(from viParticipant: VIConversationParticipant, and viUser: VIUser) -> Participant
    func buildParticipant(from viParticipant: VIConversationParticipant, and user: User) -> Participant
    func buildVIParticipant(from model: Participant) -> VIConversationParticipant
    func buildVIParticipant(with imID: NSNumber, for conversationType: ConversationType) -> VIConversationParticipant
    
    func buildMessageEvent(with viEvent: VIMessageEvent, and initiator: VIUser) -> MessageEvent
    func buildMessageEvent(with viEvent: VIMessageEvent, and initiator: User) -> MessageEvent
    func buildMessageModel(with viMessage: VIMessage) -> Message
    
    func buildConversationEvent(with viEvent: VIConversationEvent, _ viUsers: [VIUser], and initiator: VIUser) -> ConversationEvent
    func buildConversationEvent(with viEvent: VIConversationEvent, _ users: [User], and initiator: User) -> ConversationEvent
    
    func buildServiceEvent(with viEvent: VIConversationServiceEvent, and initiator: VIUser) -> ServiceEvent
    func buildUserEvent(with viEvent: VIUserEvent) -> UserEvent
    
    func buildCustomData(for type: ConversationType, _ pictureName: String?, and description: String?) -> [String: NSObject]
    
    func buildConfig(for conversationModel: Conversation) -> VIConversationConfig
}

final class ModelBuilder: ModelBuilderProtocol {
    // MARK: - User -
    func buildUser(from viUser: VIUser) -> User {
        let pictureName: String? = viUser.customData.image as String?
        let status: String? = viUser.customData.status as String?
        return User(imID: viUser.imId, username: viUser.name, displayName: viUser.displayName, pictureName: pictureName, status: status)
    }
    
    // MARK: - Conversation
    func buildConversation(from viConversation: VIConversation, and userArray: [VIUser]) -> Conversation {
        var participantModelArray: [Participant] = []
        for (index, participant) in viConversation.participants.enumerated() {
            participantModelArray.append(buildParticipant(from: participant, and: userArray[index]))
        }
        let pictureName: String? = viConversation.customData.image as String?
        let description: String? = viConversation.customData.chatDescription as String?
        let type = ConversationType(customDataValue: viConversation.customData.type)
        let permissions = viConversation.customData.permissions as? Permissions
        
        var lastReadSequence = 1
        viConversation.participants.forEach { participant in
            if participant.imUserId != sharedRepository.me!.imID && participant.lastReadEventSequence > lastReadSequence {
                lastReadSequence = Int(participant.lastReadEventSequence)
            }
        }
        
        return Conversation(uuid: viConversation.uuid, type: type, title: viConversation.title, participants: participantModelArray,
                            pictureName: pictureName, description: description, permissions: permissions,
                            lastUpdated: viConversation.lastUpdateTime, lastSequence: Int(viConversation.lastSequence),
                            isDirect: viConversation.isDirect, isPublic: viConversation.isPublicJoin, isUber: viConversation.isUber,
                            latestReadSequence: lastReadSequence)
    }
    
    func buildConversation(from viConversation: VIConversation, and users: [User]) -> Conversation {
        var participantModelArray: [Participant] = []
        viConversation.participants.forEach { participant in
            users.forEach { user in
                if user.imID == participant.imUserId {
                    participantModelArray.append(buildParticipant(from: participant, and: user))
                }
            }
        }
        let pictureName: String? = viConversation.customData.image as String?
        let description: String? = viConversation.customData.chatDescription as String?
        let type = ConversationType(customDataValue: viConversation.customData.type)
        let permissions = viConversation.customData.permissions as? Permissions
        
        var lastReadSequence = 1
        viConversation.participants.forEach { participant in
            if participant.imUserId != sharedRepository.me!.imID && participant.lastReadEventSequence > lastReadSequence {
                lastReadSequence = Int(participant.lastReadEventSequence)
            }
        }
        
        return Conversation(uuid: viConversation.uuid, type: type, title: viConversation.title, participants: participantModelArray,
                            pictureName: pictureName, description: description, permissions: permissions,
                            lastUpdated: viConversation.lastUpdateTime, lastSequence: Int(viConversation.lastSequence),
                            isDirect: viConversation.isDirect, isPublic: viConversation.isPublicJoin, isUber: viConversation.isUber,
                            latestReadSequence: lastReadSequence)
    }
    
    func buildConfig(for conversationModel: Conversation) -> VIConversationConfig {
        let config = VIConversationConfig()
        config.title = conversationModel.title
        config.isDirect = conversationModel.isDirect
        config.isUber = conversationModel.isUber
        config.isPublicJoin = conversationModel.isPublic
        config.participants = conversationModel.participants.map { VIConversationParticipant(imUserId: $0.user.imID) }
        config.customData = buildCustomData(for: conversationModel.type, conversationModel.pictureName, and: conversationModel.description)
        return config
    }
    
    func buildCustomData(for type: ConversationType, _ pictureName: String?, and description: String?) -> [String: NSObject] {
        var customData: CustomData = [:]
        customData.type = type.customDataValue
        customData.permissions = type.defaultPermissions.nsDictionary
        if let pictureName = pictureName { customData.image = pictureName as NSString }
        if let description = description { customData.chatDescription = description as NSString }
        return customData
    }
    
    func buildMessageModel(with viMessage: VIMessage) -> Message {
        return Message(uuid: viMessage.uuid, text: viMessage.text,
                       conversation: viMessage.conversation, sequence: Int(viMessage.sequence))
    }
    
    // MARK: - Participants -
    func buildParticipant(from viParticipant: VIConversationParticipant, and viUser: VIUser) -> Participant {
        return Participant(isOwner: viParticipant.isOwner, user: buildUser(from: viUser),
                                permissions: buildPermissions(for: viParticipant),
                                lastReadEventSequence: Int(viParticipant.lastReadEventSequence))
    }
    
    func buildParticipant(from viParticipant: VIConversationParticipant, and user: User) -> Participant {
        return Participant(isOwner: viParticipant.isOwner, user: user,
                                permissions: buildPermissions(for: viParticipant),
                                lastReadEventSequence: Int(viParticipant.lastReadEventSequence))
    }
    
    func buildVIParticipant(from model: Participant) -> VIConversationParticipant {
        let participant = VIConversationParticipant(imUserId: model.user.imID)
        participant.isOwner = model.isOwner
        participant.canWrite = model.permissions.canWrite
        participant.canRemoveMessages = model.permissions.canRemoveMessages
        participant.canRemoveAllMessages = model.permissions.canRemoveAllMessages
        participant.canEditMessages = model.permissions.canEditMessages
        participant.canEditAllMessages = model.permissions.canEditAllMessages
        participant.canManageParticipants = model.permissions.canManageParticipants
        return participant
    }
    
    func buildVIParticipant(with imID: NSNumber, for conversationType: ConversationType) -> VIConversationParticipant {
        let participant = VIConversationParticipant(imUserId: imID)
        participant.isOwner = false
        participant.canManageParticipants = conversationType.defaultPermissions.canManageParticipants
        participant.canWrite = conversationType.defaultPermissions.canWrite
        participant.canEditMessages = conversationType.defaultPermissions.canEditMessages
        participant.canEditAllMessages = conversationType.defaultPermissions.canEditAllMessages
        participant.canRemoveMessages = conversationType.defaultPermissions.canRemoveMessages
        participant.canRemoveAllMessages = conversationType.defaultPermissions.canRemoveAllMessages
        return participant
    }
    
    func buildPermissions(for viParticipant: VIConversationParticipant) -> Permissions {
        var permissions: Permissions = [:]
        permissions.canWrite = viParticipant.canWrite
        permissions.canEditMessages = viParticipant.canEditMessages
        permissions.canEditAllMessages = viParticipant.canEditAllMessages
        permissions.canRemoveMessages = viParticipant.canRemoveMessages
        permissions.canRemoveAllMessages = viParticipant.canRemoveAllMessages
        permissions.canManageParticipants = viParticipant.canManageParticipants
        return permissions
    }
    
    // MARK: - Events -
    func buildMessageEvent(with viEvent: VIMessageEvent, and initiator: VIUser) -> MessageEvent {
        return MessageEvent(initiator: buildUser(from: initiator), action: translateMessageAction(from: viEvent.action),
                            message: buildMessageModel(with: viEvent.message),
                            sequence: Int(viEvent.sequence), timestamp: viEvent.timestamp)
    }
    
    func buildMessageEvent(with viEvent: VIMessageEvent, and initiator: User) -> MessageEvent {
        return MessageEvent(initiator: initiator, action: translateMessageAction(from: viEvent.action),
                               message: buildMessageModel(with: viEvent.message),
                               sequence: Int(viEvent.sequence), timestamp: viEvent.timestamp)
    }
    
    func buildConversationEvent(with viEvent: VIConversationEvent, _ users: [VIUser], and initiator: VIUser) -> ConversationEvent {
        return ConversationEvent(initiator: buildUser(from: initiator), action: translateConversationAction(from: viEvent.action),
                                    conversation: buildConversation(from: viEvent.conversation, and: users),
                                    sequence: Int(viEvent.sequence), timestamp: viEvent.timestamp)
    }
    
    func buildConversationEvent(with viEvent: VIConversationEvent, _ users: [User], and initiator: User) -> ConversationEvent {
        return ConversationEvent(initiator: initiator, action: translateConversationAction(from: viEvent.action),
                                    conversation: buildConversation(from: viEvent.conversation, and: users),
                                    sequence: Int(viEvent.sequence), timestamp: viEvent.timestamp)
    }
    
    func buildServiceEvent(with viEvent: VIConversationServiceEvent, and initiator: VIUser) -> ServiceEvent {
        return ServiceEvent(initiator: buildUser(from: initiator), action: translateServiceAction(from: viEvent.action),
                               conversationUUID: viEvent.conversationUUID, sequence: Int(viEvent.sequence))
    }
    
    func buildUserEvent(with viEvent: VIUserEvent) -> UserEvent {
        return UserEvent(initator: buildUser(from: viEvent.user), action: translateUserAction(from: viEvent.action))
    }
        
    private func translateMessageAction(from viAction: VIMessengerAction) -> MessageEventAction {
        switch viAction {
        case .sendMessage   : return .send
        case .editMessage   : return .edit
        case .removeMessage : return .remove
        default             : fatalError()
        }
    }
    
    private func translateConversationAction(from viAction: VIMessengerAction) -> ConversationEventAction {
        switch viAction {
        case .addParticipants    : return .addParticipants
        case .editParticipants   : return .editParticipants
        case .removeParticipants : return .removeParticipants
        case .editConversation   : return .editConversation
        case .joinConversation   : return .joinConversation
        case .leaveConversation  : return .leaveConversation
        case .createConversation : return .createConversation
        case .removeConversation : return .removeConversation
        default                  : fatalError()
        }
    }
    
    private func translateServiceAction(from viAction: VIMessengerAction) -> ServiceEventAction {
        switch viAction {
        case .isRead : return .read
        case .typing : return .typing
        default      : fatalError()
        }
    }
    
    private func translateUserAction(from viAction: VIMessengerAction) -> UserEventAction {
        switch viAction {
        case .editUser : return .editUser
        default        : fatalError()
        }
    }
}
