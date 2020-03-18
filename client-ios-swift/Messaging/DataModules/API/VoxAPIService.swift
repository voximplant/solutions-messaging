/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import Foundation

protocol APIService {
    func getVoxUsernames(completion: @escaping (Result<[String], Error>) -> Void)
}

final class VoxAPIService: APIService {
    #error ("Enter backend adress")
    private let requestLink = ""
    private var requestURL: URL { URL(string: requestLink)! }
    
    func getVoxUsernames(completion: @escaping (Result<[String], Error>) -> Void) {
        getUsersRequest { result in
            if case let .success(data) = result
            {
                do {
                    let usernames: [String] = try JSONDecoder()
                        .decode(UsersJSONAdapter.self, from: data)
                        .result
                        .map { $0.userName }
                    completion(.success(usernames))
                } catch (let error) {
                    completion(.failure(error))
                }
            }
            else if case let .failure(error) = result { completion(.failure(error)) }
        }
    }
    
    // MARK: - Private -
    private func getUsersRequest(completion: @escaping (Result<Data, Error>) -> Void)  {
        URLSession.shared.dataTask(with: requestURL) { (data, response, error) in
            print("gerUsersRequest: response \(String(describing: response))")
            if let error = error {
                completion(.failure(error))
                return
            }
            if let data = data {
                completion(.success(data))
            } else {
                completion(.failure(VoxDemoError.errorNoDataReceived()))
            }
        }.resume()
    }
    
    private struct UsersJSONAdapter: Decodable {
        let result: [UserJSON]
    }
    
    private struct UserJSON: Decodable {
        let userName: String
        enum CodingKeys: String, CodingKey {
            case userName = "user_name"
        }
    }
}
