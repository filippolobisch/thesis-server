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
    private(set) var task: Task<Void, Never>?
    
    /// The european AWS manager.
    let europeAWSManager = AWSS3Manager.europeManager
    
    /// The north american AWS manager.
    let northAmericaAWSManager = AWSS3Manager.northAmericaManager
    
    
    /// Handles the execution of this adaptation between solely EU component and both regions.
    /// Toggles the property that determines where data is stored, everytime the adaptation is executed.
    /// It then handles the appropriate adaptation case for the new `storeDataOnlyInEU` value.
    /// Once the adaptation is performed it calls the `getFilesConstantly` method to create a constant workload.
    /// Returns the "completed" string if no error is thrown and the adaptation was successfully executed.
    /// - Parameters:
    ///   - model: The model of the system. (Unused).
    ///   - numberOfTimesToExecute: The number of times to execute this adaptation.
    final func executeAdaptation(model: String, numberOfTimesToExecute: Int) async throws -> String {
        let isOdd = !numberOfTimesToExecute.isMultiple(of: 2)
        
        // We only adapt the system if the number of times to execute is odd. This is because if it is even it is as if nothing had occurred.
        if isOdd {
            storeDataOnlyInEU.toggle()

            let adaptSystemTask = Task<Bool, any Error> {
                if storeDataOnlyInEU {
                    return try await storeDataInEU()
                } else {
                    return try await storeDataOutsideEU()
                }
            }
            
            let didAdapt = try await adaptSystemTask.value
            guard didAdapt else {
                throw "OutsideEU adaptation was not performed."
            }
            
            getFilesConstantly()
        }
        
        return "Completed"
    }
    
    /// Method that gets files constantly.
    /// Runs every two seconds to ensure that it creates a constant workload on the system.
    /// To ensure fair use of both cloud regions, we use the `randomElement` method, if `storeDataOnlyInEU` is true, otherwise we use the European AWS manager solely.
    /// Furthermore, we download a random file from the bucket to ensure that no bias is taken.
    final func getFilesConstantly() {
        task = Task {
            let managers = [europeAWSManager, northAmericaAWSManager]
            let selectedManager = storeDataOnlyInEU ? europeAWSManager : managers.randomElement()!
            
            var files: [String] = []
            do {
                files = try await europeAWSManager.getAllFilesInBucket()
            } catch {
                print(error.localizedDescription)
            }
            
            repeat {
                do {
                    guard let selectedFileKey = files.randomElement() else {
                        throw "Could not retrieve random element from the received file names of the bucket."
                    }
                    
                    _ = try await selectedManager.download(fileKey: selectedFileKey)
                } catch {
                    print(error.localizedDescription)
                }
                
                do {
                    try await Task.sleep(nanoseconds: UInt64(2 * 1_000_000_000))
                } catch {
                    print(error.localizedDescription)
                }
            } while !Task.isCancelled
        }
    }
    
    /// Method to cancel the current running task of getting files constantly.
    /// We first cancel the task and then once it's cancelled we set the task object to nil.
    final func cancelTask() {
        print("Cancelling getFilesConstantly task.")
        task?.cancel()
        task = nil
    }
    
    /// Method that stores the European S3 bucket files also onto the North American S3 bucket.
    /// First the files in the European bucket are retrieved, with their data being downloaded soon after.
    /// Followed by this it is uploaded to the North American S3 bucket.
    /// Returns `true` if no error is thrown.
    private func storeDataOutsideEU() async throws -> Bool {
        let europeanBucketFiles = try await europeAWSManager.getAllFilesInBucket()
        
        for file in europeanBucketFiles {
            let fileData = try await europeAWSManager.download(fileKey: file)
            let fileUploaded = try await northAmericaAWSManager.upload(data: fileData, using: file)
            
            guard fileUploaded else {
                fatalError("Could not upload file to bucket.")
            }
        }
        
        return true
    }
    
    /// Method that stores the North American S3 bucket files onto the European S3 bucket.
    /// First the files in the North American bucket are retrieved, with their data being downloaded soon after.
    /// Followed by this it is uploaded to the European S3 bucket and if the upload is successful, the file is deleted from the North American bucket.
    /// Returns `true` if no error is thrown.
    private func storeDataInEU() async throws -> Bool {
        let northAmericaBucketFiles = try await northAmericaAWSManager.getAllFilesInBucket()
        
        for file in northAmericaBucketFiles {
            let fileData = try await northAmericaAWSManager.download(fileKey: file)
            let fileUploaded = try await europeAWSManager.upload(data: fileData, using: file)
            
            guard fileUploaded else {
                fatalError("Could not upload file to bucket.")
            }
            
            let fileDeleted = try await northAmericaAWSManager.delete(fileKey: file)
            guard fileDeleted else {
                fatalError("Could not delete file from bucket.")
            }
        }
        
        let northAmericaBucketFilesAfterDeletion = try await northAmericaAWSManager.getAllFilesInBucket()
        guard northAmericaBucketFilesAfterDeletion.isEmpty else {
            fatalError("Files still exist in the US S3 AWS bucket.")
        }
        
        return true
    }
}
