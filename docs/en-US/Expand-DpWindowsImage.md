---
external help file: WindowsImageTools-help.xml
Module Name: WindowsImageTools
online version:
schema: 2.0.0
---

# Expand-DpWindowsImage

## SYNOPSIS
Applies a Windows image from a WIM file to a target directory using DISM.

## SYNTAX

```
Expand-DpWindowsImage [-ImagePath] <String> [-Index] <Int32> [-ApplyPath] <String> [-Compact]
 [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Wrapper for DISM.exe to apply a specific image index from a WIM file to a target directory.
Mimics Expand-WindowsImage.
Optionally uses /Compact for compact OS deployment.

## EXAMPLES

### EXAMPLE 1
```
Expand-DpWindowsImage -ImagePath 'C:\images\install.wim' -Index 1 -ApplyPath 'D:\Windows'
```

### EXAMPLE 2
```
Expand-DpWindowsImage -ImagePath 'C:\images\install.wim' -Index 1 -ApplyPath 'D:\Windows' -Compact
```

## PARAMETERS

### -ImagePath
Path to the WIM file containing the Windows image.

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

### -Index
Index of the image inside the WIM to apply.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -ApplyPath
Target directory where the image will be applied.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Compact
If specified, applies the image using the /Compact option for compact OS deployment.

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
Author: WindowsImageTools Team
Requires: Administrator privileges

## RELATED LINKS
