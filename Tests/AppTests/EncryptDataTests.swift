//
//  EncryptDataTests.swift
//  
//
//  Created by Filippo Lobisch on 04.07.23.
//

import Foundation
import XCTest
@testable import App

/// The test class that handles all the test cases for the `EncryptData` adaptation object.
final class EncryptDataTests: XCTestCase {
    let localManager = LocalManager()
    let encryptedData = EncryptData()
    
    private let testFilename = "test-file-encryptDataTests"
    let fileData = Data("This is some file data to encrypt.".utf8)
    
    override func setUp() async throws {
        continueAfterFailure = false
        try await localManager.save(data: fileData, toResource: testFilename, withExtension: "txt")
    }
    
    func testEncryptionOfData() async throws {
        let encryptionResult = try await encryptedData.encrypt(file: testFilename, ext: "txt")
        XCTAssertTrue(encryptionResult, "Expected the result of the encryption to be true, however, it is false.")
    }
    
    func testDecryptionOfData() async throws {
        _ = try await encryptedData.encrypt(file: testFilename, ext: "txt")
        let decryptedData = try await encryptedData.decrypt(file: "encrypted_\(testFilename)", ext: "txt")
        XCTAssertEqual(fileData, decryptedData, "Expected the returned data from the decryption to be equal to the fileData, however, they are different.")
    }
    
    func testDecryptionOfNonEncryptedData() async throws {
        _ = try await encryptedData.encrypt(file: testFilename, ext: "txt")
        do {
            _ = try await encryptedData.decrypt(file: "test", ext: "txt")
            XCTFail("Decrypting a file that is not encrypted expected to throw an error, however, an no error was thrown.")
        } catch {
            XCTestExpectation(description: "The decryption of a non encrypted file successfully throws an error").fulfill()
        }
    }
    
    override func tearDown() async throws {
        continueAfterFailure = false
        try await localManager.delete(resource: testFilename, withExtension: "txt")
        try await localManager.delete(resource: "encrypted_\(testFilename)", withExtension: "txt")
    }
}
