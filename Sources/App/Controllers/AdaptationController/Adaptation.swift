//
//  Adaptation.swift
//  
//
//  Created by Filippo Lobisch on 23.05.23.
//

import Foundation

enum AdaptationType: Int {
    case outsideEU = 1
    case sensitiveData = 2
    
    init(_ string: String) {
        guard let key = Int(string), let adaptation = AdaptationType(rawValue: key) else {
            fatalError("The returned key does not contain an appropriate adaptation key.")
        }
        
        self = adaptation
    }
}


protocol Adaptation {
    var useComponentB: Bool { get }
    var componentB: ComponentBController { get }
    
    mutating func executeAdaptation() async throws -> Bool
    func stress() async
}
