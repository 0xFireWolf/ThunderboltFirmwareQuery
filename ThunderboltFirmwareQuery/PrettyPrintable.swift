//
//  PrettyPrintable.swift
//  ThunderboltFirmwareQuery
//
//  Created by FireWolf on 2/23/20.
//  Copyright © 2020 FireWolf. All rights reserved.
//

import Foundation

/// A type that is capable of producing well-formatted output
public protocol PrettyPrintable
{
    func dump(to writer: IndentingWriter)
}
