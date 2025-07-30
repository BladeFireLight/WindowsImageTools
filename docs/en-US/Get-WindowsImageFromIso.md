---
external help file: WindowsImageTools-help.xml
Module Name: WindowsImageTools
online version:
schema: 2.0.0
---

# Get-WindowsImageFromIso

## SYNOPSIS
Lists Windows images available in a WIM file inside an ISO.

## SYNTAX

```
Get-WindowsImageFromIso [-Path] <String> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Mounts the specified ISO, locates the WIM file, lists its contents using Get-WindowsImage, and then dismounts the ISO.

## EXAMPLES

### EXAMPLE 1
```
Get-WindowsImageFromIso -Path 'C:\Images\Win10.iso'
```

Lists the available Windows images in the WIM file inside the specified ISO.

## PARAMETERS

### -Path
The path to the ISO file containing the Windows image.

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
Author: WindowsImageTools Team
Requires: Administrator privileges

## RELATED LINKS
