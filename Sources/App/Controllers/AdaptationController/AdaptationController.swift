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
    let outsideEU = OutsideEU()
    
    /// The sensitiveData object to perform calls to the adaptation.
    /// This is needed to ensure that every time the adaptation is called the properties that need to updated don't reset.
    let sensitiveData = SensitiveData()
    
    /// Do not allow more than once instance of this class and restrict to singleton use.
    private init() {}

    /// The main function of this adaptation controller.
    /// Once the data is converted we perform type-casting operations to get the information in a more appropriate format for our server.
    /// Then we retrieve each adaptation that needs to be execute and call the appropriate method based on it.
    /// We return true is no error if thrown and everything proceeds successfully.
    final func root(data: String) -> Bool {
        guard let key = Int(data) else { return false }
        
        switch key {
        case 1: // EU
            Task {
                do {
                    _ = try await outsideEU.executeAdaptation()
                } catch {
                    await Logger.shared.saveLogs()
                    fatalError("An error occurred inside the outsideEU main adaptation method. \(error.localizedDescription)")
                }
            }
        case 2: // SensitiveData
            Task {
                do {
                    _ = try await sensitiveData.executeAdaptation()
                } catch {
                    await Logger.shared.saveLogs()
                    fatalError("An error occurred inside the sensitiveData main adaptation method. \(error.localizedDescription)")
                }
            }
        default:
            fatalError("The returned key does not contain an appropriate adaptation key.")
        }

        return true
    }
}
