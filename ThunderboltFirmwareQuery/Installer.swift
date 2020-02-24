//
//  Installer.swift
//  ThunderboltFirmwareQuery
//
//  Created by FireWolf on 2/23/20.
//  Copyright © 2020 FireWolf. All rights reserved.
//

import Foundation

/// Represents an macOS installer
public struct Installer
{
    /// The installer version
    public let version: SystemVersion
    
    /// File path to the installer app
    public let url: URL
    
    /// Initialize the installer
    private init(version: SystemVersion, installer url: URL)
    {
        self.version = version

        self.url = url
    }
    
    /// Initialize the installer from an URL
    /// - Parameter url: File URL to the installer app
    public init?(app url: URL)
    {
        // Guard: InstallESD.dmg must exist
        let esdURL = url.appendingPathComponent("Contents/SharedSupport/InstallESD.dmg")
        
        guard FileManager.default.fileExists(atPath: esdURL.path) else
        {
            print("Error: Cannot find the InstallESD.dmg")
            
            return nil
        }
        
        // Attempt to read the installer version
        if let version = Installer.getSystemVersion(fromBaseSystem: url.appendingPathComponent("Contents/SharedSupport/BaseSystem.dmg"))
        {
            self.init(version: version, installer: url)
            
            return
        }
        else
        {
            print(" Info: Cannot locate BaseSystem.dmg under SharedSupport.")
            
            print(" Info: Will try to find it under InstallESD.dmg.")
        }
        
        // Cannot find the BaseSystem.dmg under SharedSupport
        // BaseSystem.dmg is stored in InstallESD.dmg prior to macOS 10.13
        guard let version = Installer.getSystemVersion(fromInstallESD: esdURL) else
        {
            print("Failed to find the installer version.")
            
            return nil
        }
        
        self.init(version: version, installer: url)
    }
    
    /// [Convenient] Mount the InstallESD.dmg at the given mount point
    /// - Parameter mountPoint: File URL to the mount point
    public func mountInstallESD(at mountPoint: URL) -> Bool
    {
        return DiskImageMounter.attach(diskImage: url.appendingPathComponent("Contents/SharedSupport/InstallESD.dmg"), at: mountPoint)
    }
    
    /// [Convenient] Retrieve the system version from the given BaseSystem.dmg
    /// - Parameter image: File URL to the BaseSystem.dmg file
    private static func getSystemVersion(fromBaseSystem image: URL) -> SystemVersion?
    {
        // Guard: Check whether the given image exists
        guard FileManager.default.fileExists(atPath: image.path) else
        {
            print("Error: The given image does not exist.")
            
            return nil
        }
        
        // Guard: Generate a random mount point at the temporary directory
        guard let mountPoint = try? FileManager.default.randomTemporaryDirectory() else
        {
            print("Error: Failed to create a random temporary mount point.")
            
            return nil
        }
        
        // Guard: Mount the BaseSystem.dmg
        guard DiskImageMounter.attach(diskImage: image, at: mountPoint) else
        {
            print("Error: Failed to mount the BaseSystem.dmg.")
            
            return nil
        }
        
        // Parse the installer version
        let version = SystemVersion(mountPoint: mountPoint)
        
        // Cleanup: Unmount the BaseSystem.dmg
        if !DiskImageMounter.detach(mountPoint: mountPoint)
        {
            print("Warning: Failed to unmount the BaseSystem.dmg. You could ignore this.")
        }
        
        return version
    }
    
    /// [Convenient] Retrieve the system version from the given InstallESD.dmg
    private static func getSystemVersion(fromInstallESD image: URL) -> SystemVersion?
    {
        // Guard: Generate a random mount point at the temporary directory
        guard let mountPoint = try? FileManager.default.randomTemporaryDirectory() else
        {
            print("Error: Failed to create a random temporary mount point.")
            
            return nil
        }
        
        // Guard: Mount the InstallESD.dmg
        guard DiskImageMounter.attach(diskImage: image, at: mountPoint) else
        {
            print("Error: Failed to mount the InstallESD.dmg.")
            
            return nil
        }
        
        // Read the installer version from the nested BaseSystem.dmg
        let version = self.getSystemVersion(fromBaseSystem: mountPoint.appendingPathComponent("BaseSystem.dmg"))
        
        // Unmount the InstallESD.dmg
        if !DiskImageMounter.detach(mountPoint: mountPoint)
        {
            print("Warning: Failed to unmount the InstallESD.dmg.")
        }
        
        return version
    }
}
