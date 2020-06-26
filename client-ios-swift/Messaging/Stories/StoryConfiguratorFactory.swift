/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import Foundation

final class StoryConfiguratorFactory {
    static var authService: AuthService! // DI
    static var repository: Repository! // DI
    static var dataRefresher: DataRefresher! // DI
    static var userDataSource: UserDataSource! // DI
    static var conversationDataSource: ConversationDataSource! // DI
    static var eventDataSource: EventDataSource! // DI
    static var dataBaseCleaner: Cleanable! // DI
    
    static var loginConfigurator: LoginConfiguratorProtocol {
        LoginConfigurator(authService: authService, dataRefresher: dataRefresher)
    }
    
    static var conversationsConfigurator: ConversationsConfiguratorProtocol {
        ConversationsConfigurator(conversationDataSource: conversationDataSource)
    }
    
    static var conversationInfoConfigurator: ConversationInfoConfiguratorProtocol {
        ConversationInfoConfigurator(
            repository: repository,
            authService: authService,
            conversationDataSource: conversationDataSource
        )
    }
    
    static var settingsConfigurator: SettingsConfiguratorProtocol {
        SettingsConfigurator(
            repository: repository,
            authService: authService,
            userDataSource: userDataSource,
            dataBaseCleaner: dataBaseCleaner
        )
    }
    
    static var activeConversationConfigurator: ActiveConversationConfiguratorProtocol {
        ActiveConversationConfigurator(
            repository: repository,
            conversationDataSource: conversationDataSource,
            userDataSource: userDataSource,
            eventDataSource: eventDataSource
        )
    }
    
    static var createDirectConfigurator: CreateDirectConfiguratorProtocol {
        CreateDirectConfigurator(repository: repository, userDataSource: userDataSource)
    }
    
    static var createChatConfigurator: CreateChatConfiguratorProtocol {
        CreateChatConfigurator(repository: repository, userDataSource: userDataSource)
    }
    
    static var participantsConfigurator: ParticipantsConfiguratorProtocol {
        ParticipantsConfigurator(
            repository: repository,
            conversationDataSource: conversationDataSource
        )
    }
    
    static var addParticipantsConfigurator: AddParticipantsConfiguratorProtocol {
        AddParticipantsConfigurator(
            repository: repository,
            authService: authService,
            conversationDataSource: conversationDataSource,
            userDataSource: userDataSource
        )
    }
    
    static var permissionsConfigurator: PermissionsConfiguratorProtocol {
        PermissionsConfigurator(
            repository: repository,
            conversationDataSource: conversationDataSource
        )
    }
}
