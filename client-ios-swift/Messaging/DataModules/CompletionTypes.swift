/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import Foundation
import VoxImplant

typealias VIUserCompletion                 = (Result<VIUser, Error>)              -> Void
typealias UserCompletion                   = (Result<User, Error>)                -> Void
typealias VIUserArrayCompletion            = (Result<[VIUser], Error>)            -> Void
typealias UserArrayCompletion              = (Result<[User], Error>)              -> Void
typealias VIConversationCompletion         = (Result<VIConversation, Error>)      -> Void
typealias ConversationCompletion           = (Result<Conversation, Error>)        -> Void
typealias VIConversationArrayCompletion    = (Result<[VIConversation], Error>)    -> Void
typealias ConversationArrayCompletion      = (Result<[Conversation], Error>)      -> Void
typealias VIEventCompletion                = (Result<VIMessengerEvent, Error>)    -> Void
typealias VIEventArrayCompletion           = (Result<[VIMessengerEvent], Error>)  -> Void
typealias EventArrayCompletion             = (Result<[MessengerEvent], Error>)    -> Void
typealias VIConversationEventCompletion    = (Result<VIConversationEvent, Error>) -> Void
typealias VIMessageEventCompletion         = (Result<VIMessageEvent, Error>)      -> Void
typealias MessageEventCompletion           = (Result<MessageEvent, Error>)        -> Void
typealias EmptyCompletion                  = (Result<(), Error>)                  -> Void
