//
//  PropertyListSerializable.swift
//  WWWolfMagic
//
//  Created by FireWolf on 27/07/2017.
//  Revised by FireWolf on 10/04/2018.
//  Copyright © 2017 FireWolf. All rights reserved.
//

import Foundation

public extension KeyedDecodingContainer
{
    func decode<T: Decodable>(_ key: Key) throws -> T
    {
        return try self.decode(T.self, forKey: key)
    }
    
    func decode<T: Decodable>(_ key: Key, default value: T) throws -> T
    {
        return try self.decodeIfPresent(T.self, forKey: key) ?? value
    }
}

public extension PropertyListDecoder
{
    func decode<T: Decodable>(_ type: T.Type, from url: URL) -> T?
    {
        guard let data = try? Data(contentsOf: url) else
        {
            return nil
        }
        
        return try? self.decode(type, from: data)
    }
    
    func decode<T: Decodable>(bundleResource type: T.Type, named name: String) -> T?
    {
        guard let url = Bundle.main.resourceURL?.appendingPathComponent(name) else
        {
            return nil
        }
        
        return self.decode(type, from: url)
    }
}

/// Represents a type that can be encoded to and decoded from raw plist data (xml/binary plist)
public protocol PropertyListSerializable: Codable, Serializable
{
    /// Encode `self` into a plist format
    func encode() -> [String : Any]?
    
    /// Decode from the given plist dictionary
    static func decode(from plist: [String : Any]) -> Self?
}

// MARK:- Default implementation to encode `self` into plist data
public extension PropertyListSerializable
{
    /// Default implementation to encode `self` into data
    func encode() -> Data?
    {
        let encoder = PropertyListEncoder()
        
        encoder.outputFormat = .xml
        
        return try? encoder.encode(self)
    }
    
    /// Default implementation to encode `self` into a plist
    func encode() -> [String : Any]?
    {
        guard let encoded: Data = self.encode() else
        {
            return nil
        }
        
        guard let plist = try? PropertyListSerialization.propertyList(from: encoded, options: [], format: nil) else
        {
            return nil
        }
        
        return plist as? [String : Any]
    }
}

// MARK:- Default implementation to decode from the given plist data
public extension PropertyListSerializable
{
    /// Default implementation to decode from the given plist dictionary
    static func decode(from plist: [String : Any]) -> Self?
    {
        guard let data = try? PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0) else
        {
            return nil
        }
        
        return self.decode(from: data)
    }
    
    /// Default implemenation to decode from the given data
    static func decode(from data: Data) -> Self?
    {
        let decoder = PropertyListDecoder()
        
        return try? decoder.decode(self, from: data)
    }
}
