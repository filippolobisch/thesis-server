//
//  File.swift
//  
//
//  Created by Filippo Lobisch on 23.05.23.
//

import Foundation

struct MainController {
    
    let localManager = LocalManager()
    
    
    func stress(data: String) async {
        let adaptation = AdaptationType(data)
        
        async let stressB = ComponentBController().stress()
        
        switch adaptation {
        case .outsideEU:
            async let stressA = ComponentAController().stress()
            do {
                _ = try await (stressA, stressB)
            } catch {
                print(error.localizedDescription)
            }
        case .sensitiveData:
            async let stressLocal = localStress()
            do {
                _ = try await (stressLocal, stressB)
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    func receive(data: Data) async throws -> Bool {
        guard let decodedData = convert(data: data) else { return false }
        guard let fileData = decodedData["fileData"] as? Data, let name = decodedData["name"] as? String, let ext = decodedData["ext"] as? String else {
            return false
        }
        
        try await localManager.save(data: fileData, toResource: name, withExtension: ext)
        return true
    }
    
    private func convert(data: Data) -> [String: Any]? {
        do {
            let result = try JSONSerialization.jsonObject(with: data)
            return result as? [String: Any]
        } catch {
            fatalError(error.localizedDescription)
        }
    }
    
    
    private func localStress() async throws -> Bool {
        let files = try await localManager.listFilesInResourcesDirectory()
        try await withThrowingTaskGroup(of: Void.self) { group in
            for (name, ext) in files {
                group.addTask {
                    _ = try await localManager.get(contentsOf: name, withExtension: ext)
                }
            }
            
            try await group.waitForAll()
        }
        
        return true
    }
    
}
