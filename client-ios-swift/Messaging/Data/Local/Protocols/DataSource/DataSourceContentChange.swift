/*
*  Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
*/

import Foundation

enum DataSourceContentChange<Content> {
    case update (content: Content, at: IndexPath)
    case insert (content: Content, at: IndexPath)
    case delete (from: IndexPath)
    case move (from: IndexPath, to: IndexPath)
}
