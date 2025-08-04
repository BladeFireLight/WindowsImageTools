---
external help file: WindowsImageTools-help.xml
Module Name: WindowsImageTools
online version:
schema: 2.0.0
---

# Install-WindowsFromWim

## SYNOPSIS

Populate a Disk it from a WIM

## SYNTAX

```
Install-WindowsFromWim [-DiskNumber] <String> -DiskLayout <String> [-NoRecoveryTools] [-SystemSize <Int32>]
 [-ReservedSize <Int32>] [-RecoverySize <Int32>] [-force] [-SourcePath] <String> [-Index <Int32>]
 [-Unattend <String>] [-NativeBoot] [-Feature <String[]>] [-RemoveFeature <String[]>] [-FeatureSource <String>]
 [-FeatureSourceIndex <Int32>] [-Driver <String[]>] [-AddPayloadForRemovedFeature] [-Package <String[]>]
 [-filesToInject <String[]>] [-UseDismExpansion] [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

## DESCRIPTION

This command will Format the disk and install Windows from a WIM/ISO
You must supply the path to a valid WIM/ISO.
You should also
include the index number for the Windows Edition to install.

## EXAMPLES

### EXAMPLE 1

```PowerShell
Install-WindowsFromWim -DiskNumber 0 -WimPath d:\Source\install.wim -NoRecoveryTools -DiskLayout UEFI
Installs Windows to Disk Number 0 with no Recovery Partition from Index 1
```

### EXAMPLE 2

```PowerShell
Install-WindowsFromWim -DiskNumber 0 -WimPath d:\Source\install.wim -index 3 -force -DiskLayout UEFI
Installs Windows to Disk Number 0 from with recovery partition from index 3 and overwrite any existing data.
```

## PARAMETERS

### -DiskNumber

Disk number, disk must exist

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

### -DiskLayout

Specifies whether to build the image for BIOS (MBR), UEFI (GPT), or WindowsToGo (MBR).
Generation 1 VMs require BIOS (MBR) images.
Generation 2 VMs require UEFI (GPT) images.
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

### -NoRecoveryTools

Skip creating the Recovery Environment Tools Partition.

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

### -SystemSize

System (boot loader) Partition Size (Default : 260MB)

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -ReservedSize

MS Reserved Partition Size (Default : 128MB)

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -RecoverySize

Recovery Tools Partition Size (Default : 905MB)

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 0
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

### -SourcePath

Path to WIM or ISO used to populate VHDX

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Index

Index of image inside of WIM (Default 1)

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 1
Accept pipeline input: False
Accept wildcard characters: False
```

### -Unattend

Path to file to copy inside of VHD(X) as C:\unattend.xml

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -NativeBoot

Native Boot does not have the boot code inside the VHD(x) it must exist on the physical disk.

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

### -Feature

Features to turn on (in DISM format)

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -RemoveFeature

Feature to remove (in DISM format)

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -FeatureSource

Feature Source path.
If not provided, all ISO and WIM images in $sourcePath searched

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -FeatureSourceIndex

Feature Source index.
If the source is a .wim provide an index Default =1

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 1
Accept pipeline input: False
Accept wildcard characters: False
```

### -Driver

Path to drivers to inject

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -AddPayloadForRemovedFeature

Add payload for all removed features

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

### -Package

Path of packages to install via DISM

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -filesToInject

Files/Folders to copy to root of Windows Drive (to place files in directories mimic the directory structure off of C:\\)

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -UseDismExpansion
Use DISM for expansion instead of native PowerShell

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

### -ProgressAction

{{ Fill ProgressAction Description }}

```yaml
Type: ActionPreference
Parameter Sets: (All)
Aliases: proga

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS
