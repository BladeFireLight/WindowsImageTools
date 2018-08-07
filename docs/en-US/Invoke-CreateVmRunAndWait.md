---
external help file: WindowsImageTools-help.xml
Module Name: WindowsImageTools
online version:
schema: 2.0.0
---

# Invoke-CreateVmRunAndWait

## SYNOPSIS
Create a temp vm with a random name and wait for it to stop

## SYNTAX

```
Invoke-CreateVmRunAndWait [-VhdPath] <String> [-VmGeneration] <Int32> [-VmSwitch] <String> [[-vLan] <Int32>]
 [[-ProcessorCount] <Int32>] [[-MemoryStartupBytess] <Int64>] [<CommonParameters>]
```

## DESCRIPTION
This Command quickly test changes to a VHD by creating a temporary VM and ataching it to the network.
VM is deleted when it enters a stoped state.

## EXAMPLES

### EXAMPLE 1
```
Invoke-CreateVMRunAndWait -VhdPath c:\test.vhdx -VmGeneration 2 -VmSwitch 'testlab'
```

### EXAMPLE 2
```
Invoke-CreateVMRunAndWait -VhdPath c:\test.vhdx -VmGeneration 2 -VmSwitch 'testlab' -vLan 16023 -ProcessorCount 1 -MemorySTartupBytes 512mb
```

## PARAMETERS

### -VhdPath
Path to VHD(x)

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

### -VmGeneration
VM Generation (1 = BIOS/MBR, 2 = uEFI/GPT)

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

### -VmSwitch
name of VM switch to attach to

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

### -vLan
vLAN to use default = 0 (dont use vLAN)

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -ProcessorCount
ProcessorCount default = 2

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
Default value: 2
Accept pipeline input: False
Accept wildcard characters: False
```

### -MemoryStartupBytess
MemoryStartupBytes default = 2Gig

```yaml
Type: Int64
Parameter Sets: (All)
Aliases:

Required: False
Position: 6
Default value: 2147483648
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
