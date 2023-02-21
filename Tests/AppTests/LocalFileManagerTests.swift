//
//  LocalFileManagerTests.swift
//
//
//  Created by Filippo Lobisch on 02.02.23.
//

import Foundation
import XCTest
@testable import App

/// The test class that handles all the test cases for the `LocalFileManager` object.
final class LocalFileManagerTests: XCTestCase {
    let localManager = LocalFileManager()
    
    /// Override of an XCTestCase method to setup and create a file needed for the tests.
    override func setUpWithError() throws {
        continueAfterFailure = false
        let testFileData = Data("This is some test data".utf8)
        try localManager.save(data: testFileData, toResource: "test-file")
    }
    
    /// Test the ending of the project directory url ends in 'thesis-server'.
    func testProjectDirectoryAccuracy() throws {
        let projectURL = localManager.projectDirectoryURL
        
        let expectation = "thesis-server"
        let lastPathComponent = try XCTUnwrap(projectURL.pathComponents.last, "The last component of the project url is nil.")
        
        XCTAssertEqual(lastPathComponent, expectation, "The last component of the project URL (\(lastPathComponent)) does not equal the expected last component '\(expectation)'")
    }
    
    /// Test the computed url from a file name and extension equals the path of this file.
    func testUrlAccuracy() throws {
        let filePath = #filePath // We use this file as a reference as we don't need to manually type the address and this is dynamic.
        let fileID = try XCTUnwrap(#fileID.components(separatedBy: "/").last, "The fileID is nil.")
        let filename = try XCTUnwrap(fileID.components(separatedBy: ".").first, "The filename of the fileID is nil.")
        let fileExtension = try XCTUnwrap(fileID.components(separatedBy: ".").last, "The extension of the fileID is nil.")
        
        let urlPath = try localManager.url(forResource: filename, withExtension: fileExtension).path
        XCTAssertEqual(urlPath, filePath, "The retrieved file path \(urlPath) does not equal the expected file path '\(filePath)'")
    }
    
    /// Test the retrieval of all the file names in the data files directory.
    func testListFiles() throws {
        let expectation = 1 // We use one here because of the created file in the setup method above.
        XCTAssertNoThrow(try localManager.listAllFilesInDataFilesDirectory(), "Getting the names of the file in the data_files directory expected to not throw an error, however, an error was thrown.")
        let files = try localManager.listAllFilesInDataFilesDirectory()
        XCTAssertEqual(files.count, expectation, "The file names retrieved from the local manager expected to be of size \(expectation), however, the result was \(files.count) instead of \(expectation).")
    }
    
    /// Test the retrieval of the contents of an existing file using the name and extension.
    func testGetContentsOfExistingFile() throws {
        let fileID = try XCTUnwrap(#fileID.components(separatedBy: "/").last, "The fileID is nil.")
        let filename = try XCTUnwrap(fileID.components(separatedBy: ".").first, "The filename of the fileID is nil.")
        let fileExtension = try XCTUnwrap(fileID.components(separatedBy: ".").last, "The extension of the fileID is nil.")
        
        XCTAssertNoThrow(try localManager.get(contentsOf: filename, withExtension: fileExtension), "Getting the contents of the file expected to not throw an error, however, an error was thrown.")
    }
    
    /// Test the retrieval of the contents of an existing file using the name.
    func testGetContentsOfExistingFileUsingName() throws {
        let fileID = try XCTUnwrap(#fileID.components(separatedBy: "/").last, "The fileID is nil.")
        let filename = try XCTUnwrap(fileID.components(separatedBy: ".").first, "The filename of the fileID is nil.")
        
        XCTAssertNoThrow(try localManager.get(contentsOf: filename, withExtension: nil), "Getting the contents of the file expected to not throw an error, however, an error was thrown.")
    }
    
    /// Test the retrieval of the contents of a non existing file throws an error.
    func testGetContentsOfNonExistingFile() throws {
        XCTAssertThrowsError(try localManager.get(contentsOf: "file-that-does-not-exist", withExtension: nil), "Getting the contents of the file expected to throw an error, however, an no error was thrown.")
    }
    
    /// Test the save of content to the hard disk.
    func testSaveFile() throws {
        let filename = "save-file-test-name"
        let fileData = Data("This is the test data from the testSaveFile test case.".utf8)
        XCTAssertNoThrow(try localManager.save(data: fileData, toResource: filename), "Saving the file expected to not throw an error, however, an error was thrown.")
        
        addTeardownBlock { [weak self] in
            guard let self else { return }
            try self.localManager.delete(resource: filename)
        }
    }
    
    /// Test the update of the content of the file with a given name.
    func testUpdateFile() throws {
        let filename = "test-file"
        let newContent = Data("This is some new content to be added to the test file that has already been saved.".utf8)
        XCTAssertNoThrow(try localManager.update(data: newContent, ofResource: filename), "Updating the file expected to not throw an error, however, an error was thrown.")
        
        let fileContentsAfterAssert = try localManager.get(contentsOf: filename)
        XCTAssertEqual(newContent, fileContentsAfterAssert, "The retrieved content for the saved file after the updated was expected to be equal to the newContent, however, the contents differ.")
    }
    
    /// Test the deletion of an existing file does not throw an error.
    func testDeleteExistingFile() throws {
        let filename = "delete-test-file"
        let testFileData = Data("This is some test data".utf8)
        try localManager.save(data: testFileData, toResource: filename)
        
        XCTAssertNoThrow(try localManager.delete(resource: filename), "Deleting the file expected to not throw an error, however, an error was thrown.")
        XCTAssertThrowsError(try localManager.get(contentsOf: filename), "Deleting the file expected to throw an error, however, an no error was thrown.")
    }
    
    /// Test the deletion of an non existing file and ensure it throws an error.
    func testDeleteNonExistingFile() throws {
        XCTAssertThrowsError(try localManager.delete(resource: "file-that-does-not-exist", withExtension: nil), "Deleting the file expected to throw an error, however, an no error was thrown.")
    }
    
    /// Override of XCTestCase method to remove any generated file.
    override func tearDownWithError() throws {
        continueAfterFailure = false
        try localManager.delete(resource: "test-file")
    }
}
