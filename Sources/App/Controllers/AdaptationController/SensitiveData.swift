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
    private(set) var task: Task<Void, any Error>?
    
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
    final func executeAdaptation(model: String) async throws -> String {
        Logger.shared.add(message: "Started adapting the system for the SensitiveData adaptation.")
        usesCloud.toggle()
        
        var systemDidAdapt = false
        if usesCloud {
            systemDidAdapt = try await storeSensitiveDataOnTheCloud()
        } else {
            systemDidAdapt = try await moveSensitiveDataFromCloudToLocal()
        }
        
        guard systemDidAdapt else {
            throw "SensitiveData adaptation was not performed."
        }
        
        Logger.shared.add(message: "Finished adapting the system for the SensitiveData adaptation.")
        try await getFilesConstantly()
        return "Completed"
    }
    
    
    /// Method that gets files constantly from the cloud.
    /// Checks the usesCloud property and selects the appropriate background task method.
    final func getFilesConstantly() async throws {
        Logger.shared.add(message: "Starting the SensitiveData getFilesConstantly task with usesCloud as \(usesCloud).")
        if usesCloud {
            try await getFilesConstantlyFromCloud()
        } else {
            try await getFilesConstantlyFromLocal()
        }
        
        Logger.shared.add(message: "Started the SensitiveData getFilesConstantly task with usesCloud as \(usesCloud).")
    }
    
    /// Method that gets files constantly from the cloud.
    /// We use the European AWS manager solely to simply this use case instead of tracking and randomising where files get located.
    /// Furthermore, we download all files to ensure no bias is taken. Once again, concurrently.
    private func getFilesConstantlyFromCloud() async throws {
        let files = try await europeAWSManager.getAllFilesInBucket()
        
        task = Task {
            try await withThrowingTaskGroup(of: Void.self) { group in
                if Task.isCancelled {
                    group.cancelAll()
                }

                while !Task.isCancelled {
                    for file in files {
                        _ = group.addTaskUnlessCancelled {
                            _ = try await self.europeAWSManager.download(fileKey: file)
                        }
                    }

                    try await group.waitForAll()
                }
            }
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
    /// Since we store all files always in the `data_files` directory we check that directory and read files from there, concurrently.
    private func getFilesConstantlyFromLocal() async throws {
        let files = try localManager.listAllFilesInDataFilesDirectory()
        
        task = Task {
            try await withThrowingTaskGroup(of: Void.self) { group in
                if Task.isCancelled {
                    group.cancelAll()
                }

                while !Task.isCancelled {
                    for file in files {
                        _ = group.addTaskUnlessCancelled {
                            let (filename, ext) = self.split(filename: file)
                            _ = try self.localManager.get(contentsOf: filename, withExtension: ext)
                        }
                    }

                    try await group.waitForAll()
                }
            }
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
    /// We retrieve the files from the European S3 bucket, in parallel, with their data being downloaded.
    /// Followed by this it is saved to local directory into the `data_files` directory.
    /// Once the file is saved it is deleted from the bucket, as per adaptation description to move data from the cloud to local component.
    /// Returns `true` if no error is thrown.
    private func moveSensitiveDataFromCloudToLocal() async throws -> Bool {
        Logger.shared.add(message: "Moving sensitive data from the cloud to the local component.")
        let files = try await europeAWSManager.getAllFilesInBucket()
        
        let result = try await withThrowingTaskGroup(of: Bool.self) { group in
            for file in files {
                group.addTask {
                    return try await self.moveFileToLocalStorage(file: file)
                }
            }
            
            var results: [Bool] = []
            for try await result in group {
                results.append(result)
            }
            
            Logger.shared.add(message: "Results array == \(results). Bucket files == \(files)")
            return results.filter { $0 == true }.count == files.count
        }
        
        guard result else { throw "Not all files were moved from cloud storage to the local storage." }
        Logger.shared.add(message: "Moved sensitive data from the cloud to the local component.")
        
        return true
    }
    
    /// Method to move the file to local storage.
    /// The file is first retrieved from the AWS Bucket, and then saved to local storage.
    /// After the save, it is deleted from the AWS bucket.
    /// The method returns `true` if no error is thrown.
    /// - Parameter file: The file to move to local storage.
    private func moveFileToLocalStorage(file: String) async throws -> Bool {
        let fileData = try await europeAWSManager.download(fileKey: file)
        let (filename, ext) = split(filename: file)
        
        try localManager.save(data: fileData, toResource: filename, withExtension: ext)
        
        let didDeleteFile = try await europeAWSManager.delete(fileKey: file)
        guard didDeleteFile else { throw "Could not delete file from bucket." }
        return true
    }
    
    /// Method that stores the local file data onto the European S3 bucket.
    /// We retrieve the files from the `data_files` directory, concurrently, with their data being read.
    /// Followed by this it is uploaded to the European S3 bucket.
    /// Like with the `getFilesConstantlyUsingCloud`, we use the European AWS manager solely to simply this use case instead of tracking and randomising where files get located.
    /// Returns `true` if no error is thrown.
    private func storeSensitiveDataOnTheCloud() async throws -> Bool {
        Logger.shared.add(message: "Storing sensitive data on the cloud.")
        let files = try localManager.listAllFilesInDataFilesDirectory()
        
        let result = try await withThrowingTaskGroup(of: Bool.self) { group in
            for file in files {
                group.addTask {
                    return try await self.moveFileToTheCloud(file: file)
                }
            }
            
            var results: [Bool] = []
            for try await result in group {
                results.append(result)
            }
            
            Logger.shared.add(message: "Results array == \(results). Bucket files == \(files)")
            return results.filter { $0 == true }.count == files.count
        }
        
        guard result else { throw "Not all files were moved from local storage to the cloud." }
        Logger.shared.add(message: "Stored sensitive data on the cloud.")
        return true
    }
    
    /// Method to move the file to local storage.
    /// The file is first retrieved from local storage, and then saved to the AWS bucket.
    /// It is then deleted from local storage is the upload is successful.
    /// The method returns `true` if no error is thrown.
    /// - Parameter file: The file to move to local storage.
    private func moveFileToTheCloud(file: String) async throws -> Bool {
        let (name, ext) = split(filename: file)
        let sensitiveDataUploaded = try await europeAWSManager.upload(resource: name, withExtension: ext)
        guard sensitiveDataUploaded else { throw "Could not upload sensitive data to cloud." }
        
        try localManager.delete(resource: name, withExtension: ext)
        return true
    }
}
