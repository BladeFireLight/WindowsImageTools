---
external help file: WindowsImageTools-help.xml
Module Name: WindowsImageTools
online version:
schema: 2.0.0
---

# Mount-VhdAndRunBlock

## SYNOPSIS
Mount a VHD(x), runs a script block and unmounts the VHD(x) driveleter stored in $driveLetter

## SYNTAX

```
Mount-VhdAndRunBlock [-vhd] <String> [-block] <ScriptBlock> [-ReadOnly] [<CommonParameters>]
```

## DESCRIPTION
Us this function to read / write files inside a vhd.
Any objects emited by the scriptblock are returned by this function.

## EXAMPLES

### EXAMPLE 1
```
Mount-VhdAndRunBlock -Vhd c:\win10.vhdx -Block { Copy-Item -Path 'c:\myfiles\unattend.xml' -Destination "$($driveletter):\unattend.xml"}
```

### EXAMPLE 2
```
$fileFound = Mount-VhdAndRunBlock -Vhd c:\lab.vhdx -ReadOnly { test-path "$($driveletter):\scripts\changesmade.log" }
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

### -block
Script block to execute (Drive letter stored in $driveletter)

```yaml
Type: ScriptBlock
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ReadOnly
Mount the VHD(x) readonly, This is faster.
Use when only reading files.

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable.
For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS
