//
//  FileManager+RandomTemporaryDirectory.swift
//  ThunderboltFirmwareQuery
//
//  Created by FireWolf on 2/23/20.
//  Copyright © 2020 FireWolf. All rights reserved.
//

import Foundation

public extension FileManager
{
    /// Create a random directory under the temporary directory and return the URL
    func randomTemporaryDirectory() throws -> URL
    {
        let folder = self.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true, attributes: nil)
        
        return folder
    }
}
