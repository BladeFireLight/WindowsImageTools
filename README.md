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

```NAME
    Convert-Wim2GenTwoVhdx
    
SYNOPSIS
    Create a VHDX and populate it from a WIM
    
    
SYNTAX
    Convert-Wim2GenTwoVhdx [-Path] <String> [-WIMPath] <String> [-Index <Int32>] [-Unattend 
    <String>] [-Size <UInt64>] [-Dynamic] [-BlockSizeBytes <UInt32>] [-LogicalSectorSizeBytes 
    <UInt32>] [-PhysicalSectorSizeBytes <UInt32>] [-Recovery] [-Force] [-WhatIf] [-Confirm] 
    [<CommonParameters>]
    
    
DESCRIPTION
    This command will update partitions for a Generate 2 VHDX file, configured for UEFI. 
    You must supply the path to the VHDX file and a valid WIM. You should also
    include the index number for the Windows Edition to install.
    

PARAMETERS
    -Path <String>
        Path to VHDX
        
    -WIMPath <String>
        Path to WIM used to populate VHDX
        
    -Index <Int32>
        Index of image inside of WIM (Default 1)
        index is valid
        
    -Unattend <String>
        Path to file to copy inside of VHDX as C:\unattent.xml
        
    -Size <UInt64>
        Size in Bytes from 25GB - 64TB (Default 40GB)
        
    -Dynamic [<SwitchParameter>]
        Create Dynamic disk
        
    -BlockSizeBytes <UInt32>
        Block Size (Default 2MB)
        
    -LogicalSectorSizeBytes <UInt32>
        Logical Sector size of 512 or 4098 bytes (Default 512)
        
    -PhysicalSectorSizeBytes <UInt32>
        Phisical Sector size of 512 or 4096 bytes (Default 512)
        
    -Recovery [<SwitchParameter>]
        Create the Recovery Partition (Pet vs Cattle)
        
    -Force [<SwitchParameter>]
        Force overwrite of vhdx
        
    -WhatIf [<SwitchParameter>]
        
    -Confirm [<SwitchParameter>]
        
    <CommonParameters>
        This cmdlet supports the common parameters: Verbose, Debug,
        ErrorAction, ErrorVariable, WarningAction, WarningVariable,
        OutBuffer, PipelineVariable, and OutVariable. For more information, see 
        about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216). 
    
    -------------------------- EXAMPLE 1 --------------------------
    
    PS C:\>Convert-WIM2VHDX -Path c:\windows8.vhdx -WimPath d:\Source\install.wim -Recovery
    
    -------------------------- EXAMPLE 2 --------------------------
    
    PS C:\>Convert-WIM2VHDX -Path c:\windowsServer.vhdx -WimPath d:\Source\install.wim -index 3 
    -Size 40GB -force
   
   
   
NAME
    get-AbsoluteFilePath
    
SYNOPSIS
    Get Absolute path from relative path
    
    
SYNTAX
    get-AbsoluteFilePath [-Path] <Object> [<CommonParameters>]
    
    
DESCRIPTION
    Takes a relative path like .\file.txt and returns the full path.
    Parent folder must exist, but target file does not.
    The target file does not have to exist, but the parent folder must exist
    

PARAMETERS
    -Path <Object>
        Path to file
        
    <CommonParameters>
        This cmdlet supports the common parameters: Verbose, Debug,
        ErrorAction, ErrorVariable, WarningAction, WarningVariable,
        OutBuffer, PipelineVariable, and OutVariable. For more information, see 
        about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216). 
    
    -------------------------- EXAMPLE 1 --------------------------
    
    PS C:\>$path = Get-AbsoluteFilePath -Path .\file.txt
   
   
NAME
    Initialize-GenTwoBootDisk
    
SYNOPSIS
    Create a Generation 2 VHDX
    
    
SYNTAX
    Initialize-GenTwoBootDisk [-Path] <String> [-Size <UInt64>] [-Dynamic] [-BlockSizeBytes 
    <UInt32>] [-LogicalSectorSizeBytes <UInt32>] [-PhysicalSectorSizeBytes <UInt32>] [-Recovery] 
    [-WhatIf] [-Confirm] [<CommonParameters>]
    
DESCRIPTION
    This command will create a generation 2 VHDX file. Many of the parameters are
    from the New-VHD cmdlet. The disk name must end in .vhdx
    
    To create a recovery partition use -Recovery
   
PARAMETERS
    -Path <String>
        Path to the new VHDX file (Must end in .vhdx)
        
    -Size <UInt64>
        Size in Bytes (Default 40B)
        
    -Dynamic [<SwitchParameter>]
        Create Dynamic disk
        
    -BlockSizeBytes <UInt32>
        Block Size (Default 2MB)
        
    -LogicalSectorSizeBytes <UInt32>
        Logical Sector size of 512 or 4098 bytes (Default 512)
        
    -PhysicalSectorSizeBytes <UInt32>
        Phisical Sector size of 512 or 4096 bytes (Default 512)
        
    -Recovery [<SwitchParameter>]
        Create the Recovery Partition (Pet vs Cattle)
        
    -WhatIf [<SwitchParameter>]
        
    -Confirm [<SwitchParameter>]
        
    <CommonParameters>
        This cmdlet supports the common parameters: Verbose, Debug,
        ErrorAction, ErrorVariable, WarningAction, WarningVariable,
        OutBuffer, PipelineVariable, and OutVariable. For more information, see 
        about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216). 
    
    -------------------------- EXAMPLE 1 --------------------------
    
    PS C:\>Initialize-Gen2BootDisk d:\disks\disk001.vhdx -dynamic -size 30GB
    
    -------------------------- EXAMPLE 2 --------------------------
    
    PS C:\>Initialize-Gen2BootDisk d:\disks\disk001.vhdx -dynamic -size 40GB -Recovery
   
NAME
    Set-GenTwoBootDiskFromWim
    
SYNOPSIS
    Configure Windows image and recovery partitions
    
    
SYNTAX
    Set-GenTwoBootDiskFromWim [-Path] <String> [-WIMPath] <String> [-Index <Int32>] [-Unattend 
    <String>] [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]
    
    
DESCRIPTION
    This command will update partitions for a Generate 2 VHDX file, configured for UEFI. 
    You must supply the path to the VHDX file and a valid WIM. You should also
    include the index number for the Windows Edition to install. The WIM will be
    copied to the recovery partition.
    Optionally, you can also specify an XML file to be inserted into the OS
    partition as unattend.xml
    CAUTION: This command will reformat partitions.
    

PARAMETERS
    -Path <String>
        Path to VHDX
        
    -WIMPath <String>
        Path to WIM used to populate VHDX
        
    -Index <Int32>
        Index of image inside of WIM (Default 1)
        index is valid
        
    -Unattend <String>
        Path to file to copy inside of VHDX as C:\unattent.xml
        
    -Force [<SwitchParameter>]
        Bypass the warning and about lost data
        
    -WhatIf [<SwitchParameter>]
        
    -Confirm [<SwitchParameter>]
        
    <CommonParameters>
        This cmdlet supports the common parameters: Verbose, Debug,
        ErrorAction, ErrorVariable, WarningAction, WarningVariable,
        OutBuffer, PipelineVariable, and OutVariable. For more information, see 
        about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216). 
    
    -------------------------- EXAMPLE 1 --------------------------
    
    PS C:\>Set-Gen2BootDiskFromWim -Path D:\vhd\demo3.vhdx -WIMPath D:\wim\Win2012R2-Install.wim 
    -verbose
    
    -------------------------- EXAMPLE 2 --------------------------
    
    PS C:\>Set-Gen2BootDiskFromWim -Path D:\vhd\demo3.vhdx -WIMPath D:\wim\Win2012R2-Install.wim 
    -verbose
    
  ```
