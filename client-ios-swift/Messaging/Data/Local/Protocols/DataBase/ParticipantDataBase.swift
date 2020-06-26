/*
*  Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
*/

typealias ParticipantDataBase = ParticipantDataBaseInput

protocol ParticipantDataBaseInput {
    func getParticipant(id: ParticipantObject.ID) -> Participant?
    func updateLastReadSequence(participantID: ParticipantObject.ID, sequence: Int64,
                                   completion: @escaping (Error?) -> Void)
}
