//
//  ThunderboltFirmwareConfig.swift
//  ThunderboltFirmwareQuery
//
//  Created by FireWolf on 2/23/20.
//  Copyright © 2020 FireWolf. All rights reserved.
//

import Foundation

/// Represents the updater config `Config.plist`
public struct ThunderboltFirmwareConfig: PropertyListSerializable, PrettyPrintable
{
    /// A updater config contains one or more firmware configs
    public let firmwares: [ThunderboltFirmwareInfo]
    
    /// Initialize the updater config from the `Config.plist` file
    /// - Parameter url: File URL to the `Config.plist` file
    public init?(config url: URL)
    {
        guard let dict = NSDictionary(contentsOf: url) as? [String : Any] else
        {
            print("Error: Failed to load the updater config from \(url.path)")
            
            return nil
        }
        
        // Guard: Some machines only have USB-C info
        guard let infos = dict["Thunderbolt"] as? [[String : Any]] else
        {
            print("Error: The given updater config does not contain Thunderbolt-related info.")
            
            return nil
        }
        
        self.firmwares = infos.compactMap({ ThunderboltFirmwareInfo(info: $0) })
    }
    
    /// Pretty Printable IMP
    public func dump(to writer: IndentingWriter)
    {
        for (index, firmware) in self.firmwares.enumerated()
        {
            writer.println("* Firmware \(index)")
            
            writer.indent()
            
            firmware.dump(to: writer)
            
            writer.outdent()
        }
    }
}

/// Represents the firmware info in the updater config file
/// At this moment we are only interested in the following properties
public struct ThunderboltFirmwareInfo: PropertyListSerializable, PrettyPrintable
{
    /// Firmware file name
    public let fileName: String
    
    /// Firmware version
    public let version: String
    
    /// Ridge silicon vendor ID
    public let vendorID: Int
    
    /// Ridge silicon device ID
    public let deviceID: Int
    
    /// Ridge silicon revision
    public let revision: Int
    
    /// Initialize the firmware config from a dictionary
    /// - Parameter info: A dictionary that contains the firmware info
    public init?(info: [String : Any])
    {
        guard let fileName = info["Firmware"] as? String else
        {
            print("Error: The given info dictionary does not contain the firmware file name.")
            
            return nil
        }
        
        guard let vendorID = info["Ridge Silicon Vendor ID"] as? Int else
        {
            print("Error: The given info dictionary does not contain the vendor id.")
            
            return nil
        }
        
        guard let deviceID = info["Ridge Silicon Device ID"] as? Int else
        {
            print("Error: The given info dictionary does not contain the device id.")
            
            return nil
        }
        
        guard let revision = info["Ridge Silicon Revision"] as? Int else
        {
            print("Error: The given info dictionary does not contain the revision.")
            
            return nil
        }
        
        guard let version = info["Version"] as? Double else
        {
            print("Error: The given info dictionary does not contain the version.")
            
            return nil
        }
        
        if let ridgeVersion = info["Ridge Firmware Version"] as? Double
        {
            self.version = String(ridgeVersion)
        }
        else
        {
            self.version = String(version)
        }
        
        self.fileName = fileName
        
        self.vendorID = vendorID
        
        self.deviceID = deviceID
        
        self.revision = revision
    }
    
    /// Pretty Printable IMP
    public func dump(to writer: IndentingWriter)
    {
        writer.println("- Firmware Version #: \(self.version)")
        
        writer.println("- Firmware File Name: \(self.fileName)")
        
        writer.println("- Hardware Vendor ID: 0x\(String(self.vendorID, radix: 16, uppercase: true))")
        
        writer.println("- Hardware Device ID: 0x\(String(self.deviceID, radix: 16, uppercase: true))")
        
        writer.println("- Hardware Revisions: \(self.revision)")
    }
}
