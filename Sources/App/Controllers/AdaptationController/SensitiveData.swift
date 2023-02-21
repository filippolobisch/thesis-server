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
    private var usesCloud = true {
        didSet {
            invalidateTimer = true
        }
    }
    
    /// Property that determines when to invalidate the constant task timer.
    private var invalidateTimer = false
    
    /// Hold a weak reference to the passed adaptation controller to potentially send updates to RADAR.
    /// We use a weak reference to prevent a retain cycle (i.e., strong references for both objects such that they never get de-allocated from memory).
    weak var adaptationController: AdaptationController? = nil
    
    /// The european AWS manager.
    let europeAWSManager = AWSS3Manager.europeManager
    
    /// The local file manager that can be used to
    let localManager = LocalFileManager()
    
    /// The initialiser of the SensitiveData class. Takes in an optional parameter that is used to connect this adaptation controller to the more generic controller.
    /// - Parameter adaptationController: Optional adaptation controlller that can be used to call generic methods such as register app on radar and more.
    init(adaptationController: AdaptationController? = nil) {
        self.adaptationController = adaptationController
    }
    
    /// Main function that runs the sensitive data stored either in the cloud or local based on a conditional of `usesCloud`.
    /// Handles the execution of this adaptation between sensitive data being stored in the cloud or locally.
    /// Toggles the property that determines where data is stored, everytime the adaptation is executed.
    /// It then handles the appropriate adaptation case for the new `usesCloud` value.
    /// Once the adaptation is performed it calls the appropriate `getFilesConstantly`method to create a constant workload, based on the new `usesCloud` value.
    /// Returns the "completed" string if no error is thrown and the adaptation was successfully executed.
    /// - Parameter model: The model of the system. (Unused).
    final func executeAdaptation(model: String) async throws -> String {
        if usesCloud {
            _ = try await storeSensitiveDataOnTheCloud()
            getFilesConstantlyUsingCloud()
        } else {
            _ = try await moveSensitiveDataFromCloudToLocal()
            getFilesConstantlyLocally()
        }
        
        return "Completed"
    }
    
    /// Method that gets files constantly from the cloud.
    /// Runs every two seconds to ensure that it creates a constant workload on the system.
    /// We use the European AWS manager solely to simply this use case instead of tracking and randomising where files get located.
    /// Furthermore, we download a random file from the bucket to ensure that no bias is taken.
    private func getFilesConstantlyUsingCloud() {
        Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] timer in
            guard let self else { return }
            guard !self.invalidateTimer else { timer.invalidate(); return }
            
            let manager = self.europeAWSManager
            
            Task {
                do {
                    let files = try await manager.getAllFilesInBucket()
                    guard let selectedFileKey = files.randomElement() else {
                        throw "Could not retrieve random element from the received file names of the bucket."
                    }
                    
                    _ = try await manager.download(fileKey: selectedFileKey)
                } catch {
                    print(error.localizedDescription)
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
    /// Runs every two seconds to ensure that it creates a constant workload on the system.
    /// Since we store all files always in the `data_files` directory we check that directory and read a randomly selected file from there.
    private func getFilesConstantlyLocally() {
        Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] timer in
            guard let self else { return }
            guard !self.invalidateTimer else { timer.invalidate(); return }
            
            do {
                let files = try self.localManager.listAllFilesInDataFilesDirectory()
                guard let selectedFileKey = files.randomElement() else {
                    throw "Could not retrieve random element from the received file names of the bucket."
                }
                
                let (filename, ext) = self.split(filename: selectedFileKey)
                _ = try self.localManager.get(contentsOf: filename, withExtension: ext)
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    /// Method that stores the bucket data onto the data files local directory.
    /// We retrieve the files from the European S3 bucket (one by one) with their data being downloaded.
    /// Followed by this it is saved to local directory into the `data_files` directory.
    /// Once the file is saved it is deleted from the bucket, as per adaptation description to move data from the cloud to local component.
    /// Returns `true` if no error is thrown.
    private func moveSensitiveDataFromCloudToLocal() async throws -> Bool {
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
        
        return true
    }
    
    /// Method that stores the local file data onto the European S3 bucket.
    /// We retrieve the files from the `data_files` directory (one by one), with their data being read.
    /// Followed by this it is uploaded to the European S3 bucket.
    /// Like with the `getFilesConstantlyUsingCloud`, we use the European AWS manager solely to simply this use case instead of tracking and randomising where files get located.
    /// Returns `true` if no error is thrown.
    private func storeSensitiveDataOnTheCloud() async throws -> Bool {
        let files = try localManager.listAllFilesInDataFilesDirectory() // Change to sensitive directory.
        for file in files {
            let (name, ext) = split(filename: file)
            let sensitiveDataUploaded = try await europeAWSManager.upload(resource: name, withExtension: ext)
            
            guard sensitiveDataUploaded else {
                fatalError("Could not upload sensitive data to cloud.")
            }
        }
        
        return true
    }
}
