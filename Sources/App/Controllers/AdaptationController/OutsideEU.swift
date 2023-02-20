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
    private var storeDataOnlyInEU = true {
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
    
    /// The north american AWS manager.
    let northAmericaAWSManager = AWSS3Manager.northAmericaManager
    
    /// The initialiser of the OutsideEU class. Takes in an optional parameter that is used to connect this adaptation controller to the more generic controller.
    /// - Parameter adaptationController: Optional adaptation controlller that can be used to call generic methods such as register app on radar and more.
    init(adaptationController: AdaptationController? = nil) {
        self.adaptationController = adaptationController
    }
    
    /// Handles the execution of this adaptation between solely EU component and both regions.
    /// Toggles the property that determines where data is stored, everytime the adaptation is executed.
    /// It then handles the appropriate adaptation case for the new `storeDataOnlyInEU` value.
    /// Once the adaptation is performed it calls the `getFilesConstantly` method to create a constant workload.
    /// Returns the "completed" string if no error is thrown and the adaptation was successfully executed.
    /// - Parameter model: The model of the system. (Unused).
    final func executeAdaptation(model: String) async throws -> String {
        storeDataOnlyInEU.toggle()
        
        if storeDataOnlyInEU {
            _ = try await storeDataInEU()
        } else {
            _ = try await storeDataOutsideEU()
        }
        
        await getFilesConstantly()
        return "Completed"
    }
    
    /// Method that gets files constantly.
    /// Runs every two seconds to ensure that it creates a constant workload on the system.
    /// To ensure fair use of both cloud regions, we use the `randomElement` method, if `storeDataOnlyInEU` is true, otherwise we use the European AWS manager solely.
    /// Furthermore, we download a random file from the bucket to ensure that no bias is taken.
    private func getFilesConstantly() async {
        Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] timer in
            guard let self else { return }
            guard !self.invalidateTimer else { timer.invalidate(); return }
            
            let managers = [self.europeAWSManager, self.northAmericaAWSManager]
            let selectedManager = self.storeDataOnlyInEU ? self.europeAWSManager : managers.randomElement()!
            
            Task {
                do {
                    let files = try await selectedManager.getAllFilesInBucket()
                    guard let selectedFileKey = files.randomElement() else {
                        throw "Could not retrieve random element from the received file names of the bucket."
                    }
                    
                    _ = try await selectedManager.download(fileKey: selectedFileKey)
                } catch {
                    print(error.localizedDescription)
                }
            }
        }
    }
    
    /// Method that stores the local file data onto the European S3 bucket.
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
    
    
    /// Method that stores the local file data onto the European S3 bucket.
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
