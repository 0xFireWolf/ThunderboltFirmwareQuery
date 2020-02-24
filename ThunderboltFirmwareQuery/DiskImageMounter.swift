//
//  DiskImageMounter.swift
//  ThunderboltFirmwareQuery
//
//  Created by FireWolf on 2/23/20.
//  Copyright © 2020 FireWolf. All rights reserved.
//

import Foundation

/// A naive disk image mounter
public class DiskImageMounter
{
    public static func attach(diskImage: URL, at mountPoint: URL) -> Bool
    {
        // Guard: Ensure that the given mount point exists
        if !FileManager.default.fileExists(atPath: mountPoint.path)
        {
            do
            {
                try FileManager.default.createDirectory(at: mountPoint, withIntermediateDirectories: true, attributes: nil)
            }
            catch
            {
                return false
            }
        }
        
        // Attach the disk image
        let process = Process.launchedProcess(launchPath: "/usr/bin/hdiutil", arguments: ["attach", diskImage.path, "-nobrowse", "-mountpoint", mountPoint.path, "-noverify", "-quiet"])
        
        process.waitUntilExit()
        
        return process.terminationStatus == 0
    }
    
    public static func detach(mountPoint: URL) -> Bool
    {
        let process = Process.launchedProcess(launchPath: "/usr/bin/hdiutil", arguments: ["detach", mountPoint.path, "-quiet"])
        
        process.waitUntilExit()
        
        return process.terminationStatus == 0
    }
}
