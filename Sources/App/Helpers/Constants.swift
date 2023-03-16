//
//  Constants.swift
//
//
//  Created by Filippo Lobisch on 28.01.23.
//

import Foundation

/// Useful constants for this project.
/// We use this so that we can call `Constants.euS3BucketName.rawValue` each time to ensure no spelling mistakes occur if we need to type the bucket name.
enum Constants: String {
    case euS3BucketName = "eu-data-bucket"
    case naS3BucketName = "fl-na-data-bucket"
}
