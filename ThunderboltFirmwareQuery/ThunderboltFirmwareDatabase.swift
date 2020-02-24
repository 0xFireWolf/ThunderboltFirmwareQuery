//
//  ThunderboltFirmwareDatabase.swift
//  ThunderboltFirmwareQuery
//
//  Created by FireWolf on 2/23/20.
//  Copyright © 2020 FireWolf. All rights reserved.
//

import Foundation

/// Represents a lightweight database to store Thunderbolt firmware info
public class ThunderboltFirmwareDatabase: PrettyPrintable
{
    /// The internal serializable storage
    private struct Storage: PropertyListSerializable, PrettyPrintable
    {
        public var data: [String : [BoardID : ThunderboltFirmwareConfig]]
        
        public func dump(to writer: IndentingWriter)
        {
            // Sort the version string
            let keys = self.data.keys.compactMap { (string) -> SystemVersion? in
                
                let tokens = string.components(separatedBy: "_")
                
                guard tokens.count == 2 else
                {
                    print("Error: Found a malformed version string: \(string).")
                    
                    return nil
                }
                
                guard let version = SystemVersion.init(version: tokens[0], buildVersion: tokens[1]) else
                {
                    print("Error: Found a malformed version string: \(string).")
                    
                    return nil
                }
                
                return version
            }.sorted()
            
            writer.println("## Thunderbolt Firmware Database")
            
            for key in keys
            {
                writer.println("- \(key.getOSVersionString())")
                
                writer.indent()
                
                self.data[key.getOSVersionShortString(format: "%@_%@")]!.dump(to: writer)
                
                writer.outdent()
            }
        }
    }
    
    /// The internal storage
    private var storage: Storage
    
    /// The serial queue
    private let queue: DispatchQueue
    
    /// Initialize an empty database
    private init(storage: Storage)
    {
        self.storage = storage
        
        self.queue = DispatchQueue(label: "science.firewolf.queue.tbtdb")
    }
    
    /// Create an empty database
    public static func empty() -> ThunderboltFirmwareDatabase
    {
        return ThunderboltFirmwareDatabase(storage: Storage(data: [:]))
    }
    
    ///
    /// Load the database from the given file
    ///
    /// - Parameter file: Path URL to the on-disk database file
    /// - Returns: An instance of firmware database on success, `nil` otherwise.
    ///
    public static func load(from file: URL) -> ThunderboltFirmwareDatabase?
    {
        guard let storage = Storage.decode(from: file) else
        {
            print("Error: Failed to load the database from \(file.path)")
            
            return nil
        }
        
        return ThunderboltFirmwareDatabase(storage: storage)
    }
    
    ///
    /// Save the database to the given file
    ///
    /// - Parameter file: Path URL to a file
    ///
    public func save(to file: URL) throws
    {
        try self.storage.encode(to: file)
    }
    
    ///
    /// [Synchronously] Register records under a specific installer version
    ///
    /// - Parameters:
    ///   - records: Thunderbolt firmware configs associated with machines
    ///   - version: The installer version
    ///   - overwrite: Set to `true` to overwrite existing records if `version` is already in the current database.
    /// - Note: This method is thread-safe.
    ///
    public func register(records: [BoardID : ThunderboltFirmwareConfig], for version: String, overwrite: Bool)
    {
        self.queue.sync {
            
            // Check whether the database already contains the given version
            if self.storage.data[version] == nil
            {
                self.storage.data[version] = records
            }
            else
            {
                if overwrite
                {
                    self.storage.data[version] = records
                }
            }
        }
    }
    
    /// Pretty Printable IMP
    public func dump(to writer: IndentingWriter)
    {
        self.storage.dump(to: writer)
    }
    
    /// Generate the Markdown document
    /// - Parameter file: The document will be saved to `file`
    public func generateMarkdown(to file: URL) throws
    {
        let writer = StringWriter()
        
        self.dump(to: writer)
        
        try writer.toString().write(to: file, atomically: true, encoding: .utf8)
    }
}
