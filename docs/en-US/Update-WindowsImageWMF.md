---
external help file: WindowsImageTools-help.xml
Module Name: WindowsImageTools
online version:
schema: 2.0.0
---

# Update-WindowsImageWMF

## SYNOPSIS
Updates WMF to 4.0, 5.0 or 5.1 preview (and .NET to 4.6) in a Windows Update Image

## SYNTAX

```
Update-WindowsImageWMF [-Path] <Object> [-ImageName] <String[]> [-Wmf4] [-Wmf5] [-preview] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

## DESCRIPTION
This Command downloads WMF 4.0, 5.0 or 5.1 (Production Preview) and .NET 4.6 offline installer and installes them in the target Update Image
Creates a temp VM and updates .NET (if needed) and WMF
The default is to install the latest stable (currently 5.0)
Windows 7 and 2008 Need WMF4 before WMF 5.x

## EXAMPLES

### EXAMPLE 1
```
Update-UpdateImageWMF -Path C:\WITExample
```

Updates every Image in c:\WITExample\BaseImages

### EXAMPLE 2
```
Update-UpdateImageWMF -Path C:\WitExample -Name Server2012R2Core
```

Updates only C:\WitExample\BaseImages\Server2012R2Core_Base.vhdx

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

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Wmf4
Use WMF 4 instead of the default WMF 5.0

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

### -Wmf5
Use WMF 5 instead of the default WMF 5.0

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

### -preview
Use Production Preview instead of the default WMF 5.0 (overrides -vmf4)

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

## RELATED LINKS
