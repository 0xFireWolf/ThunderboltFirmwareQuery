# ThunderboltFirmwareQuery
## >> Introduction 
`ThunderboltFirewareQuery` is a command line tool written in Swift to query Thunderbolt 3 firmwares information from macOS installers and build a centralized firmware database.

## >> Key Features
- Query firmwares information from macOS installers.
- Query firmwares information from disk images that contain macOS installers.
- Extract firmwares from macOS installers.
- Build and update the firmware database.
- Generate a markdown document for the firmware database.

## >> Usage
- `ThunderboltFirmwareQuery --query <installer1> <installer2> ...`  
    Query the Thunderbolt 3 firmware information from the given installers.  
    `<installer*>` is a file path to an macOS installer downloaded from Mac App Store.

- `ThunderboltFirmwareQuery --output <folder> --query <installer1> <installer2> ...`  
    Query the Thunderbolt 3 firmware information and save firmwares to the given `<folder>`.

- `ThunderboltFirmwareQuery --dmg --query <installerDiskImage1> ...`  
    Specify that the given files are disk images that contain one or more macOS installers.

- `ThunderboltFirmwareQuery --database <path>`  
    Create an empty database at the given path. The database is a property list file.

- `ThunderboltFirmwareQuery --database <path> --query <installer1> ...`  
    Query the Thunderbolt 3 firmware information and save the results to the given database.

- `ThunderboltFirmwareQuery --database <path> --markdown <path>`  
    Generate the Markdown document from the given database.  

## >> Thunderbolt 3 Firmware Database
An online database in multiple formats can be found in this repo.  

- Property List: [Thunderbolt3FirmwareDatabase.plist](ThunderboltFirmwares/Thunderbolt3FirmwareDatabase.plist)
- Markdown Docs: [Thunderbolt3FirmwareDatabase.md](ThunderboltFirmwares/Thunderbolt3FirmwareDatabase.md)
- HTML Page: [Thunderbolt3FirmwareDatabase.html](https://www.firewolf.science/static/articles/tbt3/Thunderbolt3FirmwareDatabase.html)  

Firmwares extracted from macOS installers are provided by this repo for research purposes only.

## >> Update Logs
- Version 1.0 @ 2020.03.04
    Initial public release.

## >> License
`ThunderboltFirmwareQuery` tool is licensed under MIT.  
Copyright (C) 2020 FireWolf @ FireWolf Pl. All rights reserved.