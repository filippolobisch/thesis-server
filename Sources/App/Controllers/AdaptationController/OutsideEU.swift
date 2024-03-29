//
//  OutsideEU.swift
//
//
//  Created by Filippo Lobisch on 13.02.23.
//

import Foundation


struct OutsideEU: Adaptation {
    private(set) var useComponentB = true
    private(set) var componentB = ComponentBController()
    
    mutating func executeAdaptation() async throws -> Bool {
        guard useComponentB else { return false }
        let result = try await componentB.adapt(for: .componentA)
        guard result else { return false }

        useComponentB = false
        return true
    }
    
    func stress() async {
        async let stressA = ComponentAController().stress()
        async let stressB = componentB.stress()
        do {
            _ = try await (stressA, stressB)
        } catch {
            print(error.localizedDescription)
        }
    }
}
