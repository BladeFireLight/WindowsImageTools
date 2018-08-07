---
external help file: WindowsImageTools-help.xml
Module Name: WindowsImageTools
online version:
schema: 2.0.0
---

# Initialize-VHDPartition

## SYNOPSIS
Create VHD(X) with partitions needed to be bootable

## SYNTAX

```
Initialize-VHDPartition [-Path] <String> [-Size <UInt64>] [-Dynamic] -DiskLayout <String>
 [-DataFormat <String>] [-Passthru] [-RecoveryTools] [-RecoveryImage] [-force] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

## DESCRIPTION
This command will create a VHD or VHDX file.
Supported layours are: BIOS, UEFI, Data or WindowsToGo. 

To create a recovery partitions use -RecoveryTools and -RecoveryImage

## EXAMPLES

### EXAMPLE 1
```
Initialize-VHDPartition d:\disks\disk001.vhdx -dynamic -size 30GB -DiskLayout BIOS
```

### EXAMPLE 2
```
Initialize-VHDPartition d:\disks\disk001.vhdx -dynamic -size 40GB -DiskLayout UEFI -RecoveryTools
```

## PARAMETERS

### -Path
Path to the new VHDX file (Must end in .vhdx)

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Size
Size in Bytes (Default 40B)

```yaml
Type: UInt64
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 42949672960
Accept pipeline input: False
Accept wildcard characters: False
```

### -Dynamic
Create Dynamic disk

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
Output the disk image object

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
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable.
For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES
General notes

## RELATED LINKS
