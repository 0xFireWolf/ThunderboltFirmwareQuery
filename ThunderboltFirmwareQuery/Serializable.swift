//
//  Serializable.swift
//  WWWolfMagic
//
//  Created by FireWolf on 27/07/2017.
//  Revised by FireWolf on 10/04/2018.
//  Copyright © 2017 FireWolf. All rights reserved.
//

import Foundation

public enum SerializableError: Error
{
    case failedToEncode
}

/// Represents a type that can be encoded to and decoded from raw data
public protocol Serializable
{
    // MARK:- Encoding a serializable object
    
    /// Encode `self` into data
    ///
    /// - Returns: The encoded data on success, `nil` otherwise.
    func encode() -> Data?
    
    /// **(Convenient)** Encode `self` into a file
    ///
    /// - Parameter file: Save `self` to the `file` path
    /// - Throws: An error if failed to encode `self` or store the encoded data.
    func encode(to file: String) throws
    
    /// **(Convenient)** Encode `self` into a file
    ///
    /// - Parameter url: Save `self` to the given `url`
    /// - Throws: An error if failed to encode `self` or store the encoded data.
    func encode(to url: URL) throws
    
    // MARK:- Decoding a serializable object from data
    
    /// Decode from the given data
    ///
    /// - Parameter data: The encoded data
    /// - Returns: An instance on success, `nil` otherwise.
    static func decode(from data: Data) -> Self?
    
    /// **(Convenient)** Decode from the given file
    ///
    /// - Parameter file: A file path to the encoded data
    /// - Returns: An instance on success, `nil` otherwise.
    static func decode(from file: String) -> Self?
    
    /// **(Convenient)** Decode from the given url
    ///
    /// - Parameter url: A url to the encoded data
    /// - Returns: An instance on success, `nil` otherwise.
    static func decode(from url: URL) -> Self?
    
    /// **(Convenient)** Decode from a bundle resource
    ///
    /// - Parameter name: The resource file name
    /// - Returns: An instance on success, `nil` otherwise.
    static func decode(fromBundleResource name: String) -> Self?
}

// MARK:- Default implementation to encode `self` into a file
public extension Serializable
{
    /// Default implementation to encode `self` into a file
    func encode(to file: String) throws
    {
        return try self.encode(to: URL(fileURLWithPath: file))
    }
    
    /// Default implementation to encode `self` into a file
    func encode(to url: URL) throws
    {
        guard let data = self.encode() else
        {
            throw SerializableError.failedToEncode
        }
        
        try data.write(to: url)
    }
}

// MARK:- Default implementation to decode from the given file
public extension Serializable
{
    /// Default implementation to decode from the given file
    static func decode(from file: String) -> Self?
    {
        return self.decode(from: URL(fileURLWithPath: file))
    }
    
    /// Default implementation to decode from the given url
    static func decode(from url: URL) -> Self?
    {
        guard let data = try? Data(contentsOf: url) else
        {
            return nil
        }
        
        return self.decode(from: data)
    }
    
    /// Default implementation to decode from a bundle resource
    static func decode(fromBundleResource name: String) -> Self?
    {
        guard let url = Bundle.main.resourceURL?.appendingPathComponent(name) else
        {
            return nil
        }
        
        return self.decode(from: url)
    }
}
