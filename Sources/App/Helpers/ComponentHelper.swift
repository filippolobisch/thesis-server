//
//  Component.swift
//  
//
//  Created by Filippo Lobisch on 19.05.23.
//

import Foundation

enum ComponentHelper: Int {
    case componentA = 1
    case thesisServer = 2
    case componentB = 3
    
    var endpoint: String {
        switch self {
        case .componentA: return "http://127.0.0.1:3000"
        case .thesisServer: return "http://127.0.0.1:8080"
        case .componentB: return "http://127.0.0.1:3030"
        }
    }
}
