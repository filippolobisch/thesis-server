//
//  AWSManager.swift
//
//
//  Created by Filippo Lobisch on 12.01.23.
//

import Foundation
import AWSS3
import ClientRuntime
import AWSClientRuntime

/// An enum error structure used to providing more descriptive errors when making requests.
enum AWSError: String, Error {
    case couldNotRetrieveListObjects
}

/// A struct object used as an intermediate interface to handle methods of downloading, uploading and deleting files of an AWS S3 bucket.
struct AWSS3Manager {
    
    /// The AWS S3 manager instance to manager files hosted in the S3 bucket in the european region.
    static let europeManager = AWSS3Manager(bucketName: Constants.euS3BucketName.rawValue, region: .euCentral1)
    
    /// The AWS S3 manager instance to manager files hosted in the S3 bucket in the north american region.
    static let northAmericaManager = AWSS3Manager(bucketName: Constants.naS3BucketName.rawValue, region: .usEast2)
    
    /// The name of the bucket.
    let bucketName: String
    
    /// The region this bucket is located in.
    let region: S3ClientTypes.BucketLocationConstraint
    
    /// The AWS S3 client object used to make requests.
    let client: S3Client
    
    /// The local file manager to occassionally get or save files to local storage.
    let localManager = LocalFileManager()
    
    
    /// The initializer of the `AWSS3Manager`.
    /// - Parameters:
    ///   - bucketName: The name of the bucket.
    ///   - region: The region the bucket is located in. Default value of `euCentral1` as we are mostly dealing with the EU region.
    init(bucketName: String, region: S3ClientTypes.BucketLocationConstraint = .euCentral1) {
        self.bucketName = bucketName
        self.region = region

        do {
            self.client = try S3Client(region: region.rawValue)
        } catch {
            fatalError(error.localizedDescription)
        }
    }

    /// Returns a list of the files that are stored in AWS S3 for this particular region.
    func getAllFilesInBucket() async throws -> [String] {
        let listInput = ListObjectsV2Input(bucket: bucketName)
        guard let objects = try await client.listObjectsV2(input: listInput).contents else {
            throw AWSError.couldNotRetrieveListObjects
        }

        return objects.compactMap(\.key) // Here the key of an AWS S3 object represents the file name.
    }

    /// Returns the result of whether the file was successfully uploaded to this bucket.
    /// - Parameters:
    ///   - name: The name of the resource to upload.
    ///   - ext: The file extension of the resource to upload.
    func upload(resource name: String, withExtension ext: String? = nil) async throws -> Bool {
        let filename = localManager.makeSingleStringFilename(forResource: name, withExtension: ext)
        let fileData = try localManager.get(contentsOf: name, withExtension: ext)
        return try await upload(data: fileData, using: filename)
    }


    
    /// Returns the result of whether the file was successfully uploaded to this bucket.
    /// - Parameters:
    ///   - data: The data to be uploaded to the bucket.
    ///   - name: The name of the resource to upload.
    ///   - ext: The file extension of the resource to upload.
    func upload(data: Data, using filename: String) async throws -> Bool {
        let dataStream = ByteStream.from(data: data)
        
        let input = PutObjectInput(body: dataStream, bucket: bucketName, key: filename)
        _ = try await client.putObject(input: input)

        let files = try await getAllFilesInBucket()
        return files.contains(filename)
    }

    
    /// Returns the data downloaded from a file that is stored in AWS S3 bucket for this region and name.
    /// - Parameter fileKey: The name of the file to be downloaded.
    func download(fileKey: String) async throws -> Data {
        let objectInput = GetObjectInput(bucket: bucketName, key: fileKey)
        let response = try await client.getObject(input: objectInput)

        guard let bodyData = response.body else {
            fatalError("Could not get data from response")
        }

        let data = bodyData.toBytes().getData()
        try localManager.save(data: data, toResource: fileKey)
         
        return data
    }

    
    /// Returns the result of whether the file was successfully deleted from this bucket.
    /// - Parameter fileKey: The name of the file to be deleted from the bucket.
    public func delete(fileKey: String) async throws -> Bool {
        let deleteObjectInput = DeleteObjectInput(bucket: bucketName, key: fileKey)
        _ = try await client.deleteObject(input: deleteObjectInput)

        let files = try await getAllFilesInBucket()
        return !files.contains(fileKey)
    }
}
