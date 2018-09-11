---
external help file: WindowsImageTools-help.xml
Module Name: WindowsImageTools
online version:
schema: 2.0.0
---

# Initialize-DiskPartition

## SYNOPSIS
Initialize a disk and create partitions

## SYNTAX

```
Initialize-DiskPartition [-DiskNumber] <Int32> -DiskLayout <String> [-DataFormat <String>] [-Passthru]
 [-RecoveryTools] [-RecoveryImage] [-force] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
This command will will create partition(s) on a give disk.
Supported layours are: BIOS, UEFI, WindowsToGo, Data. 

To create a recovery partitions use -RecoveryTools and -RecoveryImage

## EXAMPLES

### EXAMPLE 1
```
Initialize-VDiskPartition -DiskNumber 5 -dynamic -size 30GB -DiskLayout BIOS
```

### EXAMPLE 2
```
Initialize-VHDPartition -DiskNumber 4 -dynamic -size 40GB -DiskLayout UEFI -RecoveryTools
```

### EXAMPLE 3
```
Initialize-VHDPartition -DiskNumber 1 -dynamic -size 40GB -DiskLayout Data -DataFormat ReFS
```

## PARAMETERS

### -DiskNumber
Disk number, disk must exist

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -DiskLayout
Specifies whether to build the image for BIOS (MBR), UEFI (GPT), Data (GPT), or WindowsToGo (MBR).
Generation 1 VMs require BIOS (MBR) images and have one partition.
Generation 2 VMs require 
UEFI (GPT) images and have 3-5 partitions.
Windows To Go images will boot in UEFI or BIOS

```yaml
Type: String
Parameter Sets: (All)
Aliases: Layout

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -DataFormat
Format drive as NTFS or ReFS (Only applies when DiskLayout = Data)

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: ReFS
Accept pipeline input: False
Accept wildcard characters: False
```

### -Passthru
Output the disk object

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -RecoveryTools
Create the Recovery Environment Tools Partition.
Only valid on UEFI layout

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -RecoveryImage
Create the Recovery Environment Tools and Recovery Image Partitions.
Only valid on UEFI layout

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -force
Force the overwrite of existing files

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -WhatIf
Shows what would happen if the cmdlet runs.
The cmdlet is not run.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: wi

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Confirm
Prompts you for confirmation before running the cmdlet.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: cf

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES
This function is intended as a helper for Intilize-VHDDiskPartition

## RELATED LINKS
