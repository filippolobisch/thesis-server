//
//  LocalManager.swift
//  
//
//  Created by Filippo Lobisch on 13.01.23.
//

import Foundation

/// An object used as an intermediate interface between the server and Apple's file manager methods.
actor LocalManager {
    
    /// The bundle of this module. Useful for retrieving file paths and other things.
    let bundle = Bundle.module
    
    /// Holds a reference to the shared `default` instance of Apple's `FileManager`.
    /// The purpose of this object is to avoid having to re-type `FileManager.default` anytime access to the `FileManager` is needed.
    let fileManager = FileManager.default
    
    /// The URL to the `Resources` directory.
    /// A platform conditional is used since when using Xcode (for testing) the additional folders of Contents and Resources are present.
    var resourcesURL: URL {
        #if Xcode
        return bundle.bundleURL.appending(path: "Contents").appending(path: "Resources")
        #else
        return bundle.bundleURL
        #endif
    }
    
    /// Returns the names of the files located in the `Resources` directory.
    /// Uses the file manager enumerator to perform a deep search of the files located under the `Resources` directory. This includes files located inside subfolders.
    func listFilesInResourcesDirectory() throws -> [(String, String)] {
        // The following guard condition was taken from the 'enumerator' documentation method in Apple's documentation.
        // It can be found at the following link: https://developer.apple.com/documentation/foundation/filemanager/2765464-enumerator
        guard let directoryEnumerator = fileManager.enumerator(at: resourcesURL, includingPropertiesForKeys: [.nameKey, .isDirectoryKey], options: .skipsHiddenFiles) else {
            fatalError("Could not enumerate the subfiles of the Resources directory.")
        }

        var files: [(String, String)] = []

        // The following 'for case let' and the first guard condition was taken from the 'enumerator' documentation method in Apple's documentation.
        // It was modified to fit the purpose of this software.
        // It can be found at the following link: https://developer.apple.com/documentation/foundation/filemanager/2765464-enumerator
        for case let fileURL as URL in directoryEnumerator {
            let resourceValues = try fileURL.resourceValues(forKeys: [.nameKey, .isDirectoryKey])
            guard let isDirectory = resourceValues.isDirectory, !isDirectory else { continue }
            let name = fileURL.deletingPathExtension().lastPathComponent
            let ext = fileURL.pathExtension
            files.append((name, ext))
        }
        
        return files
    }
    
    /// Returns the URL of a provided resource name and extension if it exists in the directory of this project.
    /// If it doesn't exist it creates a url of the filename inside the `Resources` directory.
    /// - Parameters:
    ///   - name: The name of the resource.
    ///   - ext: The extension of the resource.
    func getFileURL(forResource name: String, withExtension ext: String?) -> URL {
        guard let url = bundle.url(forResource: name, withExtension: ext) else {
            return createFileURL(forResource: name, withExtension: ext)
        }

        return url
    }
    
    /// Returns the data of an object stored in the resources directory.
    /// - Parameters:
    ///   - name: The name of the resource.
    ///   - ext: The extension of the resource.
    func get(contentsOf name: String, withExtension ext: String?) throws -> Data {
        let path = getFileURL(forResource: name, withExtension: ext)
        return try Data(contentsOf: path)
    }
    
    /// Returns a created URL in the `Resources` directory for a provided filename and extension.
    /// - Parameters:
    ///   - name: The name of the resource.
    ///   - ext: The extension of the resource.
    func createFileURL(forResource name: String, withExtension ext: String?) -> URL {
        guard let ext else {
            return resourcesURL.appendingPathComponent(name)
        }
        
        let sanitizedExtension = ext.trimmingCharacters(in: .whitespacesAndNewlines)
        guard sanitizedExtension != "" else {
            return resourcesURL.appendingPathComponent(name)
        }
        
        let filename = "\(name).\(sanitizedExtension)"
        let fileURL = resourcesURL.appendingPathComponent(filename)
        return fileURL
    }

    /// Writes the data contents to a file with a given name in the `Resources` directory.
    /// Returns true if the file with its contents was successfully saved, false if any error occurred.
    /// - Parameters:
    ///   - data: The data to be saved.
    ///   - name: The name of the resource.
    ///   - ext: The extension of the resource.
    func save(data: Data, toResource name: String, withExtension ext: String?) throws {
        let fileURL = getFileURL(forResource: name, withExtension: ext)
        try data.write(to: fileURL, options: .atomic)
    }

    /// Deletes the file from the project directory if it exists.
    /// - Parameters:
    ///   - name: The name of the resource.
    ///   - ext: The extension of the resource.
    func delete(resource name: String, withExtension ext: String?) throws {
        let fileURL = getFileURL(forResource: name, withExtension: ext)
        try fileManager.removeItem(at: fileURL)
    }
}
