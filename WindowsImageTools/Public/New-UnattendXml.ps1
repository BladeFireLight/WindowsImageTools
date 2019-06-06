function New-UnattendXml {
    <#
    .Synopsis
    Create a new Unattend.xml
    .DESCRIPTION
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
    .EXAMPLE
    New-UnattendXml -AdminPassword 'P@ssword' -logonCount 1
    Create an an randomly named xml in $env:temp that will set the Administrator Password and autologin 1 time. outputing the path to the file
    .EXAMPLE
    New-UnattendXml -Path c:\temp\Unattent.xml -AdminPassword 'P@ssword' -logonCount 100 -FirstLogonScriptPath c:\pstemp\firstrun.ps1
    Create an Unattend in at c:\temp\Unattend.xml that :,
        Sets the Administrator Password
        Sets the auto logon count to 100 (basicly every reboot untill you manualy logoff)
        Call c:\pstemp\firstrun.ps1 for each new user's first logon
  #>
    [CmdletBinding(DefaultParameterSetName = 'Basic_FirstLogonScript',
        SupportsShouldProcess = $true)]
    [OutputType([System.IO.FileInfo])]
    Param
    (
        # The password to have unattnd.xml set the local Administrator to (minimum lenght 8)
        [Parameter(Mandatory = $true, HelpMessage = 'Local Administrator Credentials',
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0)]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [Alias('AdminPassword')]
        [System.Management.Automation.Credential()][PSCredential]
        $AdminCredential,

        # User account/password to create and add to Administators group
        [System.Management.Automation.Credential()][PSCredential[]]
        $UserAccount,

        # User account/password to join do the domain
        [System.Management.Automation.Credential()][PSCredential]
        $JoinAccount,

        # Domain to join
        [string]
        $domain,

        # OU to place computer account into
        [string]
        $OU,

        # Output Path
        [Alias('FilePath', 'FullName', 'pspath', 'outfile')]
        [string]
        $Path = "$(New-TemporaryDirectory)\unattend.xml",

        # Number of times that the local Administrator account should automaticaly login (default 0)
        [ValidateRange(0, 1000)]
        [int]
        $LogonCount,

        # ComputerName (default = *)
        [ValidateLength(1, 15)]
        [string]
        $ComputerName = '*',

        # PowerShell Script to run on FirstLogon (ie. %SystemDrive%\PSTemp\FirstRun.ps1 )
        [Parameter(ParameterSetName = 'Basic_FirstLogonScript')]
        [string]
        $FirstLogonScriptPath,

        # PowerShell Script to run on FirstBoot (ie.: %SystemDrive%\PSTemp\FirstRun.ps1 ) Executed in system context during specialize phase
        [Parameter(ParameterSetName = 'Basic_FirstBootScript')]
        [string]
        $FirstBootScriptPath,

        # The product key to use for the unattended installation.
        [ValidatePattern('^[A-Z0-9]{5,5}-[A-Z0-9]{5,5}-[A-Z0-9]{5,5}-[A-Z0-9]{5,5}-[A-Z0-9]{5,5}$')]
        [string]
        $ProductKey,

        # Timezone (default: Timezone of the local Computer)
        [ArgumentCompleter( {
            param ( $commandName,
                    $parameterName,
                    $wordToComplete,
                    $commandAst,
                    $fakeBoundParameters )

            $possibleValues = [System.TimeZoneInfo]::GetSystemTimeZones().ID  | Where-Object {
              $_ -like "$wordToComplete*"
          } | Foreach-Object{
            if ($_ -like '* *')
              { "'{0}'" -f $_ }
            else {$_}}

            $possibleValues | ForEach-Object {$_}
        } )]
        [ValidateScript({
          trap [System.TimeZoneNotFoundException] {$false}
          $null -ne [System.TimeZoneInfo]::FindSystemTimeZoneById($_)
          })]
        [string]
        $TimeZone =  [System.TimeZoneInfo]::Local.Id,

        # Specifies the system input locale and the keyboard layout (default: current system language)
        [Parameter(ValueFromPipelineByPropertyName)]
        [ArgumentCompleter( {
            param ( $commandName,
                    $parameterName,
                    $wordToComplete,
                    $commandAst,
                    $fakeBoundParameters )

            $possibleValues = [System.Globalization.CultureInfo]::GetCultures([System.Globalization.CultureTypes]::AllCultures).Name | Where-Object {
              $_ -like '*-*'
            }  | Where-Object {
              $_ -like "$wordToComplete*"
          }

            $possibleValues | ForEach-Object {$_}
        } )]
      [ValidateScript({
      trap [System.Globalization.CultureNotFoundException] {$false}
      $null -ne [System.Globalization.CultureInfo]::GetCultureInfo($_)
      })]
        [Alias('keyboardlayout')]
        [String]
        $InputLocale =  [System.Globalization.Cultureinfo]::CurrentCulture.Name,

        # Specifies the language for non-Unicode programs (default: Current system language)
        [Parameter(ValueFromPipelineByPropertyName)]
        [ArgumentCompleter( {
            param ( $commandName,
                    $parameterName,
                    $wordToComplete,
                    $commandAst,
                    $fakeBoundParameters )

            $possibleValues = [System.Globalization.CultureInfo]::GetCultures([System.Globalization.CultureTypes]::AllCultures).Name | Where-Object {
              $_ -like '*-*'
            }  | Where-Object {
              $_ -like "$wordToComplete*"
          }

            $possibleValues | ForEach-Object {$_}
        } )]
      [ValidateScript({
      trap [System.Globalization.CultureNotFoundException] {$false}
      $null -ne [System.Globalization.CultureInfo]::GetCultureInfo($_)
      })]
        [String]
        $SystemLocale  =  [System.Globalization.Cultureinfo]::CurrentCulture.Name,

        # Specifies the per-user settings used for formatting dates, times, currency and numbers (default: current system language)
        [Parameter(ValueFromPipelineByPropertyName)]
        [ArgumentCompleter( {
            param ( $commandName,
                    $parameterName,
                    $wordToComplete,
                    $commandAst,
                    $fakeBoundParameters )

            $possibleValues = [System.Globalization.CultureInfo]::GetCultures([System.Globalization.CultureTypes]::AllCultures).Name | Where-Object {
              $_ -like '*-*'
            }  | Where-Object {
              $_ -like "$wordToComplete*"
          }

            $possibleValues | ForEach-Object {$_}
        } )]
      [ValidateScript({
      trap [System.Globalization.CultureNotFoundException] {$false}
      $null -ne [System.Globalization.CultureInfo]::GetCultureInfo($_)
      })]
        [String]
        $UserLocale  =  [System.Globalization.Cultureinfo]::CurrentCulture.Name,

        # Specifies the system default user interface (UI) language (default: current system language)
        [Parameter(ValueFromPipelineByPropertyName)]
        [ArgumentCompleter( {
            param ( $commandName,
                    $parameterName,
                    $wordToComplete,
                    $commandAst,
                    $fakeBoundParameters )

            $possibleValues = [System.Globalization.CultureInfo]::GetCultures([System.Globalization.CultureTypes]::AllCultures).Name | Where-Object {
              $_ -like '*-*'
            }  | Where-Object {
              $_ -like "$wordToComplete*"
          }

            $possibleValues | ForEach-Object {$_}
        } )]
      [ValidateScript({
      trap [System.Globalization.CultureNotFoundException] {$false}
      $null -ne [System.Globalization.CultureInfo]::GetCultureInfo($_)
      })]
        [String]
        $UILanguage  =  [System.Globalization.Cultureinfo]::CurrentCulture.Name,

        # Registered Owner (default: 'Valued Customer')
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateNotNull()]
        [String]
        $RegisteredOwner,

        # Registered Organization (default: 'Valued Customer')
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateNotNull()]
        [String]
        $RegisteredOrganization,

        # Array of hashtables with Description, Order, and Path keys, and optional Domain, Password(plain text), username keys. Executed by in the system context
        [Parameter(ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'Advanced')]
        [Hashtable[]]
        $FirstBootExecuteCommand,

        # Array of hashtables with Description, Order and CommandLine keys. Execuded at first logon of an Administrator, will auto elivate
        [Parameter(ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'Advanced')]
        [Hashtable[]]
        $FirstLogonExecuteCommand,

        # Array of hashtables with Description, Order and CommandLine keys. Executed at every logon, does not elivate.
        [Parameter(ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'Advanced')]
        [Hashtable[]]
        $EveryLogonExecuteCommand,

        # Enable Local Administrator account (default $true) this is needed for client OS if your not useing autologon or adding aditional admin users.
        [switch]
        $enableAdministrator
    )

    Begin {
        $templateUnattendXml = [xml] @'
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend">
  <settings pass="specialize">
    <component name="Microsoft-Windows-UnattendedJoin" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"></component>
    <component name="Microsoft-Windows-UnattendedJoin" processorArchitecture="x86" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"></component>
    <component name="Microsoft-Windows-Deployment" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"></component>
        <component name="Microsoft-Windows-Deployment" processorArchitecture="x86" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"></component>
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"></component>
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="x86" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"></component>
  </settings>
  <settings pass="oobeSystem">
        <component name="Microsoft-Windows-International-Core" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
          <InputLocale>en-US</InputLocale>
          <SystemLocale>en-US</SystemLocale>
          <UILanguage>en-US</UILanguage>
          <UserLocale>en-US</UserLocale>
    </component>
        <component name="Microsoft-Windows-International-Core" processorArchitecture="x86" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
          <InputLocale>en-US</InputLocale>
          <SystemLocale>en-US</SystemLocale>
          <UILanguage>en-US</UILanguage>
          <UserLocale>en-US</UserLocale>
    </component>
    <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <OOBE>
        <HideEULAPage>true</HideEULAPage>
        <HideWirelessSetupInOOBE>true</HideWirelessSetupInOOBE>
        <NetworkLocation>Work</NetworkLocation>
        <ProtectYourPC>1</ProtectYourPC>
                <SkipUserOOBE>true</SkipUserOOBE>
                <SkipMachineOOBE>true</SkipMachineOOBE>
      </OOBE>
      <TimeZone>GMT Standard Time</TimeZone>
      <UserAccounts>
        <AdministratorPassword>
            <Value></Value>
            <PlainText>false</PlainText>
        </AdministratorPassword>
      </UserAccounts>
      <RegisteredOrganization>Generic Organization</RegisteredOrganization>
      <RegisteredOwner>Generic Owner</RegisteredOwner>
      </component>
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="x86" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <OOBE>
        <HideEULAPage>true</HideEULAPage>
        <HideWirelessSetupInOOBE>true</HideWirelessSetupInOOBE>
        <NetworkLocation>Work</NetworkLocation>
        <ProtectYourPC>1</ProtectYourPC>
                <SkipUserOOBE>true</SkipUserOOBE>
                <SkipMachineOOBE>true</SkipMachineOOBE>
      </OOBE>
      <TimeZone>GMT Standard Time</TimeZone>
      <UserAccounts>
        <AdministratorPassword>
            <Value></Value>
            <PlainText>false</PlainText>
        </AdministratorPassword>
      </UserAccounts>
      <RegisteredOrganization>Generic Organization</RegisteredOrganization>
      <RegisteredOwner>Generic Owner</RegisteredOwner>
    </component>
  </settings>
</unattend>
'@

        if ($LogonCount -gt 0) {
            Write-Warning -Message '-Autologon places the Administrator password in plain txt'
        }
    }
    Process {
        if ($pscmdlet.ShouldProcess("$path", 'Create new Unattended.xml')) {
            if ($FirstBootScriptPath) {
                Write-Verbose -Message "[$($MyInvocation.MyCommand)] Adding PowerShell script to First boot command"
                $FirstBootExecuteCommand = @(@{
                        Description = 'PowerShell First boot script'
                        order       = 1
                        path        = "%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"$FirstBootScriptPath`""
                    })
            }

            if ($FirstLogonScriptPath) {
                Write-Verbose -Message "[$($MyInvocation.MyCommand)] Adding PowerShell script to First Logon command"
                $FirstLogonExecuteCommand = @(@{
                        Description = 'PowerShell First logon script'
                        order       = 1
                        CommandLine = "%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"$FirstBootScriptPath`""
                    })
            }

            if ($enableAdministrator) {
                Write-Verbose -Message "[$($MyInvocation.MyCommand)] Enabeling Administrator via First boot command"
                if ($FirstBootExecuteCommand) {
                    $FirstBootExecuteCommand = $FirstBootExecuteCommand + @{
                        Description = 'Enable Administrator'
                        order       = 0
                        path        = 'net user administrator /active:yes'
                    }
                } else {
                    $FirstBootExecuteCommand = @{
                        Description = 'Enable Administrator'
                        order       = 0
                        path        = 'net user administrator /active:yes'
                    }
                }
            } else {
                if ((-not ($UserAccount)) -or (-not($EnableAdministrator)) -or ( (-not ($domain)) -and (-not ($JoinAccount)) -and (-not ($OU)) ) ) {
                    Write-Warning -Message "$Path only usable on a server SKU, for a client OS, use either -EnableAdministrator or -UserAccount, or (-Domain and -JoinAccount and -OU)"
                }
            }

            [xml] $unattendXml = $templateUnattendXml
            foreach ($setting in $unattendXml.Unattend.Settings) {
                foreach ($component in $setting.Component) {
                    if ($setting.'Pass' -eq 'specialize' -and $component.'Name' -eq 'Microsoft-Windows-UnattendedJoin' ) {
                        if (($JoinAccount) -or ($domain) -or ($OU)) {
                            if (($JoinAccount) -and ($domain) -and ($OU)) {
                                Write-Verbose -Message "[$($MyInvocation.MyCommand)] Adding Unattend Domain Join for $($component.'processorArchitecture') Architecture"
                                $identificationElement = $component.AppendChild($unattendXml.CreateElement('Identification', 'urn:schemas-microsoft-com:unattend'))
                                $IdCredentialElement = $identificationElement.AppendChild($unattendXml.CreateElement('Credentials', 'urn:schemas-microsoft-com:unattend'))
                                $IdCredDomainEliment = $IdCredentialElement.AppendChild($unattendXml.CreateElement('Domain', 'urn:schemas-microsoft-com:unattend'))
                                $Null = $IdCredDomainEliment.AppendChild($unattendXml.CreateTextNode($domain))
                                $IdCredPasswordElement = $IdCredentialElement.AppendChild($unattendXml.CreateElement('Password', 'urn:schemas-microsoft-com:unattend'))
                                $Null = $IdCredPasswordElement.AppendChild($unattendXml.CreateTextNode($JoinAccount.GetNetworkCredential().Password))
                                $IdCredUserNameElement = $IdCredentialElement.AppendChild($unattendXml.CreateElement('Username', 'urn:schemas-microsoft-com:unattend'))
                                $Null = $IdCredUserNameElement.AppendChild($unattendXml.CreateTextNode($JoinAccount.GetNetworkCredential().UserName))
                                $IdJoinDomainElement = $identificationElement.AppendChild($unattendXml.CreateElement('JoinDomain', 'urn:schemas-microsoft-com:unattend'))
                                $Null = $IdJoinDomainElement.AppendChild($unattendXml.CreateTextNode($domain))
                                $IdMachineOUElement = $identificationElement.AppendChild($unattendXml.CreateElement('MachineObjectOU', 'urn:schemas-microsoft-com:unattend'))
                                $Null = $IdMachineOUElement.AppendChild($unattendXml.CreateTextNode($OU))
                                $IdUnsecureJoinElement = $identificationElement.AppendChild($unattendXml.CreateElement('UnsecureJoin', 'urn:schemas-microsoft-com:unattend'))
                                $Null = $IdUnsecureJoinElement.AppendChild($unattendXml.CreateTextNode('False'))

                            } else {
                                Write-Warning 'Domain join requires -JoinAccount, -Domain, and -OU : one or more is missing, skipping section'
                            }

                        }
                    }
                    if ($setting.'Pass' -eq 'specialize' -and $component.'Name' -eq 'Microsoft-Windows-Deployment' ) {
                        if (($null -ne $FirstBootExecuteCommand -or $FirstBootExecuteCommand.Length -gt 0) -and $component.'processorArchitecture' -eq 'x86') {
                            Write-Verbose -Message "[$($MyInvocation.MyCommand)] Adding first boot command(s)"
                            $commandOrder = 1
                            $runSynchronousElement = $component.AppendChild($unattendXml.CreateElement('RunSynchronous', 'urn:schemas-microsoft-com:unattend'))
                            foreach ($synchronousCommand in ($FirstBootExecuteCommand | Sort-Object -Property {
                                        $_.order
                                    })) {
                                $syncCommandElement = $runSynchronousElement.AppendChild($unattendXml.CreateElement('RunSynchronousCommand', 'urn:schemas-microsoft-com:unattend'))
                                $null = $syncCommandElement.SetAttribute('action', 'http://schemas.microsoft.com/WMIConfig/2002/State', 'add')
                                $syncCommandDescriptionElement = $syncCommandElement.AppendChild($unattendXml.CreateElement('Description', 'urn:schemas-microsoft-com:unattend'))
                                $Null = $syncCommandDescriptionElement.AppendChild($unattendXml.CreateTextNode($synchronousCommand['Description']))
                                $syncCommandOrderElement = $syncCommandElement.AppendChild($unattendXml.CreateElement('Order', 'urn:schemas-microsoft-com:unattend'))
                                $Null = $syncCommandOrderElement.AppendChild($unattendXml.CreateTextNode($commandOrder))
                                $syncCommandPathElement = $syncCommandElement.AppendChild($unattendXml.CreateElement('Path', 'urn:schemas-microsoft-com:unattend'))
                                $Null = $syncCommandPathElement.AppendChild($unattendXml.CreateTextNode($synchronousCommand['Path']))
                                $commandOrder++
                            }
                        }
                    }
                    if (($setting.'Pass' -eq 'specialize') -and ($component.'Name' -eq 'Microsoft-Windows-Shell-Setup')) {
                        if ($ComputerName) {
                            Write-Verbose -Message "[$($MyInvocation.MyCommand)] Adding custom computername for $($component.'processorArchitecture') Architecture"
                            $computerNameElement = $component.AppendChild($unattendXml.CreateElement('ComputerName', 'urn:schemas-microsoft-com:unattend'))
                            $Null = $computerNameElement.AppendChild($unattendXml.CreateTextNode($ComputerName))
                        }
                        if ($ProductKey) {
                            Write-Verbose -Message "[$($MyInvocation.MyCommand)] Adding Product key for $($component.'processorArchitecture') Architecture"
                            $productKeyElement = $component.AppendChild($unattendXml.CreateElement('ProductKey', 'urn:schemas-microsoft-com:unattend'))
                            $Null = $productKeyElement.AppendChild($unattendXml.CreateTextNode($ProductKey.ToUpper()))
                        }
                    }

                    if (($setting.'Pass' -eq 'oobeSystem') -and ($component.'Name' -eq 'Microsoft-Windows-International-Core')) {
                        if ($InputLocale) {
                            Write-Verbose -Message "[$($MyInvocation.MyCommand)] Adding Input Locale for $($component.'processorArchitecture') Architecture"
                            $component.InputLocale = $InputLocale
                        }
                        if ($SystemLocale) {
                            Write-Verbose -Message "[$($MyInvocation.MyCommand)] Adding System Locale for $($component.'processorArchitecture') Architecture"
                            $component.SystemLocale = $SystemLocale
                        }
                        if ($UILanguage) {
                            Write-Verbose -Message "[$($MyInvocation.MyCommand)] Adding UI Language for $($component.'processorArchitecture') Architecture"
                            $component.UILanguage = $UILanguage
                        }
                        if ($UserLocale) {
                            Write-Verbose -Message "[$($MyInvocation.MyCommand)] Adding User Locale for $($component.'processorArchitecture') Architecture"
                            $component.UserLocale = $UserLocale
                        }
                    }

                    if (($setting.'Pass' -eq 'oobeSystem') -and ($component.'Name' -eq 'Microsoft-Windows-Shell-Setup')) {
                        if ($TimeZone) {
                            Write-Verbose -Message "[$($MyInvocation.MyCommand)] Adding Time Zone for $($component.'processorArchitecture') Architecture"
                            $component.TimeZone = $TimeZone
                        }
                        Write-Verbose -Message "[$($MyInvocation.MyCommand)] Adding Administrator Passwords for $($component.'processorArchitecture') Architecture"
                        $concatenatedPassword = '{0}AdministratorPassword' -f $AdminCredential.GetNetworkCredential().password
                        $component.UserAccounts.AdministratorPassword.Value = [System.Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($concatenatedPassword))
                        if ($RegisteredOrganization) {
                            Write-Verbose -Message "[$($MyInvocation.MyCommand)] Adding Registred Organization for $($component.'processorArchitecture') Architecture"
                            $component.RegisteredOrganization = $RegisteredOrganization
                        }
                        if ($RegisteredOwner) {
                            Write-Verbose -Message "[$($MyInvocation.MyCommand)] Adding Registered Owner for $($component.'processorArchitecture') Architecture"
                            $component.RegisteredOwner = $RegisteredOwner
                        }
                        if ($UserAccount) {
                            Write-Verbose -Message "[$($MyInvocation.MyCommand)] Adding User Account(s) for $($component.'processorArchitecture') Architecture"
                            $UserAccountsElement = $component.UserAccounts
                            $LocalAccountsElement = $UserAccountsElement.AppendChild($unattendXml.CreateElement('LocalAccounts', 'urn:schemas-microsoft-com:unattend'))
                            foreach ($Account in $UserAccount) {
                                $LocalAccountElement = $LocalAccountsElement.AppendChild($unattendXml.CreateElement('LocalAccount', 'urn:schemas-microsoft-com:unattend'))
                                $LocalAccountPasswordElement = $LocalAccountElement.AppendChild($unattendXml.CreateElement('Password', 'urn:schemas-microsoft-com:unattend'))
                                $LocalAccountPasswordValueElement = $LocalAccountPasswordElement.AppendChild($unattendXml.CreateElement('Value', 'urn:schemas-microsoft-com:unattend'))
                                $LocalAccountPasswordPlainTextElement = $LocalAccountPasswordElement.AppendChild($unattendXml.CreateElement('PlainText', 'urn:schemas-microsoft-com:unattend'))
                                $LocalAccountDisplayNameElement = $LocalAccountElement.AppendChild($unattendXml.CreateElement('DisplayName', 'urn:schemas-microsoft-com:unattend'))
                                $LocalAccountGroupElement = $LocalAccountElement.AppendChild($unattendXml.CreateElement('Group', 'urn:schemas-microsoft-com:unattend'))
                                $LocalAccountNameElement = $LocalAccountElement.AppendChild($unattendXml.CreateElement('Name', 'urn:schemas-microsoft-com:unattend'))

                                $null = $LocalAccountElement.SetAttribute('action', 'http://schemas.microsoft.com/WMIConfig/2002/State', 'add')
                                $concatenatedPassword = '{0}Password' -f $Account.GetNetworkCredential().password
                                $null = $LocalAccountPasswordValueElement.AppendChild($unattendXml.CreateTextNode([System.Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($concatenatedPassword))))
                                $null = $LocalAccountPasswordPlainTextElement.AppendChild($unattendXml.CreateTextNode('false'))
                                $null = $LocalAccountDisplayNameElement.AppendChild($unattendXml.CreateTextNode($Account.UserName))
                                $null = $LocalAccountGroupElement.AppendChild($unattendXml.CreateTextNode('Administrators'))
                                $null = $LocalAccountNameElement.AppendChild($unattendXml.CreateTextNode($Account.UserName))
                            }
                        }

                        if ($LogonCount) {
                            Write-Verbose -Message "[$($MyInvocation.MyCommand)] Adding Autologon for $($component.'processorArchitecture') Architecture"
                            $autoLogonElement = $component.AppendChild($unattendXml.CreateElement('AutoLogon', 'urn:schemas-microsoft-com:unattend'))
                            $autoLogonPasswordElement = $autoLogonElement.AppendChild($unattendXml.CreateElement('Password', 'urn:schemas-microsoft-com:unattend'))
                            $autoLogonPasswordValueElement = $autoLogonPasswordElement.AppendChild($unattendXml.CreateElement('Value', 'urn:schemas-microsoft-com:unattend'))
                            $autoLogonCountElement = $autoLogonElement.AppendChild($unattendXml.CreateElement('LogonCount', 'urn:schemas-microsoft-com:unattend'))
                            $autoLogonUsernameElement = $autoLogonElement.AppendChild($unattendXml.CreateElement('Username', 'urn:schemas-microsoft-com:unattend'))
                            $autoLogonEnabledElement = $autoLogonElement.AppendChild($unattendXml.CreateElement('Enabled', 'urn:schemas-microsoft-com:unattend'))

                            $null = $autoLogonPasswordValueElement.AppendChild($unattendXml.CreateTextNode($AdminCredential.GetNetworkCredential().password))
                            $null = $autoLogonCountElement.AppendChild($unattendXml.CreateTextNode($LogonCount))
                            $null = $autoLogonUsernameElement.AppendChild($unattendXml.CreateTextNode('administrator'))
                            $null = $autoLogonEnabledElement.AppendChild($unattendXml.CreateTextNode('true'))
                        }

                        if (($Null -ne $FirstLogonExecuteCommand -or $FirstBootExecuteCommand.Length -gt 0) -and $component.'processorArchitecture' -eq 'x86') {
                            Write-Verbose -Message "[$($MyInvocation.MyCommand)] Adding First Logon Commands"
                            $commandOrder = 1
                            $FirstLogonCommandsElement = $component.AppendChild($unattendXml.CreateElement('FirstLogonCommands', 'urn:schemas-microsoft-com:unattend'))
                            foreach ($command in ($FirstLogonExecuteCommand | Sort-Object -Property {
                                        $_.order
                                    })) {
                                $CommandElement = $FirstLogonCommandsElement.AppendChild($unattendXml.CreateElement('SynchronousCommand', 'urn:schemas-microsoft-com:unattend'))
                                $CommandDescriptionElement = $CommandElement.AppendChild($unattendXml.CreateElement('Description', 'urn:schemas-microsoft-com:unattend'))
                                $CommandOrderElement = $CommandElement.AppendChild($unattendXml.CreateElement('Order', 'urn:schemas-microsoft-com:unattend'))
                                $CommandCommandLineElement = $CommandElement.AppendChild($unattendXml.CreateElement('CommandLine', 'urn:schemas-microsoft-com:unattend'))
                                $CommandRequireInputlement = $CommandElement.AppendChild($unattendXml.CreateElement('RequiresUserInput', 'urn:schemas-microsoft-com:unattend'))

                                $null = $CommandElement.SetAttribute('action', 'http://schemas.microsoft.com/WMIConfig/2002/State', 'add')
                                $null = $CommandDescriptionElement.AppendChild($unattendXml.CreateTextNode($command['Description']))
                                $null = $CommandOrderElement.AppendChild($unattendXml.CreateTextNode($commandOrder))
                                $null = $CommandCommandLineElement.AppendChild($unattendXml.CreateTextNode($command['CommandLine']))
                                $null = $CommandRequireInputlement.AppendChild($unattendXml.CreateTextNode('false'))
                                $commandOrder++
                            }
                        }
                        if (($null -ne $EveryLogonExecuteCommand -or $FirstBootExecuteCommand.Length -gt 0) -and $component.'processorArchitecture' -eq 'x86') {
                            Write-Verbose -Message "[$($MyInvocation.MyCommand)] Adding Every-Logon Commands"
                            $commandOrder = 1
                            $FirstLogonCommandsElement = $component.AppendChild($unattendXml.CreateElement('LogonCommands', 'urn:schemas-microsoft-com:unattend'))
                            foreach ($command in ($EveryLogonExecuteCommand | Sort-Object -Property {
                                        $_.order
                                    })) {
                                $CommandElement = $FirstLogonCommandsElement.AppendChild($unattendXml.CreateElement('AsynchronousCommand', 'urn:schemas-microsoft-com:unattend'))
                                $CommandDescriptionElement = $CommandElement.AppendChild($unattendXml.CreateElement('Description', 'urn:schemas-microsoft-com:unattend'))
                                $CommandOrderElement = $CommandElement.AppendChild($unattendXml.CreateElement('Order', 'urn:schemas-microsoft-com:unattend'))
                                $CommandCommandLineElement = $CommandElement.AppendChild($unattendXml.CreateElement('CommandLine', 'urn:schemas-microsoft-com:unattend'))
                                $CommandRequireInputlement = $CommandElement.AppendChild($unattendXml.CreateElement('RequiresUserInput', 'urn:schemas-microsoft-com:unattend'))

                                $null = $CommandElement.SetAttribute('action', 'http://schemas.microsoft.com/WMIConfig/2002/State', 'add')
                                $null = $CommandDescriptionElement.AppendChild($unattendXml.CreateTextNode($command['Description']))
                                $null = $CommandOrderElement.AppendChild($unattendXml.CreateTextNode($commandOrder))
                                $null = $CommandCommandLineElement.AppendChild($unattendXml.CreateTextNode($command['CommandLine']))
                                $null = $CommandRequireInputlement.AppendChild($unattendXml.CreateTextNode('false'))
                                $commandOrder++
                            }
                        }
                    }
                } #end foreach setting.Component
            } #end foreach unattendXml.Unattend.Settings

            Write-Verbose -Message "[$($MyInvocation.MyCommand)] Saving file"

            $unattendXml.Save($Path)
            Get-ChildItem $Path
            #         }
            #         catch
            #         {
            #             throw $_.Exception.Message
            #         }
        }
    }
}


function Get-UnattendChunk {
    param
    (
        [string] $pass,
        [string] $component,
        [string] $arch,
        [xml] $unattend
    )

    # Helper function that returns one component chunk from the Unattend XML data structure
    return $unattend.unattend.settings |
    Where-Object -Property pass -EQ -Value $pass |
    Select-Object -ExpandProperty component |
    Where-Object -Property name -EQ -Value $component |
    Where-Object -Property processorArchitecture -EQ -Value $arch
}
