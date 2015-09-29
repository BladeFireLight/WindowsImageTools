
function New-UnattendXml
{

    <#
            .Synopsis
            Create a new basic Unattend.xml 
            .DESCRIPTION
            Creates a new Unattend.xml and sets the admin password, Skips any prompts, logs in a set number of times (default 0) and starts a powershell script (default c:\pstemp\firstrun.ps1).
            If no Path is provided a the file will be created in a temp folder and the path returned.
            .EXAMPLE
            New-UnattendXml -AdminPassword 'P@ssword' -logonCount 1
            .EXAMPLE
            New-UnattendXml -Path c:\temp\Unattent.xml -AdminPassword 'P@ssword' -logonCount 100 -ScriptPath c:\pstemp\firstrun.ps1
            .INPUTS
            Inputs to this cmdlet (if any)
            .OUTPUTS
            Output from this cmdlet (if any)
            .NOTES
            General notes
            .COMPONENT
            The component this cmdlet belongs to
            .ROLE
            The role this cmdlet belongs to
            .FUNCTIONALITY
            The functionality that best describes this cmdlet
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([System.IO.FileInfo])]
    Param
    (
        # The password to have unattnd.xml set the local Administrator to
        [Parameter(Mandatory = $true, 
                ValueFromPipeline = $true,
                ValueFromPipelineByPropertyName = $true, 
        Position = 0)]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [Alias('password')] 
        [string]
        $AdminPassword,

        # Output Path 
        [Alias('FilePath', 'FullName', 'pspath')]
        [ValidateScript({
                    (-not (Test-Path -Path $_))
        })]
        [string]
        $Path = "$(New-TemporaryDirectory)\unattend.xml",

        # Number of times that the local Administrator account should automaticaly login (default 1)        
        [int]
        $LogonCount = 1,

        # Script to run on autologin (default: %SystemDrive%\PSTemp\FirstRun.ps1 )
        [string]
        $ScriptPath = '%SystemDrive%\PSTemp\FirstRun.ps1',

        # set new machine to this timezone (default Central Standard Time) 
        [string]
        $TimeZone = 'Central Standard Time'
    )

    Begin
    {
    
        $unattendTemplate = [xml]@"
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend">
     <settings pass="specialize">
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="x86" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <ComputerName>*</ComputerName>
             <TimeZone>GMT Standard Time</TimeZone>
        </component>
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <ComputerName>*</ComputerName>
             <TimeZone>GMT Standard Time</TimeZone>
        </component>
    </settings>
    <settings pass="oobeSystem">
         <component name="Microsoft-Windows-International-Core" processorArchitecture="x86" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <InputLocale>en-us</InputLocale>
            <SystemLocale>en-us</SystemLocale>
            <UILanguage>en-us</UILanguage>
            <UserLocale>en-us</UserLocale>
        </component>
            <component name="Microsoft-Windows-International-Core" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <InputLocale>en-us</InputLocale>
            <SystemLocale>en-us</SystemLocale>
            <UILanguage>en-us</UILanguage>
            <UserLocale>en-us</UserLocale>
        </component> 
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="x86" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <OOBE>
                <HideEULAPage>true</HideEULAPage>
                <HideWirelessSetupInOOBE>true</HideWirelessSetupInOOBE>
                <NetworkLocation>Work</NetworkLocation>
                <ProtectYourPC>1</ProtectYourPC>
            </OOBE>
            <UserAccounts>
                <AdministratorPassword>
                    <Value>P@ssword</Value>
                    <PlainText>True</PlainText>
                </AdministratorPassword>
                <LocalAccounts>
                   <LocalAccount wcm:action="add">
                       <Password>
                           <Value>P@ssword</Value>
                           <PlainText>True</PlainText>
                       </Password>
                       <DisplayName>Temp For Win7</DisplayName>
                       <Group>Administrators</Group>
                       <Name>tempw7</Name>
                   </LocalAccount>
               </LocalAccounts>
            </UserAccounts>
            <AutoLogon>
                <Password>
                    <Value>P@ssword</Value>
                </Password>
                <LogonCount>1</LogonCount>
                <Username>administrator</Username>
                <Enabled>true</Enabled>
            </AutoLogon>
            <FirstLogonCommands>
                <SynchronousCommand wcm:action="add">
                    <CommandLine>net user "tempw7" /delete</CommandLine>
                    <Description>TempUserCleanup</Description>
                    <Order>1</Order>
                    <RequiresUserInput>false</RequiresUserInput>
                </SynchronousCommand>
                <SynchronousCommand wcm:action="add">
                    <CommandLine>%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe -NoProfile -ExecutionPolicy Bypass -File C:\PSTemp\FirstRun.ps1</CommandLine>
                    <Description>PowerShellFirstRun</Description>
                    <Order>2</Order>
                    <RequiresUserInput>false</RequiresUserInput>
                </SynchronousCommand>
            </FirstLogonCommands>
          </component>
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <OOBE>
                <HideEULAPage>true</HideEULAPage>
                <HideWirelessSetupInOOBE>true</HideWirelessSetupInOOBE>
                <NetworkLocation>Work</NetworkLocation>
                <ProtectYourPC>1</ProtectYourPC>
            </OOBE>
            <UserAccounts>
                <AdministratorPassword>
                    <Value>P@ssword</Value>
                    <PlainText>True</PlainText>
                </AdministratorPassword>
                <LocalAccounts>
                   <LocalAccount wcm:action="add">
                       <Password>
                           <Value>P@ssword</Value>
                           <PlainText>True</PlainText>
                       </Password>
                       <DisplayName>Temp For Win7</DisplayName>
                       <Group>Administrators</Group>
                       <Name>tempw7</Name>
                   </LocalAccount>
               </LocalAccounts>
            </UserAccounts>
            <AutoLogon>
                <Password>
                    <Value>P@ssword</Value>
                </Password>
                <LogonCount>1</LogonCount>
                <Username>administrator</Username>
                <Enabled>true</Enabled>
            </AutoLogon>
            <FirstLogonCommands>
                <SynchronousCommand wcm:action="add">
                    <CommandLine>net user "tempw7" /delete</CommandLine>
                    <Description>TempUserCleanup</Description>
                    <Order>1</Order>
                    <RequiresUserInput>false</RequiresUserInput>
                </SynchronousCommand>
            </FirstLogonCommands>
          </component>
    </settings>
</unattend>
"@

        $PowerShellStartupCmd = '%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe -NoProfile -ExecutionPolicy Bypass -File'
    }
    Process
    {
        if ($pscmdlet.ShouldProcess('$path', 'Create new Unattended.xml'))
        {
            try
            {
                $unattend = $unattendTemplate.Clone()
                (Get-UnattendChunk -pass 'specialize' -component 'Microsoft-Windows-Shell-Setup' -arch 'amd64' -unattend $unattend).TimeZone = $Timezone
                (Get-UnattendChunk -pass 'oobeSystem' -component 'Microsoft-Windows-Shell-Setup' -arch 'amd64' -unattend $unattend).UserAccounts.AdministratorPassword.Value = $AdminPassword
                (Get-UnattendChunk -pass 'oobeSystem' -component 'Microsoft-Windows-Shell-Setup' -arch 'amd64' -unattend $unattend).AutoLogon.Password.Value = $AdminPassword
                (Get-UnattendChunk -pass 'oobeSystem' -component 'Microsoft-Windows-Shell-Setup' -arch 'amd64' -unattend $unattend).AutoLogon.LogonCount = [string]$logonCount
               # ((Get-UnattendChunk -pass 'oobeSystem' -component 'Microsoft-Windows-Shell-Setup' -arch 'amd64' -unattend $unattend).FirstLogonCommands.SynchronousCommand | where Description -eq 'PowerShellFirstRun' ).CommandLine = "$PowerShellStartupCmd $ScriptPath"
                (Get-UnattendChunk -pass 'specialize' -component 'Microsoft-Windows-Shell-Setup' -arch 'x86' -unattend $unattend).TimeZone = $Timezone
                (Get-UnattendChunk -pass 'oobeSystem' -component 'Microsoft-Windows-Shell-Setup' -arch 'x86' -unattend $unattend).UserAccounts.AdministratorPassword.Value = $AdminPassword
                (Get-UnattendChunk -pass 'oobeSystem' -component 'Microsoft-Windows-Shell-Setup' -arch 'x86' -unattend $unattend).AutoLogon.Password.Value = $AdminPassword
                (Get-UnattendChunk -pass 'oobeSystem' -component 'Microsoft-Windows-Shell-Setup' -arch 'x86' -unattend $unattend).AutoLogon.LogonCount = [string]$logonCount
                ((Get-UnattendChunk -pass 'oobeSystem' -component 'Microsoft-Windows-Shell-Setup' -arch 'x86' -unattend $unattend).FirstLogonCommands.SynchronousCommand | where Description -eq 'PowerShellFirstRun' ).CommandLine = "$PowerShellStartupCmd $ScriptPath"
                $unattend.Save($Path)
                Get-ChildItem $Path
            }
            catch 
            {
                throw $_.Exception.Message
            }
        }
    }
}

function Get-UnattendChunk 
{
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
