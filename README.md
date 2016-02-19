# GenTwoImageTools
PowerShell Tools for Generation 2 Images

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
    Add-UpdateImage
    
SYNOPSIS
    Add a Windows Image to a Windows Image Tools Update Directory
    
    
SYNTAX
    Add-UpdateImage -Path <Object> -FriendlyName <String> -AdminCredential 
    <PSCredential> [-ProductKey <String>] [-Size <UInt64>] [-Dynamic] -DiskLayout 
    <String> [-SourcePath] <String> [-Index <Int32>] [-AddPayloadForRemovedFeature] 
    [-Feature <String[]>] [-Driver <String[]>] [-Package <String[]>] [-filesToInject 
    <String[]>] [-force] [-WhatIf] [-Confirm] [<CommonParameters>]
    
    
DESCRIPTION
    This command will convert a .ISO or .WIM into a VHD populated with an unattend.xml 
    and first boot script
```

```
NAME
    Convert-Wim2VHD
    
SYNOPSIS
    Create a VHDX and populate it from a WIM
    
SYNTAX
    Convert-Wim2VHD [-Path] <String> [-Size <UInt64>] [-Dynamic] -DiskLayout <String> 
    [-RecoveryTools] [-RecoveryImage] [-force] [-SourcePath] <String> [-Index <Int32>] 
    [-Unattend <String>] [-NativeBoot] [-Feature <String[]>] [-Driver <String[]>] 
    [-AddPayloadForRemovedFeature] [-Package <String[]>] [-filesToInject <String[]>] 
    [-WhatIf] [-Confirm] [<CommonParameters>]
    
DESCRIPTION
    This command will create a VHD or VHDX formated for UEFI (Gen 2/GPT) or BIOS (Gen 
    1/MBR)
    You must supply the path to the VHD/VHDX file and a valid WIM/ISO. You should also
    include the index number for the Windows Edition to install.
```

```
NAME
    Get-UpdateConfig
    
SYNOPSIS
    Get the Windows Image Tools Update Config used for creating the temp VM
    
SYNTAX
    Get-UpdateConfig [-Path] <Object> [<CommonParameters>]
    
DESCRIPTION
    This command will Get the config used by Invoke-WindowsImageUpdate to build a VM 
    and update Windows Images
```

```
NAME
    Get-VhdPartitionStyle
    
SYNOPSIS
    Gets partition style of a VHD(x)
    
SYNTAX
    Get-VhdPartitionStyle [-vhd] <String> [<CommonParameters>]
    
DESCRIPTION
    Returns the partition Style of the provided VHD(x) ei. GPT or MBR
```

```
NAME
    Initialize-VHDPartition
    
SYNOPSIS
    Create VHD(X) with partitions needed to be bootable
    
SYNTAX
    Initialize-VHDPartition [-Path] <String> [-Size <UInt64>] [-Dynamic] -DiskLayout 
    <String> [-Passthru] [-RecoveryTools] [-RecoveryImage] [-force] [-WhatIf] 
    [-Confirm] [<CommonParameters>]
    
DESCRIPTION
    This command will create a VHD or VHDX file. Supported layours are: BIOS, UEFO or 
    WindowsToGo. 
    
    To create a recovery partitions use -RecoveryTools and -RecoveryImage
```

```
NAME
    Invoke-CreateVmRunAndWait
    
SYNOPSIS
    Create a temp vm with a random name and wait for it to stop
    
SYNTAX
    Invoke-CreateVmRunAndWait [-VhdPath] <String> [-VmGeneration] <Int32> [-VmSwitch] 
    <String> [[-vLan] <Int32>] [[-ProcessorCount] <Int32>] [[-MemoryStartupBytess] 
    <Int64>] [<CommonParameters>]
    
DESCRIPTION
    This Command quickly test changes to a VHD by creating a temporary VM and ataching 
    it to the network. VM is deleted when it enters a stoped state.
```

```
NAME
    Invoke-WindowsImageUpdate
    
SYNOPSIS
    Starts the process of applying updates to all (or selected) images in a Windows 
    Image Tools BaseImages Folder
    
SYNTAX
    Invoke-WindowsImageUpdate [-Path] <Object> [[-ImageName] <String[]>] 
    [-ReduceImageSize] [[-output] <String>] [-WhatIf] [-Confirm] [<CommonParameters>]
    
DESCRIPTION
    This Command updates all (or selected) the images created via Add-UpdateImage in a 
    Windows Image Tools BaseImages folder 
    New-WindowsImageToolsExample can be use to create the structrure
```

```
NAME
    Mount-VhdAndRunBlock
    
SYNOPSIS
    Mount a VHD(x), runs a script block and unmounts the VHD(x) driveleter stored in 
    $driveLetter
    
SYNTAX
    Mount-VhdAndRunBlock [-vhd] <String> [-block] <ScriptBlock> [-ReadOnly] 
    [<CommonParameters>]
    
DESCRIPTION
    Us this function to read / write files inside a vhd. Any objects emited by the 
    scriptblock are returned by this function.
```

```
NAME
    New-UnattendXml
    
SYNOPSIS
    Create a new Unattend.xml
    
SYNTAX
    New-UnattendXml [-AdminCredential] <PSCredential> [-UserAccount <PSCredential[]>] 
    [-Path <String>] [-LogonCount <Int32>] [-ComputerName <String>] 
    [-FirstLogonScriptPath <String>] [-ProductKey <String>] [-TimeZone <String>] 
    [-InputLocale <String>] [-SystemLocale <String>] [-UserLocale <String>] 
    [-UILanguage <String>] [-RegisteredOwner <String>] [-RegisteredOrganization 
    <String>] [-enableAdministrator] [-WhatIf] [-Confirm] [<CommonParameters>]
    
    New-UnattendXml [-AdminCredential] <PSCredential> [-UserAccount <PSCredential[]>] 
    [-Path <String>] [-LogonCount <Int32>] [-ComputerName <String>] 
    [-FirstBootScriptPath <String>] [-ProductKey <String>] [-TimeZone <String>] 
    [-InputLocale <String>] [-SystemLocale <String>] [-UserLocale <String>] 
    [-UILanguage <String>] [-RegisteredOwner <String>] [-RegisteredOrganization 
    <String>] [-enableAdministrator] [-WhatIf] [-Confirm] [<CommonParameters>]
    
    New-UnattendXml [-AdminCredential] <PSCredential> [-UserAccount <PSCredential[]>] 
    [-Path <String>] [-LogonCount <Int32>] [-ComputerName <String>] [-ProductKey 
    <String>] [-TimeZone <String>] [-InputLocale <String>] [-SystemLocale <String>] 
    [-UserLocale <String>] [-UILanguage <String>] [-RegisteredOwner <String>] 
    [-RegisteredOrganization <String>] [-FirstBootExecuteCommand <Hashtable[]>] 
    [-FirstLogonExecuteCommand <Hashtable[]>] [-EveryLogonExecuteCommand 
    <Hashtable[]>] [-enableAdministrator] [-WhatIf] [-Confirm] [<CommonParameters>]
    
DESCRIPTION
    This Command Creates a new Unattend.xml that skips any prompts, and sets the 
    administrator password
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
    
    If no Path is provided a the file will be created in a temp folder and the path 
    returned.
```

```
NAME
    New-WindowsImageToolsExample
    
SYNOPSIS
    Create folders and script examples on the use of Windows Image Tools
    
SYNTAX
    New-WindowsImageToolsExample [-Path] <String> [-WhatIf] [-Confirm] 
    [<CommonParameters>]
    
DESCRIPTION
    This Command creates the folders structures and example files needed to use 
    Windows Image Tools to auto update windows images.
```

```
NAME
    Set-UpdateConfig
    
SYNOPSIS
    Set the Windows Image Tools Update Config used for creating the temp VM
    
SYNTAX
    Set-UpdateConfig [-Path] <Object> [[-VmSwitch] <String>] [[-vLAN] <Int32>] 
    [[-IpType] <String>] [[-IpAddress] <String>] [[-SubnetMask] <Int32>] [[-Gateway] 
    <String>] [[-DnsServer] <String>] [-WhatIf] [-Confirm] [<CommonParameters>]
    
DESCRIPTION
    Set the config used by Invoke-WitUpdate to build a VM and update Windows Images
```

```
NAME
    Set-VHDPartition
    
SYNOPSIS
    Sets the content of a VHD(X) using a source WIM or ISO
    
SYNTAX
    Set-VHDPartition [-Path] <String> [-SourcePath] <String> [-Index <Int32>] 
    [-Unattend <String>] [-NativeBoot] [-AddPayloadForRemovedFeature] [-Feature 
    <String[]>] [-Driver <String[]>] [-Package <String[]>] [-filesToInject <String[]>] 
    [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]
    
DESCRIPTION
    This command will copy the content of the SourcePath ISO or WIM and populate the 
    partitions found in the VHD(X) You must supply the path to the VHD(X) file and a 
    valid WIM/ISO. You should also include the index number for the Windows Edition 
    to install. If the recovery partitions are present the source WIM will be copied 
    to the recovery partition. Optionally, you can also specify an XML file to be 
    inserted into the OS partition as unattend.xml, any Drivers, WindowsUpdate (MSU)
    or Optional Features you want installed. And any additional files to add.
    CAUTION: This command will replace the content partitions.
```

```
NAME
    Update-WindowsImageWMF
    
SYNOPSIS
    Updates WMF to 4.0, 5.0 Production Preview or 5.0 (and .NET to 4.6) in a Windows 
    Update Image
    
SYNTAX
    Update-WindowsImageWMF [-Path] <Object> [-ImageName] <String[]> [-Wmf4] [-Wmf5pp] 
    [-WhatIf] [-Confirm] [<CommonParameters>]
    
DESCRIPTION
    This Command downloads WMF 4.0, 5.0PP or 5.0 (Production Preview) and .NET 4.6 
    offline installer
    Creates a temp VM and updates .NET if needed and WMF
```
	