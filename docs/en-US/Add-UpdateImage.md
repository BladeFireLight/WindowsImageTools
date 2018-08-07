---
external help file: WindowsImageTools-help.xml
Module Name: WindowsImageTools
online version:
schema: 2.0.0
---

# Add-UpdateImage

## SYNOPSIS
Add a Windows Image to a Windows Image Tools Update Directory

## SYNTAX

```
Add-UpdateImage -Path <Object> -FriendlyName <String> -AdminCredential <PSCredential> [-ProductKey <String>]
 [-Size <UInt64>] [-Dynamic] -DiskLayout <String> [-SourcePath] <String> [-Index <Int32>]
 [-AddPayloadForRemovedFeature] [-Feature <String[]>] [-RemoveFeature <String[]>] [-FeatureSource <String[]>]
 [-FeatureSourceIndex <Int32>] [-Driver <String[]>] [-Package <String[]>] [-filesToInject <String[]>] [-force]
 [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
This command will convert a .ISO or .WIM into a VHD populated with an unattend.xml and first boot script

## EXAMPLES

### EXAMPLE 1
```
Add-WitUpdateImage -Path c:\WitTools
```

### EXAMPLE 2
```
Another example of how to use this cmdlet
```

## PARAMETERS

### -Path
Path to the Windows Image Tools Update Folders (created via New-WindowsImageToolsExample)

```yaml
Type: Object
Parameter Sets: (All)
Aliases: FullName

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -FriendlyName
Friendly name for for Base VHD used for filenames and targeting in Invoke-WindwosImageUpdate

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -AdminCredential
Administrator Password for Base VHD

```yaml
Type: PSCredential
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ProductKey
Product Key for sorce image (Not required for volume licence media)

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
Type: String[]
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
Default value: 0
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

### -Package
Path of packages to install via DSIM

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
Files/Folders to copy to root of Winodws Drive (to place files in directories mimic the direcotry structure off of C:\\)

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

### -force
Force the overwrite of existing Image

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

### System.IO.DirectoryInfo
## OUTPUTS

### Custom object containing String -Path and String -Name
## NOTES

## RELATED LINKS
