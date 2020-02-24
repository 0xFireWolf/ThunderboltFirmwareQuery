//
//  main.swift
//  ThunderboltFirmwareQuery
//
//  Created by FireWolf on 2/23/20.
//  Copyright © 2020 FireWolf. All rights reserved.
//

import Foundation

let version = "1.0"
let date = "2020.02.24"

func usage()
{
    print("Usage: ThunderboltFirmwareQuery [COMMANDS] file1 file2 ...\n")
    
    print("Available (Optional) Commands:\n")
    
    print("    --help             Print this usage guide.")
    print("    --version          Print the current version")
    print("    --database <path>  Specify the firmware database file.")
    print("    --markdown <path>  Generate the Markdown from the database.")
    print("    --dmg              Specify that input files are disk images that contain installer apps.")
    print("    --query            Query the Thunderbolt firmware info from the given file(s).")
    print("                       When --database is specified, the query result is added to the database.")
    print("                       When --overwrite is specified, the query result overwrites the conflicted one.")
    print("                       When --output <path> is specified, firmwares are copied to the given <path>.")
    print("                       Note that --query must be the very last option.")
    print("                       Arguments right after --query are treated as installer apps or disk images.")
    
    print("\nDefault usage:")
    
    print("    Commands: Query --query <installer1> <installer2> ...")
    print(" Description: installer* is a file path to an macOS installer downloaded from Mac App Store.")
    print("              Query the Thunderbolt firmware info from the installer and print it to stdout.")
    
    print("\nUsage Examples:")
    
    print("    Commands: Query --output <path> --query <installer1> <installer2> ...")
    print(" Description: Query the Thunderbolt firmware info and save firmwares to the given <path>.\n")
    
    print("    Commands: Query --dmg --query <installerDiskImage1> ...")
    print(" Description: installerDiskImage* is a file path to a disk image that contains one or more installers.")
    print("              Query the Thunderbolt firmware info from installers and print them to stdout.\n")
    
    print("    Commands: Query --database <path>")
    print(" Description: Create an empty database at the given path.\n")
    
    print("    Commands: Query --database <path> --query <installer1> ...")
    print(" Description: Query the Thunderbolt firmware info from installers and save the results to the given database.\n")
    
    print("    Commands: Query --database <path> --markdown <path>")
    print(" Description: Generate the Markdown document from the given database.\n")
}

// Parse command line arguments

guard CommandLine.arguments.count > 1 else
{
    usage()
    
    exit(-1)
}

if CommandLine.arguments.contains("--help")
{
    usage()
    
    exit(0)
}

if CommandLine.arguments.contains("--version")
{
    print("Version: \(version) @ \(date)")
    
    exit(0)
}

let isDiskImage = CommandLine.arguments.contains("--dmg")

let overwrite = CommandLine.arguments.contains("--overwrite")

var dburl: URL? = nil

var output: URL? = nil

if let index = CommandLine.arguments.firstIndex(of: "--database")
{
    dburl = URL(fileURLWithPath: CommandLine.arguments[index + 1])
    
    // Create an empty database
    if CommandLine.arguments.count == 3
    {
        do
        {
            try ThunderboltFirmwareDatabase.empty().save(to: dburl!)
            
            print(" Info: An empty database is created at \(dburl!.path).")
            
            exit(0)
        }
        catch
        {
            print("Error: Failed to create an empty database at \(dburl!.path): \(error.localizedDescription)")
            
            exit(-1)
        }
    }
    
    // Generate a Markdown document from the given database
    if CommandLine.arguments.count == 5, let mindex = CommandLine.arguments.firstIndex(of: "--markdown")
    {
        guard let db = ThunderboltFirmwareDatabase.load(from: dburl!) else
        {
            print("Error: Failed to load the database from \(dburl!.path).")
            
            exit(-1)
        }
        
        do
        {
            try db.generateMarkdown(to: URL(fileURLWithPath: CommandLine.arguments[mindex + 1]))
            
            print(" Info: The Markdown document has been generated from the database.")
            
            exit(0)
        }
        catch
        {
            print("Error: Failed to generate the Markdown document from the database.")
            
            exit(-1)
        }
    }
}

if let index = CommandLine.arguments.firstIndex(of: "--output")
{
    output = URL(fileURLWithPath: CommandLine.arguments[index + 1])
}

// Guard: --query must be present at this point
guard let index = CommandLine.arguments.firstIndex(of: "--query") else
{
    usage()
    
    exit(-1)
}

// Create the option and queries
let option = ThunderboltFirmwareQuery.Option(shouldSaveFirmwareFiles: output != nil, outputDirectory: output)

let files = CommandLine.arguments[(index + 1)...]

// Create and perform the query
let results = files.map({ URL(fileURLWithPath: $0) }).flatMap()
{
    file -> [ThunderboltFirmwareQuery] in
    
    if isDiskImage
    {
        return ThunderboltFirmwareQuery.createQueries(onInstallerDiskImage: file)
    }
    
    guard let query = ThunderboltFirmwareQuery.createQuery(onInstaller: file) else
    {
        return []
    }
    
    return [query]
}
.compactMap({ $0.do(option: option) })
    
// Add the result into the database if necessary
guard let dburl = dburl else
{
    // Print the result to stdout
    let writer = StringWriter()
    
    results.forEach({ $0.dump(to: writer) })
    
    print(writer.toString())
    
    exit(0)
}

// Load the database from the disk
guard let database = ThunderboltFirmwareDatabase.load(from: dburl) else
{
    print("Failed to load the database. Will discard the query result.")
    
    exit(-1)
}

// Save the result to the database
results.forEach({ database.register(records: $0.records, for: $0.version.getOSVersionShortString(format: "%@_%@"), overwrite: overwrite) })

// Write the new database back to the disk
do
{
    try database.save(to: dburl)
    
    print(" Info: The new database has been saved to \(dburl.path)")
}
catch
{
    print("Error: Failed to save the new database to \(dburl.path)")
    
    exit(-1)
}
