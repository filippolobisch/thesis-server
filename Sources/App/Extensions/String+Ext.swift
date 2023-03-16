//
//  String+Ext.swift
//
//
//  Created by Filippo Lobisch on 02.02.23.
//

import Foundation

/// A string extension enabling strings to be typed as errors instead of requiring custom error objects to throw an error.
extension String: LocalizedError {
    public var errorDescription: String? { return self }
}
