---
external help file: WindowsImageTools-help.xml
Module Name: WindowsImageTools
online version:
schema: 2.0.0
---

# Set-UpdateConfig

## SYNOPSIS
Set the Windows Image Tools Update Config used for creating the temp VM

## SYNTAX

```
Set-UpdateConfig [-Path] <Object> [[-VmSwitch] <String>] [[-vLAN] <Int32>] [[-IpType] <String>]
 [[-IpAddress] <String>] [[-SubnetMask] <Int32>] [[-Gateway] <String>] [[-DnsServer] <String>] [-WhatIf]
 [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Set the config used by Invoke-WitUpdate to build a VM and update Windows Images

## EXAMPLES

### EXAMPLE 1
```
Set-WitUpdateConfig -Path C:\WitUpdate -VmSwitch 'VM' -IpType DCHP
```

Set the temp VM to attach to siwth "VM" and use DCHP for IP addresses

### EXAMPLE 2
```
Set-WitUPdateConfig -Path C:\WitUpdate -VmSwitch CorpIntAccess -vLAN 1752 -IpType 'IPv4' -IPAddress '172.17.52.100' -SubnetMask 24 -Gateway '172.17.52.254' -DNS '208.67.222.123'
```

Setup the temp VM to attache to swithc CorpIntAccess, tag the packets with vLAN id 1752, and set the statis IPv4 Address, mask, gateway and DNS

## PARAMETERS

### -Path
Path to the Windows Image Tools Update Folders (created via New-WitExample)

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

### -VmSwitch
Existing VM Switch

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -vLAN
vLAN to have the VM tag it's trafic to (0 = No vLAN taging)

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -IpType
IP Address Type used to set give the Temporary VM internet access DHCP, IPv4, or IPv6

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -IpAddress
Static IP IPv4 or IPv6 Address to asign the Temporary VM help description

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SubnetMask
IP SubnetMask Ex.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 6
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -Gateway
Static Gateway

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 7
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -DnsServer
Static DNS Server

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 8
Default value: None
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

### System.IO.DirectoryInfo
## OUTPUTS

### System.IO.DirectoryInfo
## NOTES

## RELATED LINKS
