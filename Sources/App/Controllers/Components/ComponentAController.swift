//
//  File.swift
//  
//
//  Created by Filippo Lobisch on 21.05.23.
//

import Foundation

struct ComponentAController: Component {
    let endpoint = ComponentHelper.componentA.endpoint
    
    func stress() async throws -> Bool {
        let fullEndpoint = endpoint + "/stress"
        _ = try await NetworkManager.shared.curl(endpoint: fullEndpoint)
        return true
    }
}
