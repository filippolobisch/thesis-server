//
//  AWSManagerTests.swift
//  
//
//  Created by Filippo Lobisch on 10.02.23.
//

import Foundation
import XCTest
@testable import App

/// The test class that handles all the test cases for the `AWSManager` object.
final class AWSManagerTests: XCTestCase {
    
    /// The main awsManager property that is used in all the tests.
    /// We create it here so that it does not get recreated for each test.
    private let awsManager = AWSS3Manager(bucketName: "eu-data-bucket", region: .euCentral1)
    
    /// Test the retrieval of all objects in an AWS Bucket.
    func testListObjectsEU() async throws {
        let files = try await awsManager.getAllFilesInBucket()
        XCTAssertTrue(files.count >= 0, "The number of retrieved files from the aws bucket was expected to be greater or equal to 0, however, the value was less than 0.")
    }
    
    /// Test the upload of data to the AWS bucket.
    func testUploadToBucket() async throws {
        let filename = "test-upload-data-file-name"
        let fileData = Data("This is the test data from the testUploadData test case in the AWSManagerTests.".utf8)
        let didUploadFile = try await awsManager.upload(data: fileData, using: filename)
        XCTAssertTrue(didUploadFile, "Uploading the file to AWS Bucket expected to be true, however, the file is not included in the bucket files.")
            
        addTeardownBlock {
            _ = try await self.awsManager.delete(fileKey: filename)
        }
    }
    
    /// Test the download of file from the AWS bucket.
    func testDownloadFile() async throws {
        let filename = "Latex Cache.md"
        let expectedContent = Data("# Fix BibTex cache\n\nFirst check it exists with: `biber --cache`\n\nTo clear cache: `rm -rf `biber --cache``\n".utf8)
        
        let downloadedFileData = try await awsManager.download(fileKey: filename)
        XCTAssertEqual(downloadedFileData, expectedContent, "The downloaded content was expected to be equal to the expected content, however, the content was different.")
    }
    
    /// Test the delete of a file in the AWS bucket.
    func testDeleteFile() async throws {
        let filename = "test-delete-file-name"
        let fileData = Data("This is the test data from the testDeleteFile test case in the AWSManagerTests.".utf8)
        _ = try await awsManager.upload(data: fileData, using: filename)
        
        let didDeleteFile = try await awsManager.delete(fileKey: filename)
        XCTAssertTrue(didDeleteFile, "Deleting the file to AWS Bucket expected to be true, however, the file is still included in the bucket files.")
    }
}
