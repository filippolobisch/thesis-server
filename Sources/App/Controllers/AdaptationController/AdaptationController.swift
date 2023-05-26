//
//  AdaptationController.swift
//
//
//  Created by Filippo Lobisch on 12.12.22.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import Vapor

/// The main adaptation controller.
class AdaptationController {

    /// The shared instance of the `AdaptationController` class. Uses the singleton design pattern, such that the controller isn't recreated each time.
    static let shared = AdaptationController()

    /// The outsideEU object to perform calls to the adaptation.
    /// This is needed to ensure that every time the adaptation is called the properties that need to updated don't reset.
    var outsideEU = OutsideEU()
    
    /// The sensitiveData object to perform calls to the adaptation.
    /// This is needed to ensure that every time the adaptation is called the properties that need to updated don't reset.
    var sensitiveData = SensitiveData()
    
    /// The main function of this adaptation controller.
    /// Once the data is converted we perform type-casting operations to get the information in a more appropriate format for our server.
    /// Then we retrieve each adaptation that needs to be execute and call the appropriate method based on it.
    /// We return true is no error if thrown and everything proceeds successfully.
    final func main(data: String) async -> Bool {
        let adaptation = AdaptationType(data)
        
        switch adaptation {
        case .outsideEU:
            return await execute(adaptation: &outsideEU)
        case .sensitiveData:
            return await execute(adaptation: &sensitiveData)
        }
    }
    
    private func execute(adaptation: inout some Adaptation) async -> Bool {
        do {
            return try await adaptation.executeAdaptation()
        } catch {
            await Logger.shared.saveLogs()
            fatalError("An error occurred inside the \(adaptation) method. \(error.localizedDescription)")
        }
    }
}
