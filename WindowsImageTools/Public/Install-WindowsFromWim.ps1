function Install-WindowsFromWim
{
    <#
    .Synopsis
    Populate a Disk it from a WIM
    .DESCRIPTION
    This command will Format the disk and install Windows from a WIM/ISO
    You must supply the path to a valid WIM/ISO. You should also
    include the index number for the Windows Edition to install.
    .EXAMPLE
    Install-WindowsFromWim -DiskNumber 0 -WimPath d:\Source\install.wim -NoRecoveryTools -DiskLayout UEFI
    Installs Windows to Disk Number 0 with no Recovery Partition from Index 1
    .EXAMPLE
    Install-WindowsFromWim -DiskNumber 0 -WimPath d:\Source\install.wim -index 3 -force -DiskLayout UEFI
    Installs Windows to Disk Number 0 from with recoery partition from index 3 and overwrits any existing data.
    #>
    [CmdletBinding(SupportsShouldProcess = $true,
        PositionalBinding = $false,
        ConfirmImpact = 'Medium')]
    Param
    (
        # Disk number, disk must exist
        [Parameter(Position = 0, Mandatory,
            HelpMessage = 'Disk Number based on Get-Disk')]
        [ValidateNotNullorEmpty()]
        [ValidateScript( {
                if (Get-Disk -Number $_)
                {
                    $true
                }
                else
                {
                    Throw "Disk number $_ does not exist."
                }
            })]
        [string]$DiskNumber,

        # Specifies whether to build the image for BIOS (MBR), UEFI (GPT), or WindowsToGo (MBR).
        # Generation 1 VMs require BIOS (MBR) images.  Generation 2 VMs require UEFI (GPT) images.
        # Windows To Go images will boot in UEFI or BIOS
        [Parameter(Mandatory = $true)]
        [Alias('Layout')]
        [string]
        [ValidateNotNullOrEmpty()]
        [ValidateSet('BIOS', 'UEFI', 'WindowsToGo')]
        $DiskLayout,

        # Skip creating the Recovery Environment Tools Partition.
        [switch]$NoRecoveryTools,

        # System (boot loader) Partition Size (Default : 260MB)
        [int]$SystemSize,

        # MS Reserved Partition Size (Default : 128MB)
        [int]$ReservedSize,

        # Recovery Tools Partition Size (Default : 905MB)
        [int]$RecoverySize,

        # Force the overwrite of existing files
        [switch]$force,

        # Path to WIM or ISO used to populate VHDX
        [parameter(Position = 1, Mandatory = $true,
            HelpMessage = 'Enter the path to the WIM/ISO file')]
        [ValidateScript( {
                Test-Path -Path (Get-FullFilePath -Path $_ )
            })]
        [string]$SourcePath,

        # Index of image inside of WIM (Default 1)
        [int]$Index = 1,

        # Path to file to copy inside of VHD(X) as C:\unattent.xml
        [ValidateScript( {
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

        # Native Boot does not have the boot code inside the VHD(x) it must exist on the physical disk.
        [switch]$NativeBoot,

        # Features to turn on (in DISM format)
        [ValidateNotNullOrEmpty()]
        [string[]]$Feature,

        # Feature to remove (in DISM format)
        [ValidateNotNullOrEmpty()]
        [string[]]$RemoveFeature,

        # Feature Source path. If not provided, all ISO and WIM images in $sourcePath searched
        [ValidateNotNullOrEmpty()]
        [ValidateScript( {
                (Test-Path -Path $(Resolve-Path $_) -or ($_ -eq 'NONE') )
            })]
        [string]$FeatureSource,

        # Feature Source index. If the source is a .wim provide an index Default =1
        [int]$FeatureSourceIndex = 1,

        # Path to drivers to inject
        [ValidateNotNullOrEmpty()]
        [ValidateScript( {
                foreach ($Path in $_)
                {
                    Test-Path -Path $(Resolve-Path $Path)
                }
            })]
        [string[]]$Driver,

        # Add payload for all removed features
        [switch]$AddPayloadForRemovedFeature,

        # Path of packages to install via DSIM
        [ValidateNotNullOrEmpty()]
        [ValidateScript( {
                foreach ($Path in $_)
                {
                    Test-Path -Path $(Resolve-Path $Path)
                }
            })]
        [string[]]$Package,
        # Files/Folders to copy to root of Windows Drive (to place files in directories mimic the direcotry structure off of C:\)
        [ValidateNotNullOrEmpty()]
        [ValidateScript( {
                foreach ($Path in $_)
                {
                    Test-Path -Path $(Resolve-Path $Path)
                }
            })]
        [string[]]$filesToInject

    )
    $SourcePath = $SourcePath | Get-FullFilePath

    if ($pscmdlet.ShouldProcess("[$($MyInvocation.MyCommand)] : Overwrite partitions on disk [$DiskNumber] with content of [$SourcePath]",
            "Overwrite partitions on disk [$DiskNumber] with contentce of [$SourcePath]? ",
            'Overwrite WARNING!'))
    {
        if ((Get-Disk -Number $DiskNumber | Get-Partition -ErrorAction SilentlyContinue) -Or $force -Or $pscmdlet.ShouldContinue('Are you sure? Any existin data will be lost!', 'Warning'))
        {
            $ParametersToPass = @{ }
            foreach ($key in ('Whatif', 'Verbose', 'Debug'))
            {
                if ($PSBoundParameters.ContainsKey($key))
                {
                    $ParametersToPass[$key] = $PSBoundParameters[$key]
                }
            }

            $InitializeDiskPartitionParam = @{
                'DiskNumber' = $DiskNumber
                'force'      = $true
                'DiskLayout' = $DiskLayout
            }
            if ($NoRecoveryTools)
            {
                $InitializeDiskPartitionParam.add('NoRecoveryTools', $true)
            }
            if ($Dynamic)
            {
                $InitializeDiskPartitionParam.add('Dynamic', $true)
            }
            if ($SystemSize) { $InitializeDiskPartitionParam.add('SystemSize', $SystemSize) }
            if ($ReservedSize) { $InitializeDiskPartitionParam.add('ReservedSize', $ReservedSize) }
            if ($RecoverySize) { $InitializeDiskPartitionParam.add('RecoverySize', $RecoverySize) }

            $SetDiskPartitionParam = @{
                'SourcePath' = $SourcePath
                'DiskNumber' = $DiskNumber
                'Index'      = $Index
                'force'      = $true
                'Confirm'    = $false
            }
            if ($Unattend)
            {
                $SetDiskPartitionParam.add('Unattend', $Unattend)
            }
            if ($NativeBoot)
            {
                $SetDiskPartitionParam.add('NativeBoot', $NativeBoot)
            }
            if ($Feature)
            {
                $SetDiskPartitionParam.add('Feature', $Feature)
            }
            if ($RemoveFeature)
            {
                $SetDiskPartitionParam.add('RemoveFeature', $RemoveFeature)
            }
            if ($FeatureSource)
            {
                $SetDiskPartitionParam.add('FeatureSource', $FeatureSource)
            }
            if ($FeatureSourceIndex)
            {
                $SetDiskPartitionParam.add('FeatureSourceIndex', $FeatureSourceIndex)
            }
            if ($AddPayloadForRemovedFeature)
            {
                $SetDiskPartitionParam.add('AddPayloadForRemovedFeature', $AddPayloadForRemovedFeature)
            }
            if ($Driver)
            {
                $SetDiskPartitionParam.add('Driver', $Driver)
            }
            if ($Package)
            {
                $SetDiskPartitionParam.add('Package', $Package)
            }
            if ($filesToInject)
            {
                $SetDiskPartitionParam.add('filesToInject', $filesToInject)
            }
            Write-Verbose -Message "[$($MyInvocation.MyCommand)] : InitializeDiskPartitionParam"
            Write-Verbose -Message ($InitializeVHDPartitionParam | Out-String)
            Write-Verbose -Message "[$($MyInvocation.MyCommand)] : SetDiskPartitionParam"
            Write-Verbose -Message ($SetDiskPartitionParam | Out-String)
            Write-Verbose -Message "[$($MyInvocation.MyCommand)] : ParametersToPass"
            Write-Verbose -Message ($ParametersToPass | Out-String)

            Try
            {
                Initialize-DiskPartition @InitializeDiskPartitionParam @ParametersToPass
                Set-DiskPartition @SetDiskPartitionParam @ParametersToPass
            }
            Catch
            {
                throw "$($_.Exception.Message) at $($_.Exception.InvocationInfo.ScriptLineNumber)"
            }
        }
    }
}


