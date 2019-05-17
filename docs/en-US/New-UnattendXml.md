---
external help file: WindowsImageTools-help.xml
Module Name: WindowsImageTools
online version:
schema: 2.0.0
---

# New-UnattendXml

## SYNOPSIS
Create a new Unattend.xml

## SYNTAX

### Basic_FirstLogonScript (Default)
```
New-UnattendXml [-AdminCredential] <PSCredential> [-UserAccount <PSCredential[]>] [-JoinAccount <PSCredential>]
 [-domain <String>] [-OU <String>] [-Path <String>] [-LogonCount <Int32>] [-ComputerName <String>]
 [-FirstLogonScriptPath <String>] [-ProductKey <String>] [-TimeZone <String>] [-InputLocale <String>]
 [-SystemLocale <String>] [-UserLocale <String>] [-UILanguage <String>] [-RegisteredOwner <String>]
 [-RegisteredOrganization <String>] [-enableAdministrator] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### Basic_FirstBootScript
```
New-UnattendXml [-AdminCredential] <PSCredential> [-UserAccount <PSCredential[]>] [-JoinAccount <PSCredential>]
 [-domain <String>] [-OU <String>] [-Path <String>] [-LogonCount <Int32>] [-ComputerName <String>]
 [-FirstBootScriptPath <String>] [-ProductKey <String>] [-TimeZone <String>] [-InputLocale <String>]
 [-SystemLocale <String>] [-UserLocale <String>] [-UILanguage <String>] [-RegisteredOwner <String>]
 [-RegisteredOrganization <String>] [-enableAdministrator] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### Advanced
```
New-UnattendXml [-AdminCredential] <PSCredential> [-UserAccount <PSCredential[]>] [-JoinAccount <PSCredential>]
 [-domain <String>] [-OU <String>] [-Path <String>] [-LogonCount <Int32>] [-ComputerName <String>]
 [-ProductKey <String>] [-TimeZone <String>] [-InputLocale <String>] [-SystemLocale <String>]
 [-UserLocale <String>] [-UILanguage <String>] [-RegisteredOwner <String>] [-RegisteredOrganization <String>]
 [-FirstBootExecuteCommand <Hashtable[]>] [-FirstLogonExecuteCommand <Hashtable[]>]
 [-EveryLogonExecuteCommand <Hashtable[]>] [-enableAdministrator] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
This Command Creates a new Unattend.xml that skips any prompts, and sets the administrator password
Has options for: 
  Joining domain
  Adding user accounts
  Auto logon a set number of times
  Set the Computer Name
  First Boot or First Logon powersrhell script
  Product Key
  TimeZone
  Input, System and User Locals
  UI Language
  Registered Owner and Orginization
  First Boot, First Logon and Every Logon Commands
  Enable Administrator account without autologon (client OS)

If no Path is provided a the file will be created in a temp folder and the path returned.

## EXAMPLES

### EXAMPLE 1
```
New-UnattendXml -AdminPassword 'P@ssword' -logonCount 1
```

### EXAMPLE 2
```
New-UnattendXml -Path c:\temp\Unattent.xml -AdminPassword 'P@ssword' -logonCount 100 -FirstLogonScriptPath c:\pstemp\firstrun.ps1
```

## PARAMETERS

### -AdminCredential
The password to have unattnd.xml set the local Administrator to (minimum lenght 8)

```yaml
Type: PSCredential
Parameter Sets: (All)
Aliases: AdminPassword

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -UserAccount
User account/password to create and add to Administators group

```yaml
Type: PSCredential[]
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -JoinAccount
User account/password to join do the domain

```yaml
Type: PSCredential
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -domain
Domain to join

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -OU
OU to place computer account into

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Path
Output Path

```yaml
Type: String
Parameter Sets: (All)
Aliases: FilePath, FullName, pspath, outfile

Required: False
Position: Named
Default value: "$(New-TemporaryDirectory)\unattend.xml"
Accept pipeline input: False
Accept wildcard characters: False
```

### -LogonCount
Number of times that the local Administrator account should automaticaly login (default 0)

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

### -ComputerName
ComputerName (default = *)

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: *
Accept pipeline input: False
Accept wildcard characters: False
```

### -FirstLogonScriptPath
PowerShell Script to run on FirstLogon (ie.
%SystemDrive%\PSTemp\FirstRun.ps1 )

```yaml
Type: String
Parameter Sets: Basic_FirstLogonScript
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -FirstBootScriptPath
PowerShell Script to run on FirstBoot (ie.: %SystemDrive%\PSTemp\FirstRun.ps1 ) Executed in system context during specialize phase

```yaml
Type: String
Parameter Sets: Basic_FirstBootScript
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ProductKey
The product key to use for the unattended installation.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -TimeZone
Timezone (default: Central Standard Time)

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -InputLocale
Specifies the system input locale and the keyboard layout (default: en-US)

```yaml
Type: String
Parameter Sets: (All)
Aliases: keyboardlayout

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -SystemLocale
Specifies the language for non-Unicode programs (default: en-US)

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -UserLocale
Specifies the per-user settings used for formatting dates, times, currency and numbers (default: en-US)

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -UILanguage
Specifies the system default user interface (UI) language (default: en-US)

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -RegisteredOwner
Registered Owner (default: 'Valued Customer')

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -RegisteredOrganization
Registered Organization (default: 'Valued Customer')

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -FirstBootExecuteCommand
Array of hashtables with Description, Order, and Path keys, and optional Domain, Password(plain text), username keys.
Executed by in the system context

```yaml
Type: Hashtable[]
Parameter Sets: Advanced
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -FirstLogonExecuteCommand
Array of hashtables with Description, Order and CommandLine keys.
Execuded at first logon of an Administrator, will auto elivate

```yaml
Type: Hashtable[]
Parameter Sets: Advanced
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -EveryLogonExecuteCommand
Array of hashtables with Description, Order and CommandLine keys.
Executed at every logon, does not elivate.

```yaml
Type: Hashtable[]
Parameter Sets: Advanced
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -enableAdministrator
Enable Local Administrator account (default $true) this is needed for client OS if your not useing autologon or adding aditional admin users.

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

### System.IO.FileInfo
## NOTES

## RELATED LINKS
