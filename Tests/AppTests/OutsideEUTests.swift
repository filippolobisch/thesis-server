//
//  OutsideEUTests.swift
//
//
//  Created by Filippo Lobisch on 22.02.23.
//

import Foundation
import XCTest
@testable import App

/// The test class that handles all the test cases for the `OutsideEU` object.
final class OutsideEUTests: XCTestCase {
    
    /// The main outsideEU property that is used in all the tests.
    /// We create it here so that it does not get recreated for each test.
    private let outsideEU = OutsideEU()
    
    /// Tests the creation of a `Task` object that continuously runs.
    /// We check to ensure that the `task` property is not nil after its creation inside the `getFilesConstantly` method.
    func testTaskCreation() {
        outsideEU.getFilesConstantly()
        XCTAssertNotNil(outsideEU.task, "Expected the task to not be nil, however, the task was nil.")
        
        addTeardownBlock {
            self.outsideEU.cancelTask()
        }
    }
    
    /// Tests the cancellation of a `Task` object that continuously runs.
    /// We check to ensure that the `task` property is nil after its cancellation inside the `cancelTask` method, signifying the task was successfully cancelled.
    func testTaskCancellation() async throws {
        outsideEU.getFilesConstantly()
        outsideEU.cancelTask()
        
        XCTAssertNil(outsideEU.task, "Expected the task to be nil signifying it was cancelled, however, the task is not nil meaning it is still active.")
    }
    
    
    #if os(macOS)
    /// Tests the executeAdaptation method of the OutsideEU class when an odd number value is passed for the parameter numberOfTimesToExecute.
    /// We ensure that there is a change in the `storeDataOnlyInEU` property (from false to true).
    /// We also ensure that the correct changes to the system are performed (removing content from North American bucket), to verify that the adaptation executes as we expect.
    /// Lastly we reset the changes that were made to the system. Since we are dealing with a single file we upload that file to the AWS bucket.
    func testOddNumberOfTimesToExecuteAdaptation() async throws {
        XCTAssertFalse(outsideEU.storeDataOnlyInEU, "Expected 'storeDataOnlyInEU' property to be false when starting the execution, however, the property is true.")
        
        _ = try await outsideEU.executeAdaptation(model: "", numberOfTimesToExecute: 1)
        XCTAssertTrue(outsideEU.storeDataOnlyInEU, "Expected 'storeDataOnlyInEU' property to be true after executing the adaptation, however, the property is false.")
        
        let files = try await outsideEU.northAmericaAWSManager.getAllFilesInBucket()
        XCTAssertTrue(files.isEmpty, "Expected files in North American bucket to be empty, however, files still exist.")

        addTeardownBlock {
            self.outsideEU.cancelTask()
            _ = try await self.outsideEU.northAmericaAWSManager.upload(resource: "Latex Cache", withExtension: "md")
        }
    }
    
    /// Tests the executeAdaptation method of the OutsideEU class when an even number value is passed for the parameter numberOfTimesToExecute.
    /// We ensure that there is no change in the `storeDataOnlyInEU` property (stays false).
    /// We also ensure that there are no changes to the system are performed ie content remains where it was previous to this adaptation call, to verify that the adaptation executes as we expect.
    func testEvenNumberOfTimesToExecuteAdaptation() async throws {
        XCTAssertFalse(outsideEU.storeDataOnlyInEU, "Expected 'storeDataOnlyInEU' property to be false when starting the execution, however, the property is true.")
        
        let result = try await outsideEU.executeAdaptation(model: "", numberOfTimesToExecute: 2)
        XCTAssertFalse(outsideEU.storeDataOnlyInEU, "Expected 'storeDataOnlyInEU' property to be false after executing the adaptation, however, the property is true.")
        
        let expectation = "Completed"
        XCTAssertEqual(result, expectation, "Expected the returned string from the executeAdaptation to be equal to the expectation string, however, files do not exist.")
        
        addTeardownBlock {
            self.outsideEU.cancelTask()
        }
    }
    #endif
}
