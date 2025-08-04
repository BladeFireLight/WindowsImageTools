function Initialize-VHDPartition {
    <#
    .SYNOPSIS
    Creates a VHD or VHDX file with partitions needed to be bootable.

    .DESCRIPTION
    Creates a VHD or VHDX file with the specified layout (BIOS, UEFI, Data, WindowsToGo), size, and partitioning options. Supports dynamic or fixed disks, formatting, allocation unit size, recovery partition creation, and overwrite options. Use -RecoveryTools and -RecoveryImage to create recovery partitions.

    .EXAMPLE
    Initialize-VHDPartition -Path d:\disks\disk001.vhdx -Dynamic -Size 30GB -DiskLayout BIOS -SystemSize 260MB -ReservedSize 128MB -RecoverySize 905MB -DataFormat NTFS -AllocationUnitSize 64kb -PassThru -NoRecoveryTools -force

    Creates a dynamic VHDX file at d:\disks\disk001.vhdx with BIOS layout, specified partition sizes, NTFS format, allocation unit size, skips recovery tools partition, outputs disk image object, and forces overwrite if file exists.

    .EXAMPLE
    Initialize-VHDPartition -Path d:\disks\disk001.vhdx -Dynamic -Size 40GB -DiskLayout UEFI -SystemSize 260MB -ReservedSize 128MB -RecoverySize 905MB -DataFormat NTFS -AllocationUnitSize 64kb -PassThru -NoRecoveryTools -force

    Creates a dynamic VHDX file at d:\disks\disk001.vhdx with UEFI layout, specified partition sizes, NTFS format, allocation unit size, skips recovery tools partition, outputs disk image object, and forces overwrite if file exists.

    .EXAMPLE
    Initialize-VHDPartition -Path d:\disks\disk001.vhdx -Dynamic -Size 40GB -DiskLayout Data -SystemSize 260MB -ReservedSize 128MB -RecoverySize 905MB -DataFormat ReFS -AllocationUnitSize 64kb -PassThru -NoRecoveryTools -force

    Creates a dynamic VHDX file at d:\disks\disk001.vhdx with Data layout, specified partition sizes, ReFS format, allocation unit size, skips recovery tools partition, outputs disk image object, and forces overwrite if file exists.

    .NOTES
    Helper for VHD(X) creation and bootable partition layout automation.
    #>
    [CmdletBinding(SupportsShouldProcess,
        PositionalBinding = $false,
        ConfirmImpact = 'Medium')]
    Param
    (
        # Path to the new VHDX file (Must end in .vhd, or .vhdx)
        [Parameter(Position = 0, Mandatory,
            HelpMessage = 'Enter the path for the new VHD/VHDX file')]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern(".\.vhdx?$")]
        [ValidateScript( {
                if (Get-FullFilePath -Path $_ |
                    Split-Path |
                    Resolve-Path ) {
                    $true
                } else {
                    Throw "Parent folder for $_ does not exist."
                }
            })]
        [string]$Path,

        # Size in Bytes (Default 80B)
        [uint64]$Size = 80GB,

        # System (boot loader) Partition Size (Default : 260MB)
        [int]$SystemSize,

        # MS Reserved Partition Size (Default : 128MB)
        [int]$ReservedSize,

        # Recovery Tools Partition Size (Default : 905MB)
        [int]$RecoverySize,

        # Create Dynamic disk
        [switch]$Dynamic,

        # Specifies whether to build the image for BIOS (MBR), UEFI (GPT), Data (GPT), or WindowsToGo (MBR).
        # Generation 1 VMs require BIOS (MBR) images and have one partition. Generation 2 VMs require
        # UEFI (GPT) images and have 3-5 partitions.
        # Windows To Go images will boot in UEFI or BIOS
        [Parameter(Mandatory)]
        [Alias('Layout')]
        [string]
        [ValidateNotNullOrEmpty()]
        [ValidateSet('BIOS', 'UEFI', 'WindowsToGo', 'Data')]
        $DiskLayout,

        # Format drive as NTFS or ReFS (Only applies when DiskLayout = Data)
        [string]
        [ValidateNotNullOrEmpty()]
        [ValidateSet('NTFS', 'ReFS')]
        $DataFormat = 'ReFS',

        # Allocation Unit Size to format the primary partition
        [int]
        [ValidateSet(4kb, 8kb, 16kb, 32kb, 64kb, 128kb, 256kb, 512kb, 1024kb, 2048kb)]
        $AllocationUnitSize,

        # Output the disk image object
        [switch]$PassThru,

        # Create the Recovery Environment Tools Partition. Only valid on UEFI layout
        [switch]$NoRecoveryTools,

        # Force the overwrite of existing files
        [switch]$force
    )
    Begin {


        if ($PsCmdlet.ShouldProcess("[$($MyInvocation.MyCommand)] Create partition structure for Bootable vhd(x) on [$Path]",
                "Replace existing file [$Path] ? ",
                'Overwrite WARNING!')) {
            if ((-not (Test-Path $Path)) -Or
                $force -Or
                ((Test-Path $Path) -and $PsCmdlet.ShouldContinue("TargetFile [$Path] exists! Any existing data will be lost!", 'Warning'))) {

                $ParametersToPass = @{ }
                foreach ($key in ('WhatIf', 'Verbose', 'Debug')) {
                    if ($PSBoundParameters.ContainsKey($key)) {
                        $ParametersToPass[$key] = $PSBoundParameters[$key]
                    }
                }

                #region Validate input

                $VHDFormat = ([IO.FileInfo]$Path).Extension.split('.')[-1]

                if (($DiskLayout -eq 'UEFI') -and ($VHDFormat -eq 'VHD')) {
                    throw 'UEFI disks must be in VHDX format. Please change the path to end in VHDX'
                }

                # Enforce max VHD size.
                if ('VHD' -ilike $VHDFormat) {
                    if ($Size -gt 2040GB) {
                        Write-Warning -Message 'For the VHD file format, the maximum file size is ~2040GB.  Resetting size to 2040GB.'
                        $Size = 2040GB
                    }
                }

                $fileName = Split-Path -Leaf -Path $Path

                # make paths absolute
                $Path = $Path | Get-FullFilePath
                #endregion

                # if we get this far it's ok to delete existing files. Save the ACL for the new file
                $Acl = $null
                if (Test-Path -Path $Path) {
                    $Acl = Get-Acl -Path $Path
                    Remove-Item -Path $Path
                }
                Write-Verbose -Message "[$($MyInvocation.MyCommand)] [$fileName] : Creating"

                #region Create VHD
                Try {
                    Add-WindowsImageType
                    $vhdParams = @{
                        Path    = $Path
                        Size    = $Size
                        Dynamic = $Dynamic
                        Force   = $force
                    }
                    If (-not $Dynamic) {
                        Write-Warning -Message 'Creating a Fixed Disk May take a long time!'
                    }
                    Write-Verbose -Message "[$($MyInvocation.MyCommand)] [$fileName] : Params for New-DpVhd"
                    Write-Verbose -Message ($vhdParams | Out-String)
                    #New-DpVhd @vhdParams
                    If ($Dynamic) {
                        Write-Verbose -Message "[$($MyInvocation.MyCommand)] [$fileName] : Params for [WIM2VHD.VirtualHardDisk]::CreateSparseDisk()"
                        Write-Verbose -Message ($vhdParams | Out-String)
                        $null = [WIM2VHD.VirtualHardDisk]::CreateSparseDisk(
                            $VHDFormat,
                            $Path,
                            $Size,
                            $true
                        )
                    } else {
                        Write-Verbose -Message "[$($MyInvocation.MyCommand)] [$fileName] : Params for [WIM2VHD.VirtualHardDisk]::CreateFixedDisk()"
                        Write-Verbose -Message ($vhdParams | Out-String)
                        Write-Warning -Message 'Creating a Fixed Disk May take a long time!'
                        $null = [WIM2VHD.VirtualHardDisk]::CreateFixedDisk(
                            $VHDFormat,
                            $Path,
                            $Size,
                            $true
                        )

                    }
                } catch {
                    Throw "Failed to create $Path. $($_.Exception.Message)"
                }

                #endregion

                if (Test-Path -Path $Path) {
                    if ($Acl) {
                        Set-Acl -Path $Path -AclObject $Acl
                    }
                    #region Mount Image
                    try {
                        Write-Verbose -Message "[$($MyInvocation.MyCommand)] [$fileName] : Mounting disk image"
                        $disk = Mount-DiskImage -ImagePath $Path -PassThru |
                        Get-DiskImage |
                        Get-Disk
                    } catch {
                        throw $_.Exception.Message
                    }
                    #endregion
                } else {
                    Throw "Failed to create vhd"
                }

                #region Create partitions
                try {
                    $InitializeDiskParam = @{
                        DiskNumber = $disk.Number
                        DiskLayout = $DiskLayout
                        force      = $force
                    }
                    if ($DataFormat) { $InitializeDiskParam.add('DataFormat', $DataFormat) }
                    if ($NoRecoveryTools) { $InitializeDiskParam.add('NoRecoveryTools', $NoRecoveryTools) }
                    if ($SystemSize) { $InitializeDiskParam.add('SystemSize', $SystemSize) }
                    if ($ReservedSize) { $InitializeDiskParam.add('ReservedSize', $ReservedSize) }
                    if ($RecoverySize) { $InitializeDiskParam.add('RecoverySize', $RecoverySize) }
                    if ($AllocationUnitSize) { $InitializeDiskParam.add('AllocationUnitSize', $AllocationUnitSize) }

                    $null = Initialize-DiskPartition @ParametersToPass @InitializeDiskParam
                    #endregion
                }

                catch {
                    Write-Error -Message "[$($MyInvocation.MyCommand)] [$fileName] : Creating Partitions"
                    throw $_.Exception.Message
                }
                #region Dismount
                finally {
                    Write-Verbose -Message "[$($MyInvocation.MyCommand)] [$fileName] : Dismounting disk image"
                    $null = Dismount-DiskImage -ImagePath $Path
                    [System.GC]::Collect()
                }
                #endregion
                if ($PassThru) {
                    #write the new disk object to the pipeline
                    Get-DiskImage -ImagePath $Path
                }
            }
        }
    }
}
