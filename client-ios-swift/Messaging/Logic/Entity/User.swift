/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

struct User: Identifiable, Hashable {
    let imID: Int64
    let me: Bool
    var username: String
    var displayName: String
    var pictureName: String?
    var status: String?
    
    // Identifiable
    var id: Int64 { imID }
}
