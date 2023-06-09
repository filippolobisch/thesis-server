//
//  SensitiveData.swift
//
//
//  Created by Filippo Lobisch on 13.02.23.
//

import Foundation


struct SensitiveData: Adaptation {
    private(set) var useComponentB = true
    private(set) var componentB = ComponentBController()
    
    private let mainController = MainController()
    
    mutating func executeAdaptation() async throws -> Bool {
        guard useComponentB else { return false }
        let result = try await componentB.adapt(for: .thesisServer)
        guard result else { return false }

        useComponentB = false
        return true
    }
    
    func stress() async {
        async let stressB = componentB.stress()
        async let stressLocal = mainController.stress()
        
        do {
            _ = try await (stressLocal, stressB)
        } catch {
            print(error.localizedDescription)
        }
    }
}
