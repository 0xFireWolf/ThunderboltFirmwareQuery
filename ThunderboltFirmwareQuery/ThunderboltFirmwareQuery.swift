//
//  ThunderboltFirmwareQuery.swift
//  ThunderboltFirmwareQuery
//
//  Created by FireWolf on 2/23/20.
//  Copyright © 2020 FireWolf. All rights reserved.
//

import Foundation

/// Represents a firmware query
public struct ThunderboltFirmwareQuery
{
    /// Supported query options
    public struct Option
    {
        /// Set to `true` to save the firmwares as well
        public let shouldSaveFirmwareFiles: Bool
        
        /// URL to the directory to save the firmwares
        public let outputDirectory: URL?
    }
    
    /// Represents the query result
    public struct Result: PrettyPrintable
    {
        /// Installer version
        public let version: SystemVersion
        
        /// Thunderbolt firmware records in this installer
        public let records: ThunderboltFirmwareRecord
        
        /// Pretty Printable IMP
        public func dump(to writer: IndentingWriter)
        {
            writer.println("- \(version.getOSVersionString())")
            
            writer.indent()
            
            records.dump(to: writer)
            
            writer.outdent()
        }
    }
    
    /// The macOS installer of interest
    private let installer: Installer
    
    /// The disk image that this query depends on
    /// `nil` if the query does not rely on the container disk image
    private let diskImage: URL?
    
    /// Reference counter for queries that depend on an disk image
    /// When the reference reaches 0, the disk image will be ejected.
    /// The key is the file URL to the disk image
    /// The value is the mount point and
    private static var diskImageRefs = [URL : (URL, Int)]()
    
    /// Retain a disk image due to another query that depends on it
    /// - Parameters:
    ///   - fileURL: Path URL to the disk image
    ///   - mountPoint: The mount point
    private static func retainDiskImage(fileURL: URL, mountPoint: URL)
    {
        // Check whether the disk image is already tracked by the reference counter
        if ThunderboltFirmwareQuery.diskImageRefs[fileURL] != nil
        {
            ThunderboltFirmwareQuery.diskImageRefs[fileURL]!.1 += 1
        }
        else
        {
            ThunderboltFirmwareQuery.diskImageRefs[fileURL] = (mountPoint, 1)
        }
    }
    
    /// Release a disk image due to a query that depends on it has finished
    /// - Parameter fileURL: Path URL to the disk image
    private static func releaseDiskImage(fileURL: URL)
    {
        // Guard: The given URL must be in the map
        guard let counter = ThunderboltFirmwareQuery.diskImageRefs[fileURL] else
        {
            fatalError("The given file URL is not tracked by the reference counter.")
        }
        
        // Check whether the disk image could be ejected
        if counter.1 == 1
        {
            if !DiskImageMounter.detach(mountPoint: counter.0)
            {
                print("Warning: Failed to eject the disk image mounted at \(counter.0.path)")
            }
        }
        else
        {
            ThunderboltFirmwareQuery.diskImageRefs[fileURL]!.1 -= 1
        }
    }
    
    /// Create a query on the installer at the given URL
    /// - Parameter installer: File URL to the installer app
    public static func createQuery(onInstaller url: URL, diskImage: URL? = nil) -> ThunderboltFirmwareQuery?
    {
        guard let installer = Installer(app: url) else
        {
            print("Error: Failed to create the query. Installer at \(url.path) might not be valid.")
            
            return nil
        }
        
        return ThunderboltFirmwareQuery(installer: installer, diskImage: diskImage)
    }
    
    /// Create queries on the given installer disk image
    /// - Parameter url: File URL to the disk image that contains one or more installer apps
    public static func createQueries(onInstallerDiskImage url: URL) -> [ThunderboltFirmwareQuery]
    {
        guard let mountPoint = try? FileManager.default.randomTemporaryDirectory() else
        {
            print("Error: Failed to create a random mount point directory.")
            
            return []
        }
        
        guard DiskImageMounter.attach(diskImage: url, at: mountPoint) else
        {
            print("Error: Failed to mount the given installer disk image \(url.path).")
            
            return []
        }
        
        // The given disk image might contain multiple installer apps
        // Enumerate all installer apps
        guard let contents = try? FileManager.default.contentsOfDirectory(at: mountPoint, includingPropertiesForKeys: nil, options: .skipsHiddenFiles) else
        {
            print("Error: Failed to enumerate the disk image contents.")
            
            return []
        }
        
        return contents.filter({ $0.pathExtension == "app" }).filter({ $0.lastPathComponent.starts(with: "Install") }).compactMap()
        {
            installer -> ThunderboltFirmwareQuery? in
            
            guard let query = ThunderboltFirmwareQuery.createQuery(onInstaller: installer, diskImage: url) else
            {
                return nil
            }
            
            ThunderboltFirmwareQuery.retainDiskImage(fileURL: url, mountPoint: mountPoint)
            
            return query
        }
    }
    
    /// Perform the query with options
    /// - Parameter option: Contains additional query options
    public func `do`(option: Option) -> Result?
    {
        print("===================================================================================")
        
        print(" Info: Installer: \(self.installer.url.path)")
        
        print(" Info: Start to query Thunderbolt firmware on \(installer.version.getOSVersionString()) installer.")
        
        print(" Info: - Option: Save Firmwares: \(option.shouldSaveFirmwareFiles ? "Yes" : "No")")
        
        print(" Info: - Option: Save Directory: \(option.outputDirectory?.path ?? "None")")
        
        let outputDirectory = option.outputDirectory?.appendingPathComponent(self.installer.version.getOSVersionShortString(format: "%@_%@"))
        
        // Create the version directory under the given output directory
        if (option.shouldSaveFirmwareFiles)
        {
            do
            {
                try FileManager.default.createDirectory(at: outputDirectory!, withIntermediateDirectories: true, attributes: nil)
            }
            catch
            {
                print("Error: Failed to create the version directory under the given output directory: \(error.localizedDescription)")
                
                return nil
            }
        }
        
        // Mount the InstallESD.dmg
        guard let mountPoint = try? FileManager.default.randomTemporaryDirectory() else
        {
            print("Error: Failed to create the random mount point directory.")
            
            return nil
        }
            
        print(" Info: Mounting the InstallESD.dmg...")
        
        guard self.installer.mountInstallESD(at: mountPoint) else
        {
            print("Error: Failed to mount the InstallESD.dmg.")
            
            return nil
        }
        
        print(" Info: InstallESD.dmg has been mounted successfully.")
        
        // Locate the FirmwareUpdate.pkg
        let firmwareUpdatePkg = mountPoint.appendingPathComponent("Packages/FirmwareUpdate.pkg")
        
        guard FileManager.default.fileExists(atPath: firmwareUpdatePkg.path) else
        {
            print("Error: Cannot find the FirmwareUpdate.pkg in the InstallESD.dmg.")
            
            return nil
        }
        
        print(" Info: Found FirmwareUpdate.pkg. Extracting the package...")
        
        // Expand the FirmwareUpdate.pkg
        let workingDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        
        let pkgutil = Process.launchedProcess(launchPath: "/usr/sbin/pkgutil", arguments: ["--expand-full", firmwareUpdatePkg.path, workingDirectory.path])
        
        pkgutil.waitUntilExit()
        
        guard pkgutil.terminationStatus == 0 else
        {
            print("Error: Failed to expand the FirmwareUpdate.pkg. Return value of pkgutil is \(pkgutil.terminationStatus).")
            
            return nil
        }
        
        print(" Info: FirmwareUpdate.pkg has been extracted successfully.")
        
        // Locate the USBCUpdater directory
        guard let contents = try? FileManager.default.contentsOfDirectory(at: workingDirectory.appendingPathComponent("Scripts/Tools/USBCUpdater"), includingPropertiesForKeys: nil, options: .skipsHiddenFiles) else
        {
            print("Error: Failed to locate the USBCUpdater directory.")
            
            return nil
        }
        
        let machines = contents.filter({ $0.lastPathComponent.starts(with: "Mac-") })
        
        print(" Info: Found \(machines.count) board ids in the USBCUpdater folder.")
        
        // Gather firmware records
        var records = [String : ThunderboltFirmwareConfig]()
        
        for (index, machine) in machines.enumerated()
        {
            let boardID = machine.lastPathComponent
            
            print(" Info: [\(index + 1)/\(machines.count)] Gathering Thunderbolt firmware info of \(boardID)...")
            
            // Parse the firmware configs
            if let config = ThunderboltFirmwareConfig(config: machine.appendingPathComponent("Config.plist"))
            {
                records[boardID] = config
                
                // Check whether firmware files should be saved
                if option.shouldSaveFirmwareFiles
                {
                    do
                    {
                        try FileManager.default.copyItem(at: machine, to: outputDirectory!.appendingPathComponent(boardID))
                    }
                    catch
                    {
                        print("Error: Failed to copy the firmwares to the output directory: \(error.localizedDescription); Will ignore this one.")
                    }
                }
            }
            else
            {
                print("Error: Failed to parse the config for machine \(boardID). Will ignore this one.")
            }
        }
        
        // Cleanup: Unmount the InstallESD.dmg
        print(" Info: Unmounting the InstallESD.dmg...")
        
        if !DiskImageMounter.detach(mountPoint: mountPoint)
        {
            print("Warning: Failed to unmount the InstallESD.dmg.")
        }
        
        print(" Info: InstallESD.dmg has been unmounted.")
        
        // Cleanup: Check whether the container disk image should be ejected
        if let diskImage = self.diskImage
        {
            ThunderboltFirmwareQuery.releaseDiskImage(fileURL: diskImage)
        }
        
        return Result(version: self.installer.version, records: records)
    }
}
