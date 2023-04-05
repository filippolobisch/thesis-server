//
//  SensitiveData.swift
//
//
//  Created by Filippo Lobisch on 13.02.23.
//

import Foundation

/// Class that handles the sensitive data adaptation.
class SensitiveData {
    
    /// Property that determines whether the data is stored on the cloud component of this web server.
    private(set) var usesCloud = true {
        willSet {
            cancelTask()
        }
    }
    
    /// The task object that is used as a recurring task to generate system load.
    private(set) var task: Task<Void, Never>?
    
    /// The European AWS manager.
    let europeAWSManager = AWSS3Manager.europeManager
    
    /// The local file manager that can be used to
    let localManager = LocalFileManager()
    
    
    /// Main function that runs the sensitive data stored either in the cloud or local based on a conditional of `usesCloud`.
    /// Handles the execution of this adaptation between sensitive data being stored in the cloud or locally.
    /// Toggles the property that determines where data is stored, every time the adaptation is executed.
    /// It then handles the appropriate adaptation case for the new `usesCloud` value.
    /// Once the adaptation is performed it calls the appropriate `getFilesConstantly`method to create a constant workload, based on the new `usesCloud` value.
    /// Returns the "completed" string if no error is thrown and the adaptation was successfully executed.
    /// - Parameters:
    ///   - model: The model of the system. (Unused).
    ///   - numberOfTimesToExecute: The number of times to execute this adaptation.
    final func executeAdaptation(model: String, numberOfTimesToExecute: Int) async throws -> String {
        let isOdd = !numberOfTimesToExecute.isMultiple(of: 2)
        
        // We only adapt the system if the number of times to execute is odd. This is because if it is even it is as if nothing had occurred.
        if isOdd {
            Logger.shared.add(message: "Started adapting the system for the SensitiveData adaptation.")
            usesCloud.toggle()
            
            let adaptSystemTask = Task<Bool, any Error> {
                if usesCloud {
                    return try await storeSensitiveDataOnTheCloud()
                } else {
                    return try await moveSensitiveDataFromCloudToLocal()
                }
            }
            
            let didAdapt = try await adaptSystemTask.value
            guard didAdapt else {
                throw "SensitiveData adaptation was not performed."
            }
            
            Logger.shared.add(message: "Finished adapting the system for the SensitiveData adaptation.")
            
            getFilesConstantly()
        }
        
        return "Completed"
    }
    
    
    /// Method that gets files constantly from the cloud.
    /// Checks the usesCloud property and selects the appropriate background task method.
    final func getFilesConstantly() {
        Logger.shared.add(message: "Starting the SensitiveData getFilesConstantly task with usesCloud as \(usesCloud).")
        if usesCloud {
            getFilesConstantlyFromCloud()
        } else {
            getFilesConstantlyFromLocal()
        }
        
        Logger.shared.add(message: "Started the SensitiveData getFilesConstantly task with usesCloud as \(usesCloud).")
    }
    
    /// Method that gets files constantly from the cloud.
    /// Runs every two seconds to ensure that it creates a constant workload on the system.
    /// We use the European AWS manager solely to simply this use case instead of tracking and randomising where files get located.
    /// Furthermore, we download a random file from the bucket to ensure that no bias is taken.
    private func getFilesConstantlyFromCloud() {
        task = Task {
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
                    
                    _ = try await europeAWSManager.download(fileKey: selectedFileKey)
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
    
    /// Method to split a single filename into name and extension.
    /// Returns the name of the file and an extension if it is exists, otherwise nil.
    private func split(filename: String) -> (String, String?) {
        let fileKeySplit = filename.components(separatedBy: ".")
        let name = fileKeySplit.first!
        
        var ext: String? = nil
        if fileKeySplit.count > 0 { ext = fileKeySplit.last }
        
        return (name, ext)
    }
    
    /// Method that gets files constantly from local directory.
    /// Runs every two seconds to ensure that it creates a constant workload on the system.
    /// Since we store all files always in the `data_files` directory we check that directory and read a randomly selected file from there.
    private func getFilesConstantlyFromLocal() {
        task = Task {
            repeat {
                do {
                    let files = try localManager.listAllFilesInDataFilesDirectory()
                    guard let selectedFileKey = files.randomElement() else {
                        throw "Could not retrieve random element from the received file names of local directory."
                    }
                    
                    let (filename, ext) = split(filename: selectedFileKey)
                    _ = try localManager.get(contentsOf: filename, withExtension: ext)
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
        Logger.shared.add(message: "Cancelling the SensitiveData getFilesConstantly task for usesCloud as \(usesCloud).")
        task?.cancel()
        task = nil
        Logger.shared.add(message: "Cancelled the SensitiveData getFilesConstantly task for usesCloud as \(usesCloud).")
    }
    
    /// Method that stores the bucket data onto the data files local directory.
    /// We retrieve the files from the European S3 bucket (one by one) with their data being downloaded.
    /// Followed by this it is saved to local directory into the `data_files` directory.
    /// Once the file is saved it is deleted from the bucket, as per adaptation description to move data from the cloud to local component.
    /// Returns `true` if no error is thrown.
    private func moveSensitiveDataFromCloudToLocal() async throws -> Bool {
        Logger.shared.add(message: "Moving sensitive data from the cloud to the local component.")
        let bucketFiles = try await europeAWSManager.getAllFilesInBucket()
        
        for file in bucketFiles {
            let fileData = try await europeAWSManager.download(fileKey: file)
            let (filename, ext) = self.split(filename: file)
            
            try localManager.save(data: fileData, toResource: filename, withExtension: ext)
            
            let fileDeleted = try await europeAWSManager.delete(fileKey: file)
            guard fileDeleted else {
                fatalError("Could not delete file from bucket.")
            }
        }
        
        let remainingAWSBucketFiles = try await europeAWSManager.getAllFilesInBucket()
        guard remainingAWSBucketFiles.isEmpty else {
            fatalError("Files still exist in the EU S3 AWS bucket.")
        }
        
        Logger.shared.add(message: "Moved sensitive data from the cloud to the local component.")
        
        return true
    }
    
    /// Method that stores the local file data onto the European S3 bucket.
    /// We retrieve the files from the `data_files` directory (one by one), with their data being read.
    /// Followed by this it is uploaded to the European S3 bucket.
    /// Like with the `getFilesConstantlyUsingCloud`, we use the European AWS manager solely to simply this use case instead of tracking and randomising where files get located.
    /// Returns `true` if no error is thrown.
    private func storeSensitiveDataOnTheCloud() async throws -> Bool {
        Logger.shared.add(message: "Storing sensitive data on the cloud.")
        let files = try localManager.listAllFilesInDataFilesDirectory() // Change to sensitive directory.
        for file in files {
            let (name, ext) = split(filename: file)
            let sensitiveDataUploaded = try await europeAWSManager.upload(resource: name, withExtension: ext)
            
            guard sensitiveDataUploaded else {
                fatalError("Could not upload sensitive data to cloud.")
            }
        }
        
        Logger.shared.add(message: "Stored sensitive data on the cloud.")
        return true
    }
}
