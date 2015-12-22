#requires -Version 2
<#
        .Synopsis
        Starts the process of applying updates to all (or selected) images in a Windows Image Tools BaseImages Folder
        .DESCRIPTION
        Use Invoke-WindowsImageUpdate to update all (or selected) the images created via Add-UpdateImage in a Windows Image Tools BaseImages folder 
        New-WindowsImageTools can be use to create the structrure
        .EXAMPLE
        Invoke-WindowsImageUpdate -Path C:\WITExample
        Update all the Images created with Add-UpdateImage located in C:\WITExample\BaseImages and place the resulting VHD and WIM in c:\WITExample\UpdatedImageShare
        .EXAMPLE
        Invoke-WindowsImageUpdate -Path C:\WITExample -Name 2012r2Wmf5
        Update Image named 2012r2Wmf5_Base.vhdx  in C:\WITExample\BaseImages and place the resulting VHD and WIM in c:\WITExample\UpdatedImageShare
#>
function Invoke-WindowsImageUpdate
{
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([bool])]
    Param
    (
        # Path to the Windows Image Tools Update Folders (created via New-WindowsImageToolsExample)
        [Parameter(Mandatory = $true, 
        ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({
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
        $Path,
        # Name of the Image to update
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [Alias('FriendlyName')]
        [string[]]
        $ImageName

    )

    $ParametersToPass = @{}
    foreach ($key in ('Whatif', 'Verbose', 'Debug'))
    {
        if ($PSBoundParameters.ContainsKey($key)) 
        {
            $ParametersToPass[$key] = $PSBoundParameters[$key]
        }
    }

    #region validate input
    try
    {
        $null = Test-Path -Path "$Path\BaseImage" -ErrorAction Stop
        $null = Test-Path -Path "$Path\Resource" -ErrorAction Stop
        $null = Test-Path -Path "$Path\UpdatedImageShare" -ErrorAction Stop
        $null = Test-Path -Path "$Path\config.xml" -ErrorAction Stop
    }
    catch
    {
        throw "$Path folder structure incorrect, see New-WindowsImageToolsExample for an example"
    }
    
    if ($ImageName)
    {
        Write-Verbose -Message "[$($MyInvocation.MyCommand)] : Validateing $ImageName"
        try 
        {
            $null = Test-Path -Path "$Path\BaseImage\$($ImageName)_base.vhdx" -ErrorAction Stop
        }
        catch 
        {
            throw "$ImageName not found in $Path"
        }
        $ImageList = $ImageName
    }
    else 
    {
        Write-Verbose -Message "[$($MyInvocation.MyCommand)] : Colecting List of Images"
        $ImageList = (Get-ChildItem -Path $Path\BaseImage\*_Base.vhdx).Name -replace '_Base.vhdx', ''
    }

    $configData = Import-Clixml -Path "$Path\config.xml"

    try
    {
        Write-Verbose -Message "[$($MyInvocation.MyCommand)] : Validateing VM switch config"
        $null = Get-VMSwitch -Name $configData.VmSwitch -ErrorAction Stop
    }
    catch
    {
        throw "VM Switch Configuration in $Path incorrect Set-UpdateConfig"
    }

    #endregion
    
    #region update resorces folder
    if ($pscmdlet.ShouldProcess('PowerShell Gallery', 'Download required Modules'))
    {
        if (-not (Test-Path -Path $Path\Resource\Modules)) 
        {
            mkdir -Path $Path\Resource\Modules 
        }
        if (-not (Get-Command Save-Module))
        {
            Write-Warning -Message 'PowerShellGet missing. you will need to download required modules from PowerShell Gallery manualy'
            Write-Warning -Message 'Required Modules : PSWindowsUpdate'
        }
        else 
        {
            Write-Verbose -Message "[$($MyInvocation.MyCommand)] : Geting latest PSWindowsUpdate"
            try 
            {
                # if nuget needs updating this prompts 
                # To-Do find a way to silenty update nuget
                $null = Save-Module -Name PSWindowsUpdate -Path $Path\Resource\Modules -Force -ErrorAction Stop @ParametersToPass
            }
            catch 
            {
                if (Test-Path -Path $Path\Resource\Modules\PSWindowsUpdate)
                {
                    Write-Warning -Message "[$($MyInvocation.MyCommand)] : PSwindowsUpdate present, but unable to download latest"
                }
                else 
                {
                    throw "unable to download PSWindowsUpdate from PowerShellGalary.com, download manualy and place in $Path\Resource\Modules "
                }
            }
        }
    }
    #endregion

    #region Process Images
    foreach ($TargetImage in $ImageList)
    { 
        if ($pscmdlet.ShouldProcess($TargetImage, 'Invoke Windows Updates on Image'))
        {
            #region setup enviroment
            $BaseImage = "$Path\BaseImage\$($TargetImage)_base.vhdx"
            $UpdateImage = "$Path\BaseImage\$($TargetImage)_Update.vhdx"
            $SysprepImage = "$Path\BaseImage\$($TargetImage)_Sysprep.vhdx"
            $OutputVhd = "$Path\UpdatedImageShare\$($TargetImage).vhdx"
            $OutputWim = "$Path\UpdatedImageShare\$($TargetImage).wim"

#            cleanupFile $UpdateImage, $SysprepImage
            #endregion

            #region create Diff disk
            try 
            { 
                Write-Verbose -Message "[$($MyInvocation.MyCommand)] : Windows Update : New Diff Disk : Creating $UpdateImage from $BaseImage"
#                $null = New-VHD -Path $UpdateImage -ParentPath $BaseImage -ErrorAction Stop @ParametersToPass
            }
            catch 
            {
                throw "error creating differencing disk $UpdateImage from $BaseImage"
            }
            #endregion

            #region Inject files
            $RunWindowsUpdateAtStartup = {
                Start-Transcript -Path $PSScriptRoot\AtStartup.log -Append
                
                $IpType = 'IPTYPEPLACEHOLDER'
                $IPAddress = 'IPADDRESSPLACEHOLDER'
                $SubnetMask = 'SUBNETMASKPLACEHOLDER'
                $Gateway = 'GATEWAYPLACEHOLDER'
                $DnsServer = 'DNSPLACEHOLDER'
                
                if (-not ($IpType -eq 'DHCP'))
                {
                    Write-Verbose 'Set Network : Getting network adaptor' -Verbose
                    $adapter = Get-NetAdapter | Where-Object {
                        $_.Status -eq 'up'
                    }
                    
                    Write-Verbose "Set Network : removing existing config on $($adaptor.Name)" -Verbose
                    If (($adapter | Get-NetIPConfiguration).IPv4Address.IPAddress) 
                    {
                        $adapter | Remove-NetIPAddress -AddressFamily $IpType -Confirm:$false
                    }
                    If (($adapter | Get-NetIPConfiguration).Ipv4DefaultGateway) 
                    {
                        $adapter | Remove-NetRoute -AddressFamily $IpType -Confirm:$false
                    }
                    
                    $params = {
                        AddressFamily = $IpType
                        IPAddress = $IPAddress
                        PrefixLength = $SubnetMask
                        DefaultGateway = $Gateway
                    }
                    Write-Verbose 'Set Network : Adding settings to adaptor'
                    Write-Verbose $params -Verbose
                    $adapter | New-NetIPAddress @params
                    
                    Write-Verbose "Set Network : Set DNS to $DnsServer" -Verbose
                    $adapter | Set-DnsClientServerAddress -ServerAddresses $DnsServer  
                }

                Import-Module "$env:SystemDrive\PsTemp\Modules\PSWindowsUpdate" -Force
                
                # Run pre-update script if it exists
                if (Test-Path "$env:SystemDrive\PsTemp\PreUpdateScript.ps1") 
                {
                    Write-Verbose "Pre-Upate script : found $env:SystemDrive\PsTemp\PreUpdateScript.ps1"
                    & "$env:SystemDrive\PsTemp\PreUpdateScript.ps1"
                }

                if ((Get-WUList).Count -gt 0)
                {
                    Write-Verbose 'Windows updates : Updates needed, flaging drive as changed' -Verbose
                    Get-Date | Out-File $env:SystemDrive\PsTemp\changesMade.txt -Force
                }
                else 
                {
                    Write-Verbose 'Windows updates : No further updates' -Verbose
                
                    if(-not ($IpType -eq 'DHCP')) 
                    {
                        $adapter = Get-NetAdapter | Where-Object {
                            $_.Status -eq 'up'
                        }
                        $interface = $adapter | Get-NetIPInterface -AddressFamily $IpType

                        Write-Verbose 'Set Network : Removing static config' -Verbose
                        If ($interface.Dhcp -eq 'Disabled') 
                        {
                            If (($interface | Get-NetIPConfiguration).Ipv4DefaultGateway) 
                            {
                                $interface | Remove-NetRoute -Confirm:$false
                            }
                            $interface | Set-NetIPInterface -Dhcp Enabled
                            $interface | Set-DnsClientServerAddress -ResetServerAddresses
                        }
                    }
                    Write-Verbose 'Shuting down' -Verbose
                    Stop-Transcript
                    Stop-Computer -Force
                }
 
                # Apply all non-language updates
                Write-Verbose 'Windows updates : installing updates' -Verbose
                Get-WUInstall -AcceptAll -IgnoreReboot -IgnoreUserInput -NotCategory 'Language packs'

                # Run post-update script if it exists
                if (Test-Path "$env:SystemDrive\PsTemp\PostUpdateScript.ps1") 
                {
                    Write-Verbose "Post-Update script : found $env:SystemDrive\PsTemp\PostUpdateScript.ps1"
                    & "$env:SystemDrive\PsTemp\PostUpdateScript.ps1"
                }

 
                if (Get-WURebootStatus -Silent) 
                {
                    Write-Verbose 'Windows updates : Reboot required to finish restarting' -Verbose
                } 
                else
                {
                    Write-Verbose 'Windows updates : Restarting to check for additional updates' -Verbose
                }
                Stop-Transcript
                Restart-Computer -Force
            }

            #region add configuration data into block
            $block = $RunWindowsUpdateAtStartup | Out-String -Width 400
    
            $block = $block.Replace('IPTYPEPLACEHOLDER', $configdata.IpType)
            $block = $block.Replace('IPADDRESSPLACEHOLDER', $configdata.IPAddress)
            $block = $block.Replace('SUBNETMASKPLACEHOLDER', $configdata.SubnetMask)
            $block = $block.Replace('GATEWAYPLACEHOLDER', $configdata.Gateway)
            $block = $block.Replace('DNSPLACEHOLDER', $configdata.DnsServer)
            
            $RunWindowsUpdateAtStartup = [scriptblock]::Create($block)
            #endregion
            
            $CopyInUpdateFilesBlock = {
                if (-not (Test-Path -Path "$($driveLetter):\PsTemp"))
                {
                    $null = mkdir -Path "$($driveLetter):\PsTemp"
                }
                if (-not (Test-Path -Path "$($driveLetter):\PsTemp\Modules"))
                {
                    $null = mkdir -Path "$($driveLetter):\PsTemp\Modules"
                }
                $null = New-Item -Path "$($driveLetter):\PsTemp" -Name AtStartup.ps1 -ItemType 'file' -Value $RunWindowsUpdateAtStartup -Force
                $null = Copy-Item -Path "$Path\Resource\Modules\*" -Destination "$($driveLetter):\PsTemp\Modules\" -Recurse
            }
            Write-Verbose -Message "[$($MyInvocation.MyCommand)] : Windows Update : Adding PSWindowsUpdate Module to $UpdateImage"
            Write-Verbose -Message "[$($MyInvocation.MyCommand)] : Windows Update : updateting AtStartup script"
            MountVHDandRunBlock -vhd $UpdateImage -block $CopyInUpdateFilesBlock 

            #endregion

            #region create vm and run updates
            $vmGeneration = 1
            if ((GetVHDPartitionStyle -vhd $UpdateImage) -eq 'GPT') 
            {
                $vmGeneration = 2
            }
            $ConfigData = Get-UpdateConfig -Path $Path
            createRunAndWaitVM -vhdPath $UpdateImage -vmGeneration $vmGeneration -ConfigData $ConfigData @ParametersToPass
            #endregion

            #region Detect results - Merge or discard.
            $checkresultsBlock = {
                Test-Path -Path "$($driveLetter):\PsTemp\ChangesMade.txt"
            }
            $ChangesMade = MountVHDandRunBlock -vhd $UpdateImage -block $checkresultsBlock
            if ($ChangesMade)
            {
                Write-Verbose -Message "[$($MyInvocation.MyCommand)] : Windows Update : Changes detected : Merging $UpdateImage into $BaseImage"
#                Merge-VHD -Path $UpdateImage -DestinationPath $BaseImage @ParametersToPass
            }
            else 
            {
                Write-Verbose -Message "[$($MyInvocation.MyCommand)] : Windows Update : No changes, discarding $UpdateImage" 
#                cleanupFile $UpdateImage
            }
            #endregion

            #region Sysprep with new diff disk
            if ($ChangesMade)
            {
                try 
                { 
                    Write-Verbose -Message "[$($MyInvocation.MyCommand)] : SysPrep : New Diff Disk : Creating $SysprepImage from $BaseImage"
                    $null = New-VHD -Path $SysprepImage -ParentPath $BaseImage -ErrorAction Stop @ParametersToPass
                }
                catch 
                {
                    throw "error creating differencing disk $SysprepImage from $BaseImage"
                }
                # Sysprep ###
            }
            #endregion

            #region compact and export WIM


            #endregion
        }
    }
    #endregion
}
