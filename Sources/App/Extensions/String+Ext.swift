//
//  String+Ext.swift
//  
//
//  Created by Filippo Lobisch on 02.02.23.
//

import Foundation

extension String: LocalizedError {
    public var errorDescription: String? { return self }
}
