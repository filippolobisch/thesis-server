//
//  LocalFileManagerTests.swift
//
//
//  Created by Filippo Lobisch on 02.02.23.
//

import Foundation
import XCTest
@testable import App

/// The test class that handles all the test cases for the `LocalManager` object.
final class LocalManagerTests: XCTestCase {
    let localManager = LocalManager()
    
    /// Override of an XCTestCase method to setup and create a file needed for the tests.
    override func setUp() async throws {
        continueAfterFailure = false
        let testFileData = Data("This is some test data".utf8)
        try await localManager.save(data: testFileData, toResource: "test-file", withExtension: "txt")
    }

    /// Test the ending of the project directory url ends in 'thesis-server'.
    func testBundleURLAccuracy() async throws {
        let expectation = "thesis-server_App"
        let bundle = await localManager.bundle.bundleURL
        let lastPathComponent = bundle.deletingPathExtension().lastPathComponent
        XCTAssertEqual(lastPathComponent, expectation, "Expected the lastPathComponent to be equal to \(expectation), however, the result was \(lastPathComponent).")
    }

    /// Test the retrieval of all the file names in the data files directory.
    func testListFiles() async throws {
        let expectation = 2
        let files = try await localManager.listFilesInResourcesDirectory()
        XCTAssertEqual(files.count, expectation, "The file names retrieved from the local manager expected to be of size \(expectation), however, the result was \(files.count).")
    }

    /// Test the retrieval of the contents of an existing file using the name and extension.
    func testGetContentsOfFile() async throws {
        let expectation = Data("This is some test data".utf8)
        let fileData = try await localManager.get(contentsOf: "test-file", withExtension: "txt")
        XCTAssertEqual(fileData, expectation, "The file data expected to be equal to the expectation string result, however, they are different.")
    }

    /// Test the retrieval of the contents of a non existing file throws an error.
    func testGetContentsOfNonExistingFile() async throws {
        do {
            _ = try await localManager.get(contentsOf: "non-existing-file", withExtension: "txt")
            XCTFail("Getting the contents of the file expected to throw an error, however, an no error was thrown.")
        } catch {
            XCTestExpectation(description: "The retrieval of the contents of a file that doesn't exist successfully throws an error").fulfill()
        }
    }

    /// Test the save of content to the hard disk.
    func testSaveFile() async throws {
        let filename = "save-file-test-name"
        let fileData = Data("This is the test data from the testSaveFile test case.".utf8)
        try await localManager.save(data: fileData, toResource: filename, withExtension: "txt")

        addTeardownBlock { [weak self] in
            guard let self else { return }
            try await self.localManager.delete(resource: filename, withExtension: "txt")
        }
    }

    /// Test the update of the content of the file with a given name.
    func testUpdateFile() async throws {
        let filename = "test-file"
        let newContent = Data("This is some new content to be added to the test file that has already been saved.".utf8)
        try await localManager.save(data: newContent, toResource: filename, withExtension: "txt")
        
        let fileContentsAfterUpdate = try await localManager.get(contentsOf: filename, withExtension: "txt")
        XCTAssertEqual(newContent, fileContentsAfterUpdate, "The retrieved content for the saved file after the updated was expected to be equal to the newContent, however, the contents differ.")
    }

    /// Test the deletion of an existing file does not throw an error.
    func testDeleteExistingFile() async throws {
        let filename = "delete-test-file"
        let testFileData = Data("This is some test data".utf8)
        try await localManager.save(data: testFileData, toResource: filename, withExtension: "txt")
        
        try await localManager.delete(resource: filename, withExtension: "txt")
        let files = try await localManager.listFilesInResourcesDirectory()
        XCTAssertTrue(!files.contains { $0 == (filename, "") }, "The deleted test file was not expected to be in the list of files under the Resources directory, however, the file still exists.")
    }

    /// Test the deletion of an non existing file and ensure it throws an error.
    func testDeleteNonExistingFile() async throws {
        do {
            _ = try await localManager.delete(resource: "file-that-does-not-exist", withExtension: "txt")
            XCTFail("Deleting the file expected to throw an error, however, an no error was thrown.")
        } catch {
            XCTestExpectation(description: "The deletion of a file that doesn't exist successfully throws an error").fulfill()
        }
    }

    /// Override of XCTestCase method to remove any generated file.
    override func tearDown() async throws {
        continueAfterFailure = false
        try await localManager.delete(resource: "test-file", withExtension: "txt")
    }
}
