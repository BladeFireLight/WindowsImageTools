function Get-UpdateConfig
{
    <#
    .Synopsis
    Get the Windows Image Tools Update Config used for creating the temp VM
    .DESCRIPTION
    This command will Get the config used by Invoke-WindowsImageUpdate to build a VM and update Windows Images
    .EXAMPLE
    Set-WitUpdateConfig -Path C:\WitUpdate -VmSwitch 'VM' -IpType DCHP
    Set the temp VM to attach to siwth "VM" and use DCHP for IP addresses
    .EXAMPLE
    Set-WitUPdateConfig -Path C:\WitUpdate -VmSwitch CorpIntAccess -vLAN 1752 -IpType 'IPv4' -IPAddress '172.17.52.100' -SubnetMask 24 -Gateway '172.17.52.254' -DNS '208.67.222.123'
    Setup the temp VM to attache to swithc CorpIntAccess, tag the packets with vLAN id 1752, and set the statis IPv4 Address, mask, gateway and DNS
    .INPUTS
    System.IO.DirectoryInfo
    .OUTPUTS
    System.IO.DirectoryInfo
    #>
    [CmdletBinding()]
    [Alias()]
    [OutputType([Hashtable])]
    Param
    (
        # Path to the Windows Image Tools Update Folders (created via New-WitExample)
        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [ValidateScript( {
                if (Test-Path $_)
                {
                    $true
                }
                else
                {
                    throw "Path $_ does not exist"
                }
            })]
        [Alias('FullName')]
        $Path
    )

    return (Import-Clixml -Path "$Path\config.xml")
}
