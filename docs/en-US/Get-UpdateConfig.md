---
external help file: WindowsImageTools-help.xml
Module Name: WindowsImageTools
online version:
schema: 2.0.0
---

# Get-UpdateConfig

## SYNOPSIS
Get the Windows Image Tools Update Config used for creating the temp VM

## SYNTAX

```
Get-UpdateConfig [-Path] <Object> [<CommonParameters>]
```

## DESCRIPTION
This command will Get the config used by Invoke-WindowsImageUpdate to build a VM and update Windows Images

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.IO.DirectoryInfo
## OUTPUTS

### System.IO.DirectoryInfo
## NOTES

## RELATED LINKS
