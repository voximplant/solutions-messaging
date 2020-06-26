/*
*  Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
*/

import VoxImplantSDK

typealias EventDataBase = EventDataBaseInput & EventDataBaseOutput

protocol EventDataBaseInput {
    func processEvent(_ viEvent: VIMessengerEvent, completion: @escaping (Error?) -> Void)
    func process(viEvents: [VIMessengerEvent], completion: @escaping (Error?) -> Void)
    func updateEventsReadMark(conversation: String, sequence lastReadSequence: Int64,
                             completion: @escaping (Error?) -> Void)
}

protocol EventDataBaseOutput {
    var eventDataSource: EventDataSource { get }
}
