---
external help file: WindowsImageTools-help.xml
Module Name: WindowsImageTools
online version:
schema: 2.0.0
---

# Set-DiskPartition

## SYNOPSIS
Sets the content of a Disk using a source WIM or ISO

## SYNTAX

```
Set-DiskPartition [-DiskNumber] <Int32> [-SourcePath] <String> [-Index <Int32>] [-Unattend <String>]
 [-NativeBoot] [-AddPayloadForRemovedFeature] [-Feature <String[]>] [-RemoveFeature <String[]>]
 [-FeatureSource <String>] [-FeatureSourceIndex <Int32>] [-Driver <String[]>] [-Package <String[]>]
 [-filesToInject <String[]>] [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
This command will copy the content of the SourcePath ISO or WIM and populate the 
partitions found on the disk.
You must supply the path to a valid WIM/ISO.
You 
should also include the index number for the Windows Edition to install.
If the 
recovery partitions are present the source WIM will be copied to the recovery 
partition.
Optionally, you can also specify an XML file to be inserted into the 
OS partition as unattend.xml, any Drivers, WindowsUpdate (MSU) or Optional Features 
you want installed.
And any additional files to add.
CAUTION: This command will replace the content partitions.

## EXAMPLES

### EXAMPLE 1
```
Set-VHDPartition -DiskNumber 0 -SourcePath D:\wim\Win2012R2-Install.wim -Index 1
```

### EXAMPLE 2
```
Set-VHDPartition -DiskNumber 0 -SourcePath D:\wim\Win2012R2-Install.wim -Index 1 -Confirm:$false -force -Verbose
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
Path to file to copy inside of VHD(X) as C:\unattent.xml

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
Native Boot does not have the boot code on the disk.
Only usefull for VHD(X).

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
Feature to turn on (in DISM format)

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

### -Force
Bypass the warning and about lost data

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

## RELATED LINKS
