//
//  File.swift
//  
//
//  Created by Filippo Lobisch on 21.05.23.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import Vapor

struct ComponentAController: Component {
    
    let endpoint = "http://0.0.0.0:3000"
    
    func stress() async throws -> Bool {
        let fullEndpoint = endpoint + "/stress"
        guard let url = URL(string: fullEndpoint) else {
            throw NetworkError.invalidURL
        }
        
        let request = URLRequest(url: url)
        return try await NetworkManager.shared.fetchData(request: request, type: Bool.self)
    }
    
}
