function Initialize-VHDPartition
{
    <#
    .Synopsis
    Create VHD(X) with partitions needed to be bootable
    .DESCRIPTION
    This command will create a VHD or VHDX file. Supported layours are: BIOS, UEFI, Data or WindowsToGo.

    To create a recovery partitions use -RecoveryTools and -RecoveryImage

    .EXAMPLE
    Initialize-VHDPartition d:\disks\disk001.vhdx -dynamic -size 30GB -DiskLayout BIOS
    .EXAMPLE
    Initialize-VHDPartition d:\disks\disk001.vhdx -dynamic -size 40GB -DiskLayout UEFI -RecoveryTools
    .NOTES
    General notes
    #>
    [CmdletBinding(SupportsShouldProcess,
        PositionalBinding = $false,
        ConfirmImpact = 'Medium')]
    Param
    (
        # Path to the new VHDX file (Must end in .vhd, or .vhdx)
        [Parameter(Position = 0, Mandatory,
            HelpMessage = 'Enter the path for the new VHD/VHDX file')]
        [ValidateNotNullorEmpty()]
        [ValidatePattern(".\.vhdx?$")]
        [ValidateScript( {
                if (Get-FullFilePath -Path $_ |
                    Split-Path |
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

        # Size in Bytes (Default 80B)
        [ValidateRange(25GB, 64TB)]
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

        # Output the disk image object
        [switch]$Passthru,

        # Create the Recovery Environment Tools Partition. Only valid on UEFI layout
        [switch]$NoRecoveryTools,

        # Force the overwrite of existing files
        [switch]$force
    )
    Begin
    {


        if ($pscmdlet.ShouldProcess("[$($MyInvocation.MyCommand)] Create partition structure for Bootable vhd(x) on [$Path]",
                "Replace existing file [$Path] ? ",
                'Overwrite WARNING!'))
        {
            if ((-not (Test-Path $Path)) -Or
                $force -Or
                ((Test-Path $Path) -and $pscmdlet.ShouldContinue("TargetFile [$Path] exists! Any existin data will be lost!", 'Warning')))
            {

                $ParametersToPass = @{ }
                foreach ($key in ('Whatif', 'Verbose', 'Debug'))
                {
                    if ($PSBoundParameters.ContainsKey($key))
                    {
                        $ParametersToPass[$key] = $PSBoundParameters[$key]
                    }
                }

                #region Validate input

                $VHDFormat = ([IO.FileInfo]$Path).Extension.split('.')[-1]

                if (($DiskLayout -eq 'UEFI') -and ($VHDFormat -eq 'VHD'))
                {
                    throw 'UEFI disks must be in VHDX format. Please change the path to end in VHDX'
                }

                # Enforce max VHD size.
                if ('VHD' -ilike $VHDFormat)
                {
                    if ($Size -gt 2040GB)
                    {
                        Write-Warning -Message 'For the VHD file format, the maximum file size is ~2040GB.  Reseting size to 2040GB.'
                        $Size = 2040GB
                    }
                }

                $fileName = Split-Path -Leaf -Path $Path

                # make paths absolute
                $Path = $Path | Get-FullFilePath
                #endregion

                # if we get this far it's ok to delete existing files. Save the ACL for the new file
                $Acl = $null
                if (Test-Path -Path $Path)
                {
                    $Acl = Get-Acl -Path $Path
                    Remove-Item -Path $Path
                }
                Write-Verbose -Message "[$($MyInvocation.MyCommand)] [$fileName] : Creating"

                #region Create VHD
                Try
                {
                    $vhdParams = @{
                        VHDFormat = $VHDFormat
                        Path      = $Path
                        SizeBytes = $Size
                    }

                    If ($Dynamic)
                    {
                        Write-Verbose -Message "[$($MyInvocation.MyCommand)] [$fileName] : Params for [WIM2VHD.VirtualHardDisk]::CreateSparseDisk()"
                        Write-Verbose -Message ($vhdParams | Out-String)
                        $null = [WIM2VHD.VirtualHardDisk]::CreateSparseDisk(
                            $VHDFormat,
                            $Path,
                            $Size,
                            $true
                        )
                    }
                    else
                    {
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
                }
                catch
                {
                    Throw "Failed to create $Path. $($_.Exception.Message)"
                }

                #endregion

                if (Test-Path -Path $Path)
                {
                    if ($Acl)
                    {
                        Set-Acl -Path $Path -AclObject $Acl
                    }
                    #region Mount Image
                    try
                    {
                        Write-Verbose -Message "[$($MyInvocation.MyCommand)] [$fileName] : Mounting disk image"
                        $disk = Mount-DiskImage -ImagePath $Path -PassThru |
                        Get-DiskImage |
                        Get-Disk
                    }
                    catch
                    {
                        throw $_.Exception.Message
                    }
                    #endregion
                }
                else
                {
                    Throw "Failed to create vhd"
                }

                #region Create partitions
                try
                {
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

                    $null = Initialize-DiskPartition @ParametersToPass @InitializeDiskParam
                    #endregion
                }

                catch
                {
                    Write-Error -Message "[$($MyInvocation.MyCommand)] [$fileName] : Creating Partitions"
                    throw $_.Exception.Message
                }
                #region Dismount
                finally
                {
                    Write-Verbose -Message "[$($MyInvocation.MyCommand)] [$fileName] : Dismounting disk image"
                    $null = Dismount-DiskImage -ImagePath $Path
                    [System.GC]::Collect()
                }
                #endregion
                if ($Passthru)
                {
                    #write the new disk object to the pipeline
                    Get-DiskImage -ImagePath $Path
                }
            }
        }
    }
}
