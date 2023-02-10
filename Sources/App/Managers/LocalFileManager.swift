//
//  LocalFileManager.swift
//  
//
//  Created by Filippo Lobisch on 13.01.23.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// A helper enumeration that conforms to String and Error useful for throwing custom errors.
enum FileManagerError: String, Error {
    case currentDirectoryPathNotTransformableToURL = "The current directory path could not be transformed into the type URL."
    case fileDoesNotExist = "The file at the provided URL does not exist."
    case filePathWithSchemeNotTransformableToURLType = "The file path with the 'file://' scheme could not be transformed into the type URL."
}


/// A struct object used as an intermediate interface between the server and Apple's file manager methods.
struct LocalFileManager {
    /// Holds a reference to the shared `default` instance of Apple's `FileManager`.
    /// The purpose of this object is to avoid having to re-type `FileManager.default` anytime access to the `FileManager` is needed.
    private let fileManager = FileManager.default
    
    
    /// Returns the project directory URL.
    var projectDirectoryURL: URL {
        guard
            var filePath = URL(string: #filePath),
            let indexThesisWebServerPathComponent = filePath.pathComponents.firstIndex(of: "thesis-server")
        else {
            fatalError("Could not retrieve project directory.")
        }
        
        repeat {
            filePath.deleteLastPathComponent()
        } while filePath.pathComponents.count > (indexThesisWebServerPathComponent + 1)
        
        return filePath
    }
    
    
    /// Returns a single string filename for a given name and extension.
    /// It performs some sanitation checks and returns the best filename for the parameters passed.
    /// - Parameters:
    ///   - name: The name of the resource.
    ///   - ext: The extension of the resource.
    func makeSingleStringFilename(forResource name: String, withExtension ext: String? = nil) -> String {
        guard let ext else { return name }
        let extensionSanitized = ext.trimmingCharacters(in: .whitespacesAndNewlines)
        guard ext != "" else { return name }
        return "\(name).\(extensionSanitized)"
    }
    
    
    /// Returns the URL of a provided resource name and extension if it exists in the directory of this project.
    /// If it doesn't exist it creates a url of the filename inside the `data_files` directory.
    /// - Parameters:
    ///   - name: The name of the resource.
    ///   - ext: The extension of the resource.
    func url(forResource name: String, withExtension ext: String? = nil) throws -> URL {
        let filename = makeSingleStringFilename(forResource: name, withExtension: ext)
        
        // The following guard condition was taken from the 'enumerator' documentation method in Apple's documentation.
        // It can be found at the following link: https://developer.apple.com/documentation/foundation/filemanager/2765464-enumerator
        guard let directoryEnumerator = fileManager.enumerator(at: projectDirectoryURL, includingPropertiesForKeys: [.nameKey, .isDirectoryKey], options: .skipsHiddenFiles) else {
            fatalError("Could not enumerate the subdirectories and subfiles of the project.")
        }
         
        var fileURLForResource: URL? = nil
        
        // The following 'for case let' and the first guard condition was taken from the 'enumerator' documentation method in Apple's documentation.
        // Minor modifications were made from the example in the documentation.
        // It can be found at the following link: https://developer.apple.com/documentation/foundation/filemanager/2765464-enumerator
        for case let fileURL as URL in directoryEnumerator {
            let resourceValues = try fileURL.resourceValues(forKeys: [.nameKey, .isDirectoryKey])
            guard let isDirectory = resourceValues.isDirectory, var name = resourceValues.name, !isDirectory else {
                continue
            }
            
            if ext == nil {
                name = name.components(separatedBy: ".")[0]
            }
            
            guard name == filename else { continue }
            fileURLForResource = fileURL
            break
        }
        
        guard let fileURLForResource else {
            return try createURL(for: filename)
        }
        
        return fileURLForResource
    }
    
    
    /// Returns a created URL in the `data_files` directory for a provided filename that includes the extension.
    /// - Parameter filename: The name of the file to create a URL for.
    private func createURL(for filename: String) throws -> URL {
        let folderURL = projectDirectoryURL.appendingPathComponent("data_files")
        try fileManager.createDirectory(atPath: folderURL.absoluteString, withIntermediateDirectories: true)
        let fileURL = folderURL.appendingPathComponent(filename)
        guard let fileUrlWithScheme = URL(string: "file://\(fileURL)") else {
            throw FileManagerError.filePathWithSchemeNotTransformableToURLType
        }
        return fileUrlWithScheme
    }
    
    
    /// Returns the contents of a given filename as a `Data` object if the file exists.
    /// - Parameter file: The name of the file to retrieve from local directory.
    func get(contentsOf file: String, withExtension ext: String? = nil) throws -> Data {
        let fileURL = try url(forResource: file, withExtension: ext)
        return try Data(contentsOf: fileURL)
    }


    /// Writes the data contents to a file with a given name in the `data_files` directory.
    /// Returns true if the file with its contents was successfully saved, false if any error occurred.
    /// - Parameters:
    ///   - data: The data to be saved.
    ///   - name: The name of the resource.
    ///   - ext: The extension of the resource.
    func save(data: Data, toResource name: String, withExtension ext: String? = nil) throws {
        let fileURL = try url(forResource: name, withExtension: ext).absoluteURL
        try data.write(to: fileURL, options: .atomic)
    }

    
    /// This update method simply serves as an interface to the save method (for easier reading), since the save method overwrites files.
    /// - Parameters:
    ///   - data: The data to be saved.
    ///   - name: The name of the resource.
    ///   - ext: The extension of the resource.
    func update(data: Data, ofResource name: String, withExtension ext: String? = nil) throws {
        try save(data: data, toResource: name, withExtension: ext)
    }

    
    /// Deletes the file from the project directory if it exists.
    /// - Parameters:
    ///   - name: The name of the resource.
    ///   - ext: The extension of the resource.
    func delete(resource name: String, withExtension ext: String? = nil) throws {
        let fileURL = try url(forResource: name, withExtension: ext).absoluteURL
        try fileManager.removeItem(at: fileURL)
    }
}
