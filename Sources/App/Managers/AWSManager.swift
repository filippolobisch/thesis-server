//
//  AWSManager.swift
//
//
//  Created by Filippo Lobisch on 12.01.23.
//

import Foundation
import SotoS3

/// A struct object used as an intermediate interface to handle methods of downloading, uploading and deleting files of an AWS S3 bucket.
struct AWSS3Manager {
    
    /// The AWS S3 manager instance to manager files hosted in the S3 bucket in the European region.
    static let europeManager = AWSS3Manager(bucketName: Constants.euS3BucketName.rawValue, region: .eucentral1)
    
    /// The AWS S3 manager instance to manager files hosted in the S3 bucket in the North American region.
    static let northAmericaManager = AWSS3Manager(bucketName: Constants.naS3BucketName.rawValue, region: .useast2)
    
    
    /// The name of the bucket.
    let bucketName: String
    
    /// The region this bucket is located in.
    let region: Region
    
    /// The AWS S3 client object used to make requests.
    let client: S3
    
    /// The local file manager to occasionally get or save files to local storage.
    let localManager = LocalFileManager()
    
    
    /// The region name of the bucket.
    var regionName: String {
        switch region {
        case .useast2:
            return "North American"
        default:
            return "European Union"
        }
    }
    
    
    /// The initializer of the `AWSS3Manager`.
    /// - Parameters:
    ///   - bucketName: The name of the bucket.
    ///   - region: The region the bucket is located in. Default value of `euCentral1` as we are mostly dealing with the EU region.
    init(bucketName: String, region: Region = .eucentral1) {
        self.bucketName = bucketName
        self.region = region
        
        let awsClient = AWSClient(credentialProvider: .default, httpClientProvider: .createNew)
        self.client = S3(client: awsClient, region: region)
    }

    /// Returns a list of the files that are stored in AWS S3 for this particular region.
    func getAllFilesInBucket() async throws -> [String] {
        let request = S3.ListObjectsV2Request(bucket: bucketName)
        let response = try await client.listObjectsV2(request)
        guard let objects = response.contents else { return [] }
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
    ///   - filename: The name of the resource.
    func upload(data: Data, using filename: String) async throws -> Bool {
        let payload = AWSPayload.byteBuffer(ByteBuffer(data: data))
        let request = S3.PutObjectRequest(body: payload, bucket: bucketName, key: filename)
        _ = try await client.putObject(request)
        return true
    }

    
    /// Returns the data downloaded from a file that is stored in AWS S3 bucket for this region and name.
    /// - Parameter fileKey: The name of the file to be downloaded.
    func download(fileKey: String) async throws -> Data {
        let request = S3.GetObjectRequest(bucket: bucketName, key: fileKey)
        let response = try await client.getObject(request)
        
        guard let bodyData = response.body, let data = bodyData.asData() else {
            fatalError("Could not get data from response")
        }
        
        return data
    }
    
    /// Returns the data downloaded from a file that is stored in AWS S3 bucket for this region and name and saves it to local directory.
    /// - Parameter fileKey: The name of the file to be downloaded.
    func downloadAndSave(fileKey: String) async throws -> Data {
        let data = try await download(fileKey: fileKey) // Calls the download method above.
        try localManager.save(data: data, toResource: fileKey)
        return data
    }
    
    /// Returns the result of whether the file was successfully deleted from this bucket.
    /// - Parameter fileKey: The name of the file to be deleted from the bucket.
    public func delete(fileKey: String) async throws -> Bool {
        let request = S3.DeleteObjectRequest(bucket: bucketName, key: fileKey)
        _ = try await client.deleteObject(request)
        return true
    }
}
