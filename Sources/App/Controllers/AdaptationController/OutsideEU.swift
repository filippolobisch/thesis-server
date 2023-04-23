//
//  OutsideEU.swift
//
//
//  Created by Filippo Lobisch on 13.02.23.
//

import Foundation

/// Class that handles the OutsideEU adaptation.
class OutsideEU {
    
    /// Property that determines whether the data is stored solely in the European region.
    private(set) var storeDataOnlyInEU = false {
        willSet {
            cancelTask()
        }
    }
    
    /// The task object that is used as a recurring task to generate system load.
    private(set) var task: Task<Void, any Error>?
    
    /// The European AWS manager.
    let europeAWSManager = AWSS3Manager.europeManager
    
    /// The North American AWS manager.
    let northAmericaAWSManager = AWSS3Manager.northAmericaManager
    
    
    /// Handles the execution of this adaptation between solely EU component and both regions.
    /// Toggles the property that determines where data is stored, every time the adaptation is executed.
    /// It then handles the appropriate adaptation case for the new `storeDataOnlyInEU` value.
    /// Once the adaptation is performed it calls the `getFilesConstantly` method to create a constant workload.
    /// Returns the "completed" string if no error is thrown and the adaptation was successfully executed.
    /// - Parameters:
    ///   - model: The model of the system. (Unused).
    final func executeAdaptation(model: String) async throws -> String {
        Logger.shared.add(message: "Started adapting the system for the OutsideEU adaptation.")
        storeDataOnlyInEU.toggle()
        
        var systemDidAdapt = false
        if storeDataOnlyInEU {
            systemDidAdapt = try await storeData(from: northAmericaAWSManager, to: europeAWSManager)
        } else {
            systemDidAdapt = try await storeData(from: europeAWSManager, to: northAmericaAWSManager)
        }
        
        guard systemDidAdapt else {
            throw "OutsideEU adaptation was not performed."
        }
        
        Logger.shared.add(message: "Finished adapting the system for the OutsideEU adaptation.")
        try await getFilesConstantly()
        return "Completed"
    }
    
    /// Method that gets files constantly.
    /// If `storeDataOnlyInEU` is true we use the European AWS manager solely, otherwise we use the North American AWS manager solely.
    /// Furthermore, we download all files in the chosen bucket, concurrently.
    final func getFilesConstantly() async throws {
        Logger.shared.add(message: "Starting the OutsideEU getFilesConstantly task with storeDataOnlyInEU as \(storeDataOnlyInEU).")
        let selectedManager = storeDataOnlyInEU ? europeAWSManager : northAmericaAWSManager
        let files = try await selectedManager.getAllFilesInBucket()
        
        task = Task<Void, any Error> {
            try await withThrowingTaskGroup(of: Void.self) { group in
                if Task.isCancelled {
                    group.cancelAll()
                }

                while !Task.isCancelled {
                    for file in files {
                        _ = group.addTaskUnlessCancelled {
                            _ = try await selectedManager.download(fileKey: file)
                        }
                    }

                    try await group.waitForAll()
                }
            }
        }
        
        Logger.shared.add(message: "Started the OutsideEU getFilesConstantly task with storeDataOnlyInEU as \(storeDataOnlyInEU).")
    }
    
    /// Method to cancel the current running task of getting files constantly.
    /// We first cancel the task and then once it's cancelled we set the task object to nil.
    final func cancelTask() {
        Logger.shared.add(message: "Cancelling the OutsideEU getFilesConstantly task for storeDataOnlyInEU as \(storeDataOnlyInEU).")
        task?.cancel()
        task = nil
        Logger.shared.add(message: "Cancelled the OutsideEU getFilesConstantly task for storeDataOnlyInEU as \(storeDataOnlyInEU).")
    }
    
    /// Method that moves the data stored in an origin bucket to a provided destination bucket.
    /// First the files in the origin bucket are retrieved, with their data being downloaded soon after.
    /// Followed by this it is uploaded to the destination S3 bucket.
    /// Returns `true` if no error is thrown.    
    private func storeData(from originBucket: AWSS3Manager, to destinationBucket: AWSS3Manager) async throws -> Bool {
        Logger.shared.add(message: "Storing data from the \(originBucket.regionName) region only in the \(destinationBucket.regionName).")
        let files = try await originBucket.getAllFilesInBucket()
        
        let result = try await withThrowingTaskGroup(of: Bool.self) { group in
            for file in files {
                group.addTask {
                    let fileData = try await originBucket.download(fileKey: file)
                    let didUploadFile = try await destinationBucket.upload(data: fileData, using: file)
                    guard didUploadFile else { throw "File was not uploaded to S3 bucket \(destinationBucket)." }
                    
                    let didDeleteFile = try await originBucket.delete(fileKey: file)
                    guard didDeleteFile else { throw "File was not deleted from S3 bucket \(originBucket)." }
                    return true
                }
            }
            
            var results: [Bool] = []
            for try await result in group {
                results.append(result)
            }
            
            Logger.shared.add(message: "Results array == \(results). Bucket files == \(files)")
            return results.filter { $0 == true }.count == files.count
        }
        
        guard result else { throw "Not all files were moved to the destination bucket \(destinationBucket)." }
        Logger.shared.add(message: "Stored data from the \(originBucket.regionName) region only in the \(destinationBucket.regionName).")
        return true
    }
}
