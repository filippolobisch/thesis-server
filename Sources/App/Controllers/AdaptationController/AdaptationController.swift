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
    
    /// The shared instance of the `AdaptationController` class. Uses the singleton design pattern.
    static let shared = AdaptationController()
    
    /// The JSON decoder object that is used to convert the data into a dictionary from the received string.
    private let decoder = JSONDecoder()
    
    /// The IP of the RADAR software.
    private let radarIP = "http://127.0.0.1:7770"
    
    /// The outsideEU object to perform calls to the adaptation.
    /// This is needed to ensure that every time the adaptation is called the properties that need to updated don't reset.
    let outsideEU = OutsideEU()
    
    /// The sensitiveData object to perform calls to the adaptation.
    /// This is needed to ensure that every time the adaptation is called the properties that need to updated don't reset.
    let sensitiveData = SensitiveData()
    
    
    /// Method to register this application on RADAR as a managed context system.
    /// We use a URLRequest to send a post request to RADAR.
    /// We use `withCheckedThrowingContinuation` to get the result outside of the Data Task completion handler.
    /// We also use this instead of a newer async await URLRequest method to be compatible with Ubuntu.
    /// Then we decode the response received into type Integer and return it. This is used in the routes section to determine whether the response was correct or not.
    final func registerThisAppOnRadar(app: Application) async throws -> Int {
        let appHostname = app.http.server.configuration.hostname
        let appPort = app.http.server.configuration.port
        let radarEndpoint = "\(radarIP)/registerManagedSystem"
        let monitoringURLString = "http://\(appHostname):\(appPort)/execute"
        let executionURLString = "http://\(appHostname):\(appPort)/execute"
        
        let modelData = try LocalFileManager().get(contentsOf: "model", withExtension: "json")
        
        let model = String(data: modelData, encoding: .utf8)
        let httpBodyString = "\(model!)&\(monitoringURLString)&\(executionURLString)"
        
        guard let radarURL = URL(string: radarEndpoint) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: radarURL)
        request.httpMethod = "POST"
        request.httpBody = Data(httpBodyString.utf8)
        
        // Here we use `withCheckedThrowingContinuation` to get the result outside of the Data Task completion handler.
        // We also use this instead of a newer async await URLRequest method to be compatible with Ubuntu.
        let data: Data = try await withCheckedThrowingContinuation { continuation in
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                guard error == nil else {
                    continuation.resume(throwing: NetworkError.unableToCompleteRequest)
                    return
                }
                
                guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
                    continuation.resume(throwing: NetworkError.invalidResponseFromServer)
                    return
                }
                
                guard let data = data else {
                    continuation.resume(throwing: NetworkError.invalidDataFromServer)
                    return
                }
                
                continuation.resume(returning: data)
            }
            
            task.resume()
        }
        
        let result = try decoder.decode(Int.self, from: data)
        return result
    }
    
    /// The main function of this adaptation controller.
    /// Once the data is converted we perform type-casting operations to get the information in a more appropriate format for our server.
    /// Then we retrieve each adaptation that needs to be execute and call the appropriate method based on it.
    /// We return true is no error if thrown and everything proceeds successfully.
    final func root(data dataString: String) -> Bool {
        let data = convert(data: dataString)
        guard let model = data["model"] as? String, let adaptations = data["adaptations"] as? [Int] else { return false }
        let adaptationsCount = Dictionary(adaptations.map { ($0, 1) }, uniquingKeysWith: +) // Create dictionary from the adaptation keys, and removes duplicates.
        let adaptationKeys = adaptationsCount.keys
        
        for key in adaptationKeys {
            let numberOfTimesToExecute = adaptationsCount[key] ?? 1
            switch key {
            case 1: // EU
                Task {
                    do {
                        _ = try await outsideEU.executeAdaptation(model: model, numberOfTimesToExecute: numberOfTimesToExecute)
                    } catch {
                        fatalError("An error occurred inside the outsideEU main adaptation method.")
                    }
                }
            case 2: // SensitiveData
                Task {
                    do {
                        _ = try await sensitiveData.executeAdaptation(model: model, numberOfTimesToExecute: numberOfTimesToExecute)
                    } catch {
                        fatalError("An error occurred inside the sensitiveData main adaptation method.")
                    }
                }
            default:
                fatalError("The returned adaptationKeys does not contain an adaptation key.")
            }
        }
        
        return true
    }
    
    /// Method to convert the data from a string to a dictionary object (JSON format).
    /// First we convert the string to a data object. We then use JSONSerialization to convert it into a JSON object before casting it to a dictionary.
    private func convert(data dataString: String) -> [String: Any] {
        let data = Data(dataString.utf8)
        
        do {
            let result = try JSONSerialization.jsonObject(with: data)
            return result as? [String: Any] ?? [:] // If the casting to [String: Any] fails/returns nil, we return an empty dictionary.
        } catch {
            fatalError(error.localizedDescription)
        }
    }
}

/// Enum object used to provide more descriptive Network errors that might occur when performing the register on radar network call.
enum NetworkError: String, Error {
    case invalidURL = "The URL provided is invalid."
    case unableToCompleteRequest = "Unable to complete your request. Please check your internet connection."
    case invalidResponseFromServer = "Invalid response from the server. The response given from URLSession is not equal to statusCode 200 (OK)."
    case invalidDataFromServer = "The data received from the server was invalid."
}
