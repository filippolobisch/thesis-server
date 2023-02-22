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
    
    /// Tests the creation of a `Task` object that continuously runs that retrieves senstiveData on the cloud.
    /// We check to ensure that the `getFilesConstantlyFromCloudTask` property is not nil after its creation inside the `getFilesConstantlyFromCloud` method.
    func testCloudTaskCreation() {
        let sensitiveData = SensitiveData()
        sensitiveData.getFilesConstantlyFromCloud()
        
        XCTAssertNotNil(sensitiveData.getFilesConstantlyFromCloudTask, "Expected the task to not be nil, however, the task was nil.")
    }
    
    /// Tests the cancellation of the `Task` object that continuously runs.
    /// We check to ensure that the `getFilesConstantlyFromCloudTask` property is nil after its cancellation inside the `cancelCurrentlyRunningTask` method, signifying the task was successfully cancelled.
    func testCloudTaskCancellation() async throws {
        let sensitiveData = SensitiveData()
        sensitiveData.getFilesConstantlyFromCloud()
        sensitiveData.cancelCurrentlyRunningTask()
        
        XCTAssertNil(sensitiveData.getFilesConstantlyFromCloudTask, "Expected the task to be nil signifying it was cancelled, however, the task is not nil meaning it is still active.")
    }
    
    /// Tests the creation of a `Task` object that continuously runs that retrieves senstiveData on the local component.
    /// We check to ensure that the `getFilesConstantlyFromLocalTask` property is not nil after its creation inside the `getFilesConstantlyFromLocal` method.
    func testLocalTaskCreation() {
        let sensitiveData = SensitiveData()
        sensitiveData.getFilesConstantlyFromLocal()
        
        XCTAssertNotNil(sensitiveData.getFilesConstantlyFromLocalTask, "Expected the task to not be nil, however, the task was nil.")
    }
    
    /// Tests the cancellation of the `Task` object that continuously runs.
    /// We check to ensure that the `getFilesConstantlyFromLocalTask` property is nil after its cancellation inside the `cancelCurrentlyRunningTask` method, signifying the task was successfully cancelled.
    func testLocalTaskCancellation() async throws {
        let sensitiveData = SensitiveData()
        sensitiveData.getFilesConstantlyFromLocal()
        sensitiveData.cancelCurrentlyRunningTask()
        
        XCTAssertNil(sensitiveData.getFilesConstantlyFromLocalTask, "Expected the task to be nil signifying it was cancelled, however, the task is not nil meaning it is still active.")
    }
    
    /// Tests the executeAdaptation method of the SensitiveData class when an odd number value is passed for the parameter numberOfTimesToExecute.
    /// We ensure that there is a change in the `usesCloud` property (from true to false).
    /// We also ensure that the correct changes to the system are performed (removing content from European bucket to local content), to verify that the adaptation executes as we expect.
    /// Lastly we reset the changes that were made to the system. Since we are dealing with a single file we upload that file to the AWS bucket.
    func testOddNumberOfTimesToExecuteAdaptation() async throws {
        let sensitiveData = SensitiveData()
        XCTAssertTrue(sensitiveData.usesCloud, "Expected 'usesCloud' property to be true when starting the execution, however, the property is false.")

        _ = try await sensitiveData.executeAdaptation(model: "", numberOfTimesToExecute: 1)
        sensitiveData.cancelCurrentlyRunningTask() // We cancel the task as we do not require it to be running constantly for this test.

        XCTAssertFalse(sensitiveData.usesCloud, "Expected 'usesCloud' property to be false after executing the adaptation, however, the property is true.")

        let files = try await sensitiveData.europeAWSManager.getAllFilesInBucket()
        XCTAssertTrue(files.isEmpty, "Expected files in European bucket to be empty, however, files still exist.")

        addTeardownBlock {
            _ = try await sensitiveData.europeAWSManager.upload(resource: "Latex Cache", withExtension: "md")
        }
    }
    
    /// Tests the executeAdaptation method of the SensitiveData class when an even number value is passed for the parameter numberOfTimesToExecute.
    /// We ensure that there is no change in the `usesCloud` property (stays true).
    /// We also ensure that there are no changes to the system are performed ie content remains where it was previous to this adaptation call, to verify that the adaptation executes as we expect.
    func testEvenNumberOfTimesToExecuteAdaptation() async throws {
        let sensitiveData = SensitiveData()
        XCTAssertTrue(sensitiveData.usesCloud, "Expected 'usesCloud' property to be true when starting the execution, however, the property is false.")

        _ = try await sensitiveData.executeAdaptation(model: "", numberOfTimesToExecute: 2)
        sensitiveData.cancelCurrentlyRunningTask() // We cancel the task as we do not require it to be running constantly for this test.

        XCTAssertTrue(sensitiveData.usesCloud, "Expected 'usesCloud' property to be true after executing the adaptation, however, the property is false.")

        let files = try await sensitiveData.europeAWSManager.getAllFilesInBucket()
        XCTAssertTrue(!files.isEmpty, "Expected files in European bucket to exist, however, files do not exist.")
    }
}
