# Change Log

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## [1.9.24] Unreleased

### Fixed
  Switched to Semver : Non-SemVer version number breaks build with newer mpackage management
  Fixes Breaking bug in function to export in manifest. this rendered the module unusable

## [1.9.19.0] Released
### Added
  Initialize-DataDisk to format a phisical disk for GPT data. Microsfot recomends GPT drives all have an MSR partiion. so this does one MSR and then the rest a primary data drive.
  New-DataVhD. this is a wraper arround Initialize-DataDisk with the addition of creating and mounting a VHD(x)
  Install-WindowsFromWim contains the heavy lifting for Convert-Wim2VHD but targets drive numbers

### Changed
  Convert-Wim2HVD Added the ability to control the size of the MSR, System and Recovery drives.

### Removed
  All functions arround windows updates. The orignal purpose of the modue has evolved from 2012. The Core image now includes all but .NET35 and PowerShell 2.0. The GetLatest module can be used to aquire the latest update and Convert-Wim2VHD can inject the update. allowing for a simple pipeline of aquireing the udpate and injecting to the ISO. given less generations and a cleaner history

### Fixed
  Lost of bugs to numorus to remember
