function Convert-Wim2VHD
{
    <#
            .Synopsis
            Create a VHDX and populate it from a WIM
            .DESCRIPTION
            This command will update partitions for a Generate 2 VHDX file, configured for UEFI. 
            You must supply the path to the VHDX file and a valid WIM. You should also
            include the index number for the Windows Edition to install.
            .EXAMPLE
            Convert-WIM2VHDX -Path c:\windows8.vhdx -WimPath d:\Source\install.wim -Recovery
            .EXAMPLE
            Convert-WIM2VHDX -Path c:\windowsServer.vhdx -WimPath d:\Source\install.wim -index 3 -Size 40GB -force
    #>
    [CmdletBinding(SupportsShouldProcess = $true, 
            PositionalBinding = $false,
    ConfirmImpact = 'Medium')]
    Param
    (
        # Path to the new VHDX file (Must end in .vhdx)
        [Parameter(Position = 0,Mandatory = $true,
        HelpMessage = 'Enter the path for the new VHDX file')]
        [ValidateNotNullorEmpty()]
        [ValidatePattern(".\.vhdx?$")]
        [ValidateScript({
                    if (get-FullFilePath -Path $_ |
                        Split-Path  |
                    Resolve-Path ) 
                    {
                        $true
                    }
                    else 
                    {
                        Throw "Parent folder for $_ does not exist."
                    }
        })]
        [string]$Path,
        
        # Size in Bytes (Default 40B)
        [ValidateRange(25GB,64TB)]
        [uint64]$Size = 40GB,
        
        # Create Dynamic disk
        [switch]$Dynamic,

        # Specifies whether to create a VHD or VHDX formatted Virtual Hard Disk.
        # The default is AUTO, which will create a VHD if using the BIOS disk layout or 
        # VHDX if using UEFI or WindowsToGo layouts. The extention in -path must match.
        [Alias('Format')]
        [string]
        [ValidateNotNullOrEmpty()]
        [ValidateSet('VHD', 'VHDX', 'AUTO')]
        $VHDFormat        = 'AUTO',

        # Specifies whether to build the image for BIOS (MBR), UEFI (GPT), or WindowsToGo (MBR).
        # Generation 1 VMs require BIOS (MBR) images.  Generation 2 VMs require UEFI (GPT) images.
        # Windows To Go images will boot in UEFI or BIOS
        [Parameter(Mandatory = $true)]
        [Alias('Layout')]
        [string]
        [ValidateNotNullOrEmpty()]
        [ValidateSet('BIOS', 'UEFI', 'WindowsToGo')]
        $DiskLayout,

        # Create the Recovery Enviroment Tools Partition. Only valid on UEFI layout
        [switch]$RecoveryTools,

        # Create the Recovery Enviroment Tools and Recovery Image Partitions. Only valid on UEFI layout
        [switch]$RecoveryImage,

        # Force the overwrite of existing files
        [switch]$force,
        
        # Path to WIM or ISO used to populate VHDX
        [parameter(Position = 1,Mandatory = $true,
        HelpMessage = 'Enter the path to the WIM/ISO file')]
        [ValidateScript({
                    Test-Path -Path (get-FullFilePath -Path $_ )
        })]
        [string]$SourcePath,
        
        # Index of image inside of WIM (Default 1)
        [int]$Index = 1,
        
        # Path to file to copy inside of VHD(X) as C:\unattent.xml
        [ValidateScript({
                    if ($_)
                    {
                        Test-Path -Path $_
                    }
                    else 
                    {
                        $true
                    }
        })]
        [string]$Unattend,

        # Native Boot does not have the boot code iniside the VHD(x) it must exist on the phisical disk. 
        [switch]$NativeBoot,

        # Featurs to turn on (in DISM format)
        [ValidateNotNullOrEmpty()]
        [string[]]$Feature,

        # Path to drivers to inject
        [ValidateNotNullOrEmpty()]
        [ValidateScript({
                    Test-Path -Path $(Resolve-Path $_)
        })]
        [string[]]$Driver,

        # Path of packages to install via DSIM
        [ValidateNotNullOrEmpty()]
        [ValidateScript({
                    Test-Path -Path $(Resolve-Path $_)
        })]
        [string[]]$Package
    )
    $Path = $Path | get-FullFilePath 
    $SourcePath = $SourcePath | get-FullFilePath

    $VhdxFileName = Split-Path -Leaf -Path $Path

    if ($pscmdlet.ShouldProcess("[$($MyInvocation.MyCommand)] : Overwrite partitions inside [$Path] with content of [$SourcePath]",
            "Overwrite partitions inside [$Path] with contentce of [$SourcePath]? ",
    'Overwrite WARNING!'))
    {
        if((-not (Test-Path $Path)) -Or $force -Or $pscmdlet.ShouldContinue('Are you sure? Any existin data will be lost!', 'Warning')) 
        {
            $ParametersToPass = @{}
            foreach ($key in ('Whatif', 'Verbose', 'Debug'))
            {
                if ($PSBoundParameters.ContainsKey($key)) 
                {
                    $ParametersToPass[$key] = $PSBoundParameters[$key]
                }
            }
        
            $InitializeVHDPartitionParam = @{
                'Size'       = $Size
                'Path'       = $Path
                'force'      = $true
                'DiskLayout' = $DiskLayout
            }
            if ($RecoveryTools)
            {
                $InitializeVHDPartitionParam.add('RecoveryTools', $true)
            }
            if ($RecoveryImage)
            {
                $InitializeVHDPartitionParam.add('RecoveryImage', $true)
            }
            if ($Dynamic)
            {
                $InitializeVHDPartitionParam.add('Dynamic', $true)
            }
            $SetVHDPartitionParam = @{
                'SourcePath' = $SourcePath
                'Path'       = $Path
                'Index'      = $Index
                'force'      = $true
                'Confirm'    = $false
            }
            if ($Unattend)
            {
                $SetVHDPartitionParam.add('Unattend', $Unattend)
            }
            if ($NativeBoot)
            {
                $SetVHDPartitionParam.add('NativeBoot', $NativeBoot)
            }
            if ($Feature)
            {
                $SetVHDPartitionParam.add('Feature', $Feature)
            }
            if ($Driver)
            {
                $SetVHDPartitionParam.add('Driver', $Driver)
            }
            if ($Package)
            {
                $SetVHDPartitionParam.add('Package', $Package)
            }
            Write-Verbose -Message "[$($MyInvocation.MyCommand)] : InitializeVHDPartitionParam"
            Write-Verbose -Message ($InitializeVHDPartitionParam | Out-String)
            Write-Verbose -Message "[$($MyInvocation.MyCommand)] : SetVHDPartitionParam"
            Write-Verbose -Message ($SetVHDPartitionParam | Out-String)
            Write-Verbose -Message "[$($MyInvocation.MyCommand)] : ParametersToPass"
            Write-Verbose -Message ($ParametersToPass | Out-String)
            
            Try
            {
                Initialize-VHDPartition @InitializeVHDPartitionParam @ParametersToPass 
                Set-VHDPartition @SetVHDPartitionParam @ParametersToPass
            }
            Catch
            {
                throw "$($_.Exception.Message) at $($_.Exception.InvocationInfo.ScriptLineNumber)"
            }
        }
    }
}


