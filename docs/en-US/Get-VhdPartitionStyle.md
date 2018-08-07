---
external help file: WindowsImageTools-help.xml
Module Name: WindowsImageTools
online version:
schema: 2.0.0
---

# Get-VhdPartitionStyle

## SYNOPSIS
Gets partition style of a VHD(x)

## SYNTAX

```
Get-VhdPartitionStyle [-vhd] <String> [<CommonParameters>]
```

## DESCRIPTION
Returns the partition Style of the provided VHD(x) ei.
GPT or MBR

## EXAMPLES

### EXAMPLE 1
```
$partitionStyle = Get-VhdPartitionStyle -Vhd C:\win10.vhdx
```

## PARAMETERS

### -vhd
Path to VHD(x) file

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable.
For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS
