//
//  NetworkError.swift
//  
//
//  Created by Filippo Lobisch on 16.05.23.
//

import Foundation

/// Enum object used to provide more descriptive Network errors that might occur when performing a network call.
enum NetworkError: String, Error {
    case invalidURL = "The URL provided is invalid."
    case unableToCompleteRequest = "Unable to complete your request. Please check your internet connection."
    case invalidResponseFromServer = "Invalid response from the server. The response given from URLSession is not equal to statusCode 200 (OK)."
    case invalidDataFromServer = "The data received from the server was invalid."
    case failedToDecodeData = "Failed to decode the data into the appropriate format."
}
