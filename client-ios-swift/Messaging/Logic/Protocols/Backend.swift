/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import Foundation

protocol Backend {
    func getVoxUsernames(completion: @escaping (Result<[String], Error>) -> Void)
}
