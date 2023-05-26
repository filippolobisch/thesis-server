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
    let endpoint = ComponentHelper.componentA.endpoint
    
    func stress() async throws -> Bool {
        let fullEndpoint = endpoint + "/stress"
        return try await NetworkManager.shared.curl(endpoint: fullEndpoint)
    }
}
