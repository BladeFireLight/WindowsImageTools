# GenTwoImageTools
PowerShell Tools for Generation 2 Images

## Synopsis
This module provides tools to quickly convert a WIM into a Gen 2 compatable UEFI bootable VHDX

## Description
Creating Patched Images or just a baseline VHDX from a CD has in the past required MDT to deploy to a machine, patch and then caputre the images.

Useing MDT is time consumeing. Converting the WIM directly to a VHDX is more efficiant.

In the past this was acomplished with Convert-WindowsImage.ps1 https://gallery.technet.microsoft.com/scriptcenter/Convert-WindowsImageps1-0fe23a8f

While that is a great tool, I found it had many shortcomings
* It's huge (as single purpose PowerShell scirpt go)
* It's buggy
* It's not a Module (This being my bigest gripe)


Jeffery Hicks wrote two great articals on the process of creating a Gen2 VHDX and populating it from a WIM
* http://www.altaro.com/hyper-v/creating-generation-2-disk-powershell/
* http://www.altaro.com/hyper-v/customizing-generation-2-vhdx/

Thease are the starting point for this module. 

## Functions (I'm bad a naming, so i'm open to better names)

### Convert-Wim2GenTwoVhdx
```NAME
    Convert-Wim2GenTwoVhdx
    
SYNOPSIS
    Create a VHDX and populate it from a WIM
    
    
SYNTAX
    Convert-Wim2GenTwoVhdx [-Path] <String> [-WIMPath] <String> [-Index <Int32>] [-Unattend <String>] [-Size 
    <UInt64>] [-Dynamic] [-BlockSizeBytes <UInt32>] [-LogicalSectorSizeBytes <UInt32>] 
    [-PhysicalSectorSizeBytes <UInt32>] [-Recovery] [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]
    
    
DESCRIPTION
    This command will update partitions for a Generate 2 VHDX file, configured for UEFI. 
    You must supply the path to the VHDX file and a valid WIM. You should also
    include the index number for the Windows Edition to install.
```

### Initialize-GenTwoBootDisk
```NAME
    Initialize-GenTwoBootDisk
    
SYNOPSIS
    Create a Generation 2 VHDX
    
    
SYNTAX
    Initialize-GenTwoBootDisk [-Path] <String> [-Size <UInt64>] [-Dynamic] [-BlockSizeBytes <UInt32>] 
    [-LogicalSectorSizeBytes <UInt32>] [-PhysicalSectorSizeBytes <UInt32>] [-Recovery] [-WhatIf] [-Confirm] 
    [<CommonParameters>]
    
    
DESCRIPTION
    This command will create a generation 2 VHDX file. Many of the parameters are
    from the New-VHD cmdlet. The disk name must end in .vhdx
     
    To create a recovery partition use -Recovery
```

### Set-GenTwoBootDiskFromWim
```NAME
    Set-GenTwoBootDiskFromWim
    
SYNOPSIS
    Configure Windows image and recovery partitions
    
    
SYNTAX
    Set-GenTwoBootDiskFromWim [-Path] <String> [-WIMPath] <String> [-Index <Int32>] [-Unattend <String>] 
    [-Force <Boolean>] [-WhatIf] [-Confirm] [<CommonParameters>]
    
    
DESCRIPTION
    This command will update partitions for a Generate 2 VHDX file, configured for UEFI. 
    You must supply the path to the VHDX file and a valid WIM. You should also
    include the index number for the Windows Edition to install. The WIM will be
    copied to the recovery partition.
    Optionally, you can also specify an XML file to be inserted into the OS
    partition as unattend.xml
    CAUTION: This command will reformat partitions.
```
