/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import Foundation

final class BackendService: Backend {
    var requestURL: URL? { URL(string: BackendConfig.requestLink) }
    
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
        guard let url = requestURL else {
            completion(.failure(VoxDemoError.wrongUUID))
            return
        }
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            print("gerUsersRequest: response \(String(describing: response))")
            if let error = error {
                completion(.failure(error))
                return
            }
            if let data = data {
                completion(.success(data))
            } else {
                completion(.failure(VoxDemoError.noDataReceived))
            }
        }.resume()
    }
    
    // MARK: - Decodable
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
