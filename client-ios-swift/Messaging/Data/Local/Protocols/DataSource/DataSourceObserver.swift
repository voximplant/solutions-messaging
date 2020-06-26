/*
*  Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
*/

import Foundation

struct DataSourceObserver<Content>: Identifiable {
    let id: UUID = UUID()
    let contentWillChange: (() -> Void)?
    let contentDidChange: (() -> Void)?
    let didReceiveChange: (DataSourceContentChange<Content>) -> Void
}
