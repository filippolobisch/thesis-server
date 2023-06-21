//
//  RadarController.swift
//
//
//  Created by Filippo Lobisch on 17.05.23.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import Vapor


struct RadarController {
    
    /// The IP of the RADAR software.
    private let endpoint = "http://127.0.0.1:7770"
    
    
    /// Method to register this application on RADAR as a managed context system.
    /// We use a URLRequest to send a post request to RADAR.
    /// Then we decode the response received into type Integer and return it. This is used in the routes section to determine whether the response was correct or not.
    func registerThisAppOnRadar(app: Application) async throws -> Int {
        let appHostname = app.http.server.configuration.hostname
        let appPort = app.http.server.configuration.port
        let radarEndpoint = endpoint + "/registerManagedSystem"
        let monitoringURLString = "http://\(appHostname):\(appPort)/execute"
        let executionURLString = "http://\(appHostname):\(appPort)/execute"

        let modelData = try await LocalManager().get(contentsOf: "model", withExtension: "json")
        let model = String(data: modelData, encoding: .utf8)
        let httpBodyString = "\(model!)&\(monitoringURLString)&\(executionURLString)"

        guard let radarURL = URL(string: radarEndpoint) else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: radarURL)
        request.httpMethod = "POST"
        request.httpBody = Data(httpBodyString.utf8)
        
        return try await NetworkManager.shared.fetchData(request: request, type: Int.self)
    }
}
