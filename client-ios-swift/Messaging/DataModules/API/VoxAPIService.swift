/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import Foundation

protocol APIService {
    func getVoxUsernames(completion: @escaping (Result<[String], Error>) -> Void)
}

class VoxAPIService: APIService {
    #error ("Enter backend adress")
    private let requestLink = ""
    private var requestURL: URL { return URL(string: requestLink)! }
    
    private func getUsersRequest(completion: @escaping (Result<Data, Error>) -> Void)  {
        let request = URLSession.shared.dataTask(with: requestURL) { (data, response, error) in
            print("gerUsersRequest: response \(String(describing: response))")
            if let error = error { completion(.failure(error)) }
            data != nil ? completion(.success(data!)) : completion(.failure(VoxDemoError.errorNoDataReceived()))
        }
        request.resume()
    }
    
    func getVoxUsernames(completion: @escaping (Result<[String], Error>) -> Void) {
        getUsersRequest { result in
            if case let .success(data) = result
            {
                if let parsedData = JSONParser.parse(data: data) { completion(.success(parsedData)) }
                else { completion(.failure(VoxDemoError.errorDataParsingFailed())) }
            }
            else if case let .failure(error) = result { completion(.failure(error)) }
        }
    }
}

fileprivate class JSONParser {
    static let resultKey = "result"
    static let countKey = "count"
    static let usernameKey = "user_name"
    
    class func parse(data: Data)  -> [String]? {
        do {
            guard let json = try JSONSerialization.jsonObject (with: data, options: .mutableContainers) as? [String : Any],
                  let result = json[resultKey] as? [[String : Any]],
                  let userCount = json[countKey] as? Int else { return nil }
            
            var voxUsernameArray: [String] = []
            for user in 0...(userCount - 1)
            {
                let userInfo = result[user]
                guard let username = userInfo[usernameKey] as? String else { return nil }
                voxUsernameArray.append(username)
            }
            return voxUsernameArray
        }
        catch { return nil }
    }
}


