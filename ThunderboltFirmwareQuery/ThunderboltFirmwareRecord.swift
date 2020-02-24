//
//  ThunderboltFirmwareRecord.swift
//  ThunderboltFirmwareQuery
//
//  Created by FireWolf on 2/23/20.
//  Copyright © 2020 FireWolf. All rights reserved.
//

import Foundation

/// The board-id type
public typealias BoardID = String

public typealias ThunderboltFirmwareRecord = [BoardID : ThunderboltFirmwareConfig]

extension Dictionary: PrettyPrintable where Key == BoardID, Value == ThunderboltFirmwareConfig
{
    public func dump(to writer: IndentingWriter)
    {
        for (id, config) in self
        {
            writer.println("- Board ID: \(id)")
            
            writer.indent()
            
            config.dump(to: writer)
            
            writer.outdent()
        }
    }
}
