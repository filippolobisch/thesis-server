//
//  EncryptData.swift
//  
//
//  Created by Filippo Lobisch on 04.07.23.
//

import Foundation
import Crypto

struct EncryptData: Adaptation {
    private let localManager = LocalManager()
    private let mainController = MainController()
    
    private(set) var filesEncrypted = false
    private let key = SymmetricKey(size: .bits256)
    
    mutating func executeAdaptation() async throws -> Bool {
        guard !filesEncrypted else { return false }
        let result = try await encryptAllFiles()
        guard result else { return false }
        filesEncrypted = true
        return true
    }
    
    func stress() async {
        do {
            if filesEncrypted {
                _ = try await stressEncrypted()
            } else {
                _ = try await mainController.stress()
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    private func stressEncrypted() async throws -> Bool {
        let files = try await localManager.listFilesInResourcesDirectory()
        let encryptedFiles = files.filter { $0.0.starts(with: "encrypted_") }
        
        try await withThrowingTaskGroup(of: Void.self) { group in
            for (name, ext) in encryptedFiles {
                group.addTask {
                    _ = try await decrypt(file: name, ext: ext)
                }
            }
            
            try await group.waitForAll()
        }
        
        return true
    }
    
    func encryptAllFiles() async throws -> Bool {
        let files = try await localManager.listFilesInResourcesDirectory()
        let result = try await withThrowingTaskGroup(of: Bool.self) { group in
            for (name, ext) in files {
                group.addTask {
                    return try await encrypt(file: name, ext: ext)
                }
            }
            
            var results: [Bool] = []
            for try await result in group {
                results.append(result)
            }
            
            let successfullyEncryptedFiles = results.filter { $0 }
            return successfullyEncryptedFiles.count == files.count
        }
        
        return result
    }
}

// MARK: - Encryption and Decryption methods.
extension EncryptData {
    func encrypt(file name: String, ext: String?) async throws -> Bool {
        let fileData = try await localManager.get(contentsOf: name, withExtension: ext)
        let sealedBox = try AES.GCM.seal(fileData, using: key)
        guard let combined = sealedBox.combined else {
            fatalError("Could not encrypt data.")
        }
        
        let encryptedFileName = "encrypted_\(name)"
        try await localManager.save(data: combined, toResource: encryptedFileName, withExtension: ext)
        return true
    }
    
    func decrypt(file name: String, ext: String?) async throws -> Data {
        guard name.starts(with: "encrypted_") else {
            throw "The name of the file to decrypt must start with 'encrypted_'."
        }
        
        let encryptedData = try await localManager.get(contentsOf: name, withExtension: ext)
        let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
        let decryptedData = try AES.GCM.open(sealedBox, using: key)
        return decryptedData
    }
}
