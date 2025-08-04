function Install-WindowsFromWim {
    <#
    .SYNOPSIS
    Formats a disk and installs Windows from a WIM or ISO image.

    .DESCRIPTION
    This command formats the specified disk and installs Windows from a provided WIM or ISO image. You must supply the disk number and the path to a valid WIM or ISO file. You can specify the index number for the Windows edition to install, disk layout, partition sizes, features, drivers, packages, and more. The function supports overwriting existing data and skipping the recovery partition.

    .PARAMETER DiskNumber
    The disk number to format and install Windows to. Must exist and be visible to Get-Disk.

    .PARAMETER DiskLayout
    Specifies the disk layout: BIOS (MBR), UEFI (GPT), or WindowsToGo (MBR).

    .PARAMETER NoRecoveryTools
    If specified, skips creation of the recovery tools partition.

    .PARAMETER SystemSize
    Size of the system (boot loader) partition in MB. Default is 260MB.

    .PARAMETER ReservedSize
    Size of the MS Reserved partition in MB. Default is 128MB.

    .PARAMETER RecoverySize
    Size of the recovery tools partition in MB. Default is 905MB.

    .PARAMETER Force
    If specified, overwrites any existing partitions or data on the disk.

    .PARAMETER SourcePath
    The path to the WIM or ISO file used to install Windows.

    .PARAMETER Index
    The index of the image inside the WIM. Default is 1.

    .PARAMETER Unattend
    Path to an unattend.xml file to copy into the installed Windows image.

    .PARAMETER NativeBoot
    If specified, prepares the disk for native boot.

    .PARAMETER Feature
    Features to enable (in DISM format).

    .PARAMETER RemoveFeature
    Features to remove (in DISM format).

    .PARAMETER FeatureSource
    Path to feature source files or folders.

    .PARAMETER FeatureSourceIndex
    Index for feature source WIM. Default is 1.

    .PARAMETER Driver
    Paths to drivers to inject.

    .PARAMETER AddPayloadForRemovedFeature
    If specified, adds payload for all removed features.

    .PARAMETER Package
    Paths to packages to install via DISM.

    .PARAMETER filesToInject
    Files or folders to copy to the root of the Windows drive.

    .EXAMPLE
    Install-WindowsFromWim -DiskNumber 0 -SourcePath d:\Source\install.wim -NoRecoveryTools -DiskLayout UEFI

    Installs Windows to disk number 0 with no recovery partition from index 1.

    .EXAMPLE
    Install-WindowsFromWim -DiskNumber 0 -SourcePath d:\Source\install.wim -Index 3 -Force -DiskLayout UEFI

    Installs Windows to disk number 0 from index 3, overwriting any existing data.

    .NOTES
    Author: WindowsImageTools Team
    Requires: Administrator privileges
    #>
    [CmdletBinding(SupportsShouldProcess = $true,
        PositionalBinding = $false,
        ConfirmImpact = 'Medium')]
    Param
    (
        # Disk number, disk must exist
        [Parameter(Position = 0, Mandatory,
            HelpMessage = 'Disk Number based on Get-Disk')]
        [ValidateNotNullOrEmpty()]
        [ValidateScript( {
                if (Get-Disk -Number $_) {
                    $true
                } else {
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

        # Path to file to copy inside of VHD(X) as C:\unattend.xml
        [ValidateScript( {
                if ($_) {
                    Test-Path -Path $_
                } else {
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
                foreach ($Path in $_) {
                    Test-Path -Path $(Resolve-Path $Path)
                }
            })]
        [string[]]$Driver,

        # Add payload for all removed features
        [switch]$AddPayloadForRemovedFeature,

        # Path of packages to install via DISM
        [ValidateNotNullOrEmpty()]
        [ValidateScript( {
                foreach ($Path in $_) {
                    Test-Path -Path $(Resolve-Path $Path)
                }
            })]
        [string[]]$Package,
        # Files/Folders to copy to root of Windows Drive (to place files in directories mimic the directory structure off of C:\)
        [ValidateNotNullOrEmpty()]
        [ValidateScript( {
                foreach ($Path in $_) {
                    Test-Path -Path $(Resolve-Path $Path)
                }
            })]
        [string[]]$filesToInject,

        # Use DISM for expansion instead of native PowerShell
        [Parameter(HelpMessage = 'Use DISM for expansion instead of native PowerShell')]
        [switch]$UseDismExpansion

    )
    $SourcePath = $SourcePath | Get-FullFilePath

    if ($psCmdlet.ShouldProcess("[$($MyInvocation.MyCommand)] : Overwrite partitions on disk [$DiskNumber] with content of [$SourcePath]",
            "Overwrite partitions on disk [$DiskNumber] with content of [$SourcePath]? ",
            'Overwrite WARNING!')) {
        if ((Get-Disk -Number $DiskNumber | Get-Partition -ErrorAction SilentlyContinue) -Or $force -Or $psCmdlet.ShouldContinue('Are you sure? Any existing data will be lost!', 'Warning')) {
            $ParametersToPass = @{ }
            foreach ($key in ('WhatIf', 'Verbose', 'Debug')) {
                if ($PSBoundParameters.ContainsKey($key)) {
                    $ParametersToPass[$key] = $PSBoundParameters[$key]
                }
            }

            $InitializeDiskPartitionParam = @{
                'DiskNumber' = $DiskNumber
                'force'      = $true
                'DiskLayout' = $DiskLayout
            }
            if ($NoRecoveryTools) {
                $InitializeDiskPartitionParam.add('NoRecoveryTools', $true)
            }
            if ($Dynamic) {
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
            if ($Unattend) {
                $SetDiskPartitionParam.add('Unattend', $Unattend)
            }
            if ($NativeBoot) {
                $SetDiskPartitionParam.add('NativeBoot', $NativeBoot)
            }
            if ($Feature) {
                $SetDiskPartitionParam.add('Feature', $Feature)
            }
            if ($RemoveFeature) {
                $SetDiskPartitionParam.add('RemoveFeature', $RemoveFeature)
            }
            if ($FeatureSource) {
                $SetDiskPartitionParam.add('FeatureSource', $FeatureSource)
            }
            if ($FeatureSourceIndex) {
                $SetDiskPartitionParam.add('FeatureSourceIndex', $FeatureSourceIndex)
            }
            if ($AddPayloadForRemovedFeature) {
                $SetDiskPartitionParam.add('AddPayloadForRemovedFeature', $AddPayloadForRemovedFeature)
            }
            if ($Driver) {
                $SetDiskPartitionParam.add('Driver', $Driver)
            }
            if ($Package) {
                $SetDiskPartitionParam.add('Package', $Package)
            }
            if ($filesToInject) {
                $SetDiskPartitionParam.add('filesToInject', $filesToInject)
            }
            if ($PSBoundParameters.ContainsKey('UseDismExpansion')) {
                $SetDiskPartitionParam.add('UseDismExpansion', $UseDismExpansion.IsPresent)
            }
            Write-Verbose -Message "[$($MyInvocation.MyCommand)] : InitializeDiskPartitionParam"
            Write-Verbose -Message ($InitializeVHDPartitionParam | Out-String)
            Write-Verbose -Message "[$($MyInvocation.MyCommand)] : SetDiskPartitionParam"
            Write-Verbose -Message ($SetDiskPartitionParam | Out-String)
            Write-Verbose -Message "[$($MyInvocation.MyCommand)] : ParametersToPass"
            Write-Verbose -Message ($ParametersToPass | Out-String)

            Try {
                Initialize-DiskPartition @InitializeDiskPartitionParam @ParametersToPass
                Set-DiskPartition @SetDiskPartitionParam @ParametersToPass
            } Catch {
                throw "$($_.Exception.Message) at $($_.Exception.InvocationInfo.ScriptLineNumber)"
            }
        }
    }
}


