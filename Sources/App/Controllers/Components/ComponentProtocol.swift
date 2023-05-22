//
//  ComponentProtocol.swift
//  
//
//  Created by Filippo Lobisch on 21.05.23.
//

import Foundation

protocol Component {
    var endpoint: String { get }
    
    func stress() async throws -> Bool
}
