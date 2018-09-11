---
external help file: WindowsImageTools-help.xml
Module Name: WindowsImageTools
online version:
schema: 2.0.0
---

# Invoke-WindowsImageUpdate

## SYNOPSIS
Starts the process of applying updates to all (or selected) images in a Windows Image Tools BaseImages Folder

## SYNTAX

```
Invoke-WindowsImageUpdate [-Path] <Object> [[-ImageName] <String[]>] [-ReduceImageSize] [[-output] <String>]
 [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
This Command updates all (or selected) the images created via Add-UpdateImage in a Windows Image Tools BaseImages folder 
New-WindowsImageToolsExample can be use to create the structrure

## EXAMPLES

### EXAMPLE 1
```
Invoke-WindowsImageUpdate -Path C:\WITExample
```

Update all the Images created with Add-UpdateImage located in C:\WITExample\BaseImages and place the resulting VHD and WIM in c:\WITExample\UpdatedImageShare

### EXAMPLE 2
```
Invoke-WindowsImageUpdate -Path C:\WITExample -Name 2012r2Wmf5
```

Update Image named 2012r2Wmf5_Base.vhdx  in C:\WITExample\BaseImages and place the resulting VHD and WIM in c:\WITExample\UpdatedImageShare

## PARAMETERS

### -Path
Path to the Windows Image Tools Update Folders (created via New-WindowsImageToolsExample)

```yaml
Type: Object
Parameter Sets: (All)
Aliases: FullName

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -ImageName
Name of the Image to update

```yaml
Type: String[]
Parameter Sets: (All)
Aliases: FriendlyName

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ReduceImageSize
Reduce output file by removing feature sources

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

### -output
what files to export if upates are added : NONE, WIM, Both (wim and vhdx) default = both

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: Both
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

### System.Boolean
## NOTES

## RELATED LINKS
