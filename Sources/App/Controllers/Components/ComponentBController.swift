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

struct ComponentBController: Component {
    
    let endpoint = ComponentHelper.componentB.endpoint
    var isOnline = true
    
    mutating func adapt(for component: ComponentHelper) async throws -> Bool {
        guard isOnline else { return false }
        
        let fullEndpoint = endpoint + "/adapt"
        let adaptationIndex = component.rawValue
        let data = Data("\(adaptationIndex)".utf8)
        
        let result = try await NetworkManager.shared.send(data: data, to: fullEndpoint)
        guard result else { return false }
        
        let didShutdown = try await shutdown()
        guard didShutdown else { return false }
        
        isOnline = false
        return true
    }
    
    func stress() async throws -> Bool {
        let fullEndpoint = endpoint + "/stress"
        return try await NetworkManager.shared.curl(endpoint: fullEndpoint)
    }
    
    func shutdown() async throws -> Bool {
        let fullEndpoint = endpoint + "/shutdown"
        return try await NetworkManager.shared.curl(endpoint: fullEndpoint)
    }
}
