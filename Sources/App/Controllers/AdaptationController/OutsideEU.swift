//
//  OutsideEU.swift
//
//
//  Created by Filippo Lobisch on 13.02.23.
//

import Foundation


class OutsideEU {
    
    private(set) var task: Task<Void, any Error>?
    
    final func executeAdaptation() async throws -> Bool {
        return true
    }
}
