# Windows Image Tools
PowerShell Module for deploying windows to VHDX or Phisical Disk

## Synopsis
This module provides tools to quickly convert a WIM into bookable VHD(x) and Create fully updated WIM/VHD(x)

## Description
Creating Patched Images or just a baseline VHDX from a CD has in the past required MDT to deploy to a machine, patch and then capture the images.

Using MDT is time consuming. Converting the WIM directly to a VHDX is more efficient.

In the past this was accomplished with Convert-WindowsImage.ps1 https://gallery.technet.microsoft.com/scriptcenter/Convert-WindowsImageps1-0fe23a8f

While that is a great tool, I found it had many shortcomings
* It's one huge file (as single purpose PowerShell script go)
* It's buggy (Most of them have been fixed recently)
* It's not a Module (This being my biggest gripe)


Jeffrey Hicks wrote two great articles on the process of creating a Gen2 VHDX and populating it from a WIM
* http://www.altaro.com/hyper-v/creating-generation-2-disk-powershell/
* http://www.altaro.com/hyper-v/customizing-generation-2-vhdx/

And Benjamin Armstrong created a script for creating patched vhdx files
* https://blogs.msdn.microsoft.com/virtual_pc_guy/2015/06/16/script-image-factory-for-hyper-v/

These are the starting point for this module.

### Requirements
This should work on a base install of Windows client or server. (tested on Windows 10)
It's recommended to have the Hyper-V PowerShell tools installed.
* Microsoft-Hyper-V-Management-PowerShell
On windows 10 the There are two features recommended
* Microsoft-Hyper-V-Services
* Microsoft-Hyper-V-Management-PowerShell

## Functions (I'm bad a naming, so I'm open to better names)

```
NAME
    Convert-Wim2VHD

SYNOPSIS
    Create a VHDX and populate it from a WIM


SYNTAX
    Convert-Wim2VHD [-Path] <String> [-Size <Int64>] [-Dynamic] -DiskLayout
    <String> [-RecoveryTools] [-RecoveryImage] [-force] [-SourcePath] <String>
    [-Index <Int32>] [-Unattend <String>] [-NativeBoot] [-Feature <String[]>]
    [-RemoveFeature <String[]>] [-FeatureSource <String>] [-FeatureSourceIndex
    <Int32>] [-Driver <String[]>] [-AddPayloadForRemovedFeature] [-Package
    <String[]>] [-filesToInject <String[]>] [-WhatIf] [-Confirm]
    [<CommonParameters>]


DESCRIPTION
    This command will create a VHD or VHDX formated for UEFI (Gen 2/GPT) or
    BIOS (Gen 1/MBR)
    You must supply the path to the VHD/VHDX file and a valid WIM/ISO. You
    should also
    include the index number for the Windows Edition to install.
```

```
NAME
    New-UnattendXml

SYNOPSIS
    Create a new Unattend.xml


SYNTAX
    New-UnattendXml [-AdminCredential] <PSCredential> [-UserAccount
    <PSCredential[]>] [-Path <String>] [-LogonCount <Int32>] [-ComputerName
    <String>] [-FirstLogonScriptPath <String>] [-ProductKey <String>]
    [-TimeZone <String>] [-InputLocale <String>] [-SystemLocale <String>]
    [-UserLocale <String>] [-UILanguage <String>] [-RegisteredOwner <String>]
    [-RegisteredOrganization <String>] [-enableAdministrator] [-WhatIf]
    [-Confirm] [<CommonParameters>]

    New-UnattendXml [-AdminCredential] <PSCredential> [-UserAccount
    <PSCredential[]>] [-Path <String>] [-LogonCount <Int32>] [-ComputerName
    <String>] [-FirstBootScriptPath <String>] [-ProductKey <String>]
    [-TimeZone <String>] [-InputLocale <String>] [-SystemLocale <String>]
    [-UserLocale <String>] [-UILanguage <String>] [-RegisteredOwner <String>]
    [-RegisteredOrganization <String>] [-enableAdministrator] [-WhatIf]
    [-Confirm] [<CommonParameters>]

    New-UnattendXml [-AdminCredential] <PSCredential> [-UserAccount
    <PSCredential[]>] [-Path <String>] [-LogonCount <Int32>] [-ComputerName
    <String>] [-ProductKey <String>] [-TimeZone <String>] [-InputLocale
    <String>] [-SystemLocale <String>] [-UserLocale <String>] [-UILanguage
    <String>] [-RegisteredOwner <String>] [-RegisteredOrganization <String>]
    [-FirstBootExecuteCommand <Hashtable[]>] [-FirstLogonExecuteCommand
    <Hashtable[]>] [-EveryLogonExecuteCommand <Hashtable[]>]
    [-enableAdministrator] [-WhatIf] [-Confirm] [<CommonParameters>]


DESCRIPTION
    This Command Creates a new Unattend.xml that skips any prompts, and sets
    the administrator password
    Has options for: Adding user accounts
    Auto logon a set number of times
    Set the Computer Name
    First Boot or First Logon powersrhell script
    Product Key
    TimeZone
    Input, System and User Locals
    UI Language
    Registered Owner and Orginization
    First Boot, First Logon and Every Logon Commands
    Enable Administrator account without autologon (client OS)

    If no Path is provided a the file will be created in a temp folder and the
    path returned.
```
