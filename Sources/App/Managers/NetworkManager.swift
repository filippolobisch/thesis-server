//
//  NetworkManager.swift
//  
//
//  Created by Filippo Lobisch on 17.05.23.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

struct NetworkManager {
    
    static let shared = NetworkManager()
    
    
    func send(data: Data, to endpoint: String) async throws -> Bool {
        guard let url = URL(string: endpoint) else {
            throw NetworkError.invalidURL
        }
                
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = data
        
        let result = try await fetchData(request: request, type: Bool.self)
        return result
    }
    
    func fetchData(request: URLRequest) async throws -> Data {
        // Here we use `withCheckedThrowingContinuation` to get the result outside of the Data Task completion handler.
        // We also use this instead of a newer async await URLRequest method to be compatible with Ubuntu.
        return try await withCheckedThrowingContinuation { continuation in
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                guard error == nil else {
                    continuation.resume(throwing: NetworkError.unableToCompleteRequest)
                    return
                }

                guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
                    continuation.resume(throwing: NetworkError.invalidResponseFromServer)
                    return
                }

                guard let data else {
                    continuation.resume(throwing: NetworkError.invalidDataFromServer)
                    return
                }

                continuation.resume(returning: data)
            }

            task.resume()
        }
    }
    
    /// Convenience method to easily convert the returned data from the GET HTTP request into a specified type format `T`.
    /// Works if the generic type `T`is not of type `Data` or `String`.
    /// - Parameters:
    ///   - request: The `URLRequest` to perform.
    ///   - type: The type to decode the response into. (Do not use `Data` or `String`).
    func fetchData<T: Decodable>(request: URLRequest, type: T.Type) async throws -> T {
        let data = try await fetchData(request: request)
        
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw NetworkError.failedToDecodeData
        }
    }
}
