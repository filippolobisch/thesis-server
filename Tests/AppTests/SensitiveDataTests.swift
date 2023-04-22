//
//  SensitiveDataTests.swift
//
//
//  Created by Filippo Lobisch on 22.02.23.
//

import Foundation
import XCTest
@testable import App

/// The test class that handles all the test cases for the `SensitiveData` object.
final class SensitiveDataTests: XCTestCase {

    /// The main sensitive property that is used in all the tests.
    /// We create it here so that it does not get recreated for each test.
    private let sensitiveData = SensitiveData()

    /// Tests the creation of a `Task` object that continuously runs.
    /// We check to ensure that the `task` property is not nil after its creation inside the `getFilesConstantly` method.
    func testTaskCreation() async throws {
        try await sensitiveData.getFilesConstantly()
        XCTAssertNotNil(sensitiveData.task, "Expected the task to not be nil, however, the task was nil.")
        
        addTeardownBlock {
            self.sensitiveData.cancelTask()
        }
    }
    
    /// Tests the cancellation of a `Task` object that continuously runs.
    /// We check to ensure that the `task` property is nil after its cancellation inside the `cancelTask` method, signifying the task was successfully cancelled.
    func testTaskCancellation() async throws {
        try await sensitiveData.getFilesConstantly()
        sensitiveData.cancelTask()
        
        XCTAssertNil(sensitiveData.task, "Expected the task to be nil signifying it was cancelled, however, the task is not nil meaning it is still active.")
    }

    #if os(macOS)
    /// Tests the executeAdaptation method of the SensitiveData class.
    /// We ensure that there is a change in the `usesCloud` property (from true to false).
    /// We also ensure that the correct changes to the system are performed (removing content from European bucket to local content), to verify that the adaptation executes as we expect.
    /// Lastly we reset the changes that were made to the system. Since we are dealing with a single file we upload that file to the AWS bucket.
    func testExecuteAdaptation() async throws {
        XCTAssertTrue(sensitiveData.usesCloud, "Expected 'usesCloud' property to be true when starting the execution, however, the property is false.")

        _ = try await sensitiveData.executeAdaptation(model: "")
        XCTAssertFalse(sensitiveData.usesCloud, "Expected 'usesCloud' property to be false after executing the adaptation, however, the property is true.")

        let files = try await sensitiveData.europeAWSManager.getAllFilesInBucket()
        XCTAssertTrue(files.isEmpty, "Expected files in European bucket to be empty, however, files still exist.")

        addTeardownBlock {
            self.sensitiveData.cancelTask()
            _ = try await self.sensitiveData.europeAWSManager.upload(resource: "Latex Cache", withExtension: "md")
        }
    }
    #endif
}
