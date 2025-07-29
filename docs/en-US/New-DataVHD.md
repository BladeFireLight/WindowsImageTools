---
external help file: WindowsImageTools-help.xml
Module Name: WindowsImageTools
online version:
schema: 2.0.0
---

# New-DataVHD

## SYNOPSIS

Create a VHDX Data Drive with GPT partitions

## SYNTAX

```PowerShell
New-DataVHD [-Path] <String> [-DataFormat <String>] [-AllocationUnitSize <Int32>] [-Size <Int64>]
 [-ReservedSize <Int32>] [-Dynamic] [-force] [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

## DESCRIPTION

This command will create a VHD or VHDX with a GPT partition table
formatted ReFS(Default) or NTFS.
You must supply the path to the VHD/VHDX file
Use -Force to overwrite existing file (ACLs will be copied to new file)

## EXAMPLES

### EXAMPLE 1

```PowerShell
New-DataVHD -Path c:\Data.vhdx -Size 20GB -Dynamic
Creates a new 20GB Data VHDX that is dynamic, formatted ReFS
```

### EXAMPLE 2

```PowerShell
New-DataVHD -Path c:\data.vhdx -Size 100GB -DataFormat NTFS
Creates a new 100GB Data VHDX formatted NTFS
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

### -AllocationUnitSize

Allocation Unit Size to format the primary partition

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

### -Size

Size in Bytes (Default 40B)

```yaml
Type: Int64
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 42949672960
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
