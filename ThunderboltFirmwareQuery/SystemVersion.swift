//
//  SystemVersion.swift
//  ThunderboltFirmwareQuery
//
//  Created by FireWolf on 2/23/20.
//  Copyright © 2020 FireWolf. All rights reserved.
//

import Foundation

/// Represents the system version
public struct SystemVersion: Hashable, Comparable
{
    /// Represents the major version [10].12.5
    public let major: Int
    
    /// Represents the minor version 10.[12].5
    public let minor: Int
    
    /// Represents the patch version 10.12.[5]
    public let patch: Int
    
    /// Represents the full version string "10.12.5"
    public let version: String
    
    /// Represents the build version string "16F73"
    public let buildVersion: String
    
    /// Initialize from the version and build version string
    public init?(version: String, buildVersion: String)
    {
        let tokens = version.split(separator: ".")
        
        switch tokens.count
        {
        case 2:
            self.patch = 0
            
        case 3:
            self.patch = Int(tokens[2])!
            
        default:
            return nil
        }
        
        self.major = Int(tokens[0])!
        
        self.minor = Int(tokens[1])!
        
        self.version = version
        
        self.buildVersion = buildVersion
    }
    
    /// Initialize from the on-disk SystemVersion.plist file
    /// - Parameter plistFile: File URL to the `SystemVersion.plist` file
    public init?(plistFile url: URL)
    {
        guard let info = NSDictionary(contentsOf: url),
              let version = info.value(forKey: "ProductVersion") as? String,
              let buildVersion = info.value(forKey: "ProductBuildVersion") as? String else
        {
            return nil
        }
        
        self.init(version: version, buildVersion: buildVersion)
    }
    
    /// Initialize from a system volume
    /// - Parameter url: The mount point of a system volume
    public init?(mountPoint url: URL)
    {
        self.init(plistFile: url.appendingPathComponent("/System/Library/CoreServices/SystemVersion.plist"))
    }
    
    // "macOS Sierra"
    public func getOSName() -> String
    {
        switch self.minor
        {
        case 0:
            return "Mac OS X Cheetah"
            
        case 1:
            return "Mac OS X Puma"
            
        case 2:
            return "Mac OS X Jaguar"
            
        case 3:
            return "Mac OS X Panther"
            
        case 4:
            return "Mac OS X Tiger"
            
        case 5:
            return "Mac OS X Leopard"
            
        case 6:
            return "Mac OS X Snow Leopard"
            
        case 7:
            return "Mac OS X Lion"
            
        case 8:
            return "OS X Mountain Lion"
            
        case 9:
            return "OS X Mavericks"
            
        case 10:
            return "OS X Yosemite"
            
        case 11:
            return "OS X El Capitan"
            
        case 12:
            return "macOS Sierra"
            
        case 13:
            return "macOS High Sierra"
            
        case 14:
            return "macOS Mojave"
            
        case 15:
            return "macOS Catalina"
            
        default:
            return "macOS 10.\(minor)"
        }
    }
    
    // "macOS Sierra 10.12.5 (16F73)"
    public func getOSVersionString() -> String
    {
        return "\(self.getOSName()) \(self.version) (\(self.buildVersion))"
    }
    
    // "10.12.5 (16F73)"
    public func getOSVersionShortString() -> String
    {
        return "\(self.version) (\(self.buildVersion))"
    }
    
    // Example: "%@_%@"
    public func getOSVersionShortString(format: String) -> String
    {
        return String.init(format: format, self.version, self.buildVersion)
    }
    
    private func getNumericVersion() -> Int
    {
        return self.major * 1000 + self.minor * 10 + self.patch
    }
    
    public static func < (lhs: SystemVersion, rhs: SystemVersion) -> Bool
    {
        if lhs.getNumericVersion() < rhs.getNumericVersion()
        {
            return true
        }
        
        if lhs.buildVersion.count < rhs.buildVersion.count
        {
            return true
        }
        
        return lhs.buildVersion < rhs.buildVersion
    }
}
