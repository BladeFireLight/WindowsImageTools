function New-DataVHD {
    <#
    .SYNOPSIS
    Creates a VHD or VHDX data drive with GPT partitions.

    .DESCRIPTION
    This command creates a VHD or VHDX file with a GPT partition table, formatted as ReFS (default) or NTFS. You must supply the path to the VHD/VHDX file. Use -Force to overwrite an existing file (ACLs will be copied to the new file). Supports dynamic disks, allocation unit size, reserved partition size, and more.

    .PARAMETER Path
    The path to the new VHD or VHDX file. Must end in .vhd or .vhdx.

    .PARAMETER DataFormat
    The file system format for the data drive. Valid values are NTFS or ReFS. Default is ReFS.

    .PARAMETER AllocationUnitSize
    The allocation unit size to use when formatting the primary partition. Valid values are 4kb, 8kb, 16kb, 32kb, 64kb, 128kb, 256kb, 512kb, 1024kb, 2048kb.

    .PARAMETER Size
    The size of the VHD(X) in bytes. Default is 40GB. Minimum is 100MB, maximum is 64TB.

    .PARAMETER ReservedSize
    The size of the MS Reserved partition in MB. Default is 128MB.

    .PARAMETER Dynamic
    If specified, creates a dynamic disk.

    .PARAMETER Force
    If specified, overwrites any existing file.

    .EXAMPLE
    New-DataVHD -Path c:\Data.vhdx -Size 20GB -Dynamic

    Creates a new 20GB dynamic Data VHDX formatted as ReFS.

    .EXAMPLE
    New-DataVHD -Path c:\data.vhdx -Size 100GB -DataFormat NTFS

    Creates a new 100GB Data VHDX formatted as NTFS.

    .NOTES
    Author: WindowsImageTools Team
    Requires: Administrator privileges
    #>
    [CmdletBinding(SupportsShouldProcess = $true,
        PositionalBinding = $false,
        ConfirmImpact = 'Medium')]
    Param
    (
        # Path to the new VHDX file (Must end in .vhdx)
        [Parameter(Position = 0, Mandatory = $true,
            HelpMessage = 'Enter the path for the new VHDX file')]
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

        # Format drive as NTFS or ReFS (Only applies when DiskLayout = Data)
        [string]
        [ValidateNotNullOrEmpty()]
        [ValidateSet('NTFS', 'ReFS')]
        $DataFormat = 'ReFS',

        # Allocation Unit Size to format the primary partition
        [int]
        [ValidateSet(4kb, 8kb, 16kb, 32kb, 64kb, 128kb, 256kb, 512kb, 1024kb, 2048kb)]
        $AllocationUnitSize,

        # Size in Bytes (Default 40B)
        [ValidateRange(100mb, 64TB)]
        [long]$Size = 40GB,

        # MS Reserved Partition Size (Default : 128MB)
        [int]$ReservedSize,

        # Create Dynamic disk
        [switch]$Dynamic,

        # Force the overwrite of existing files
        [switch]$force

    )
    $Path = $Path | Get-FullFilePath
    $VhdxFileName = Split-Path -Leaf -Path $Path

    if ($PsCmdlet.ShouldProcess("[$($MyInvocation.MyCommand)] : Overwrite partitions inside [$Path] with GPT Data Partitions",
            "Overwrite partitions inside [$Path] with GPT Data Partitions ? ",
            'Overwrite WARNING!')) {
        if ((-not (Test-Path $Path)) -Or $force -Or $PsCmdlet.ShouldContinue('Are you sure? Any existing data will be lost!', 'Warning')) {
            $ParametersToPass = @{ }
            foreach ($key in ('WhatIf', 'Verbose', 'Debug')) {
                if ($PSBoundParameters.ContainsKey($key)) {
                    $ParametersToPass[$key] = $PSBoundParameters[$key]
                }
            }

            $InitializeVHDPartitionParam = @{
                'Size'       = $Size
                'Path'       = $Path
                'force'      = $true
                'DiskLayout' = 'Data'
                'DataFormat' = $DataFormat
            }
            if ($Dynamic) {
                $InitializeVHDPartitionParam.add('Dynamic', $true)
            }
            if ($ReservedSize) {
                $InitializeVHDPartitionParam.add('ReservedSize', $ReservedSize)
            }
            if ($AllocationUnitSize) { $InitializeVHDPartitionParam.add('AllocationUnitSize', $AllocationUnitSize) }

            Write-Verbose -Message "[$($MyInvocation.MyCommand)] : InitializeVHDPartitionParam"
            Write-Verbose -Message ($InitializeVHDPartitionParam | Out-String)
            Write-Verbose -Message "[$($MyInvocation.MyCommand)] : ParametersToPass"
            Write-Verbose -Message ($ParametersToPass | Out-String)
            Try {
                Initialize-VHDPartition @InitializeVHDPartitionParam @ParametersToPass
            } Catch {
                throw "$($_.Exception.Message) at $($_.Exception.InvocationInfo.ScriptLineNumber)"
            }
            #region mount the VHDX file
            try {
                Write-Verbose -Message "[$($MyInvocation.MyCommand)] [$VhdxFileName] : Mounting disk image [$Path]"
                $disk = Mount-DiskImage -ImagePath $Path -PassThru |
                Get-DiskImage |
                Get-Disk
                $DiskNumber = $disk.Number
            } catch {
                throw $_.Exception.Message
            }
            #endregion

            try {
                #! Workaround for new drive letters in script modules
                $null = Get-PSDrive

                #region Assign Drive Letters (disable explorer popup and reset afterwords)
                $DisableAutoPlayOldValue = (Get-ItemProperty -path HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers -name DisableAutoplay).DisableAutoplay
                Set-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers -Name DisableAutoplay -Value 1
                foreach ($partition in (Get-Partition -DiskNumber $DiskNumber |
                        where-object -FilterScript { $_.Type -eq 'IFS' -or $_.type -eq 'basic' })) {
                    $partition | Add-PartitionAccessPath -AssignDriveLetter -ErrorAction Stop
                }
                #! Workaround for new drive letters in script modules
                $null = Get-PSDrive
                Set-ItemProperty -Path hkcu:\Software\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers -Name DisableAutoplay -Value $DisableAutoPlayOldValue
            } catch {
                Write-Error -Message "[$($MyInvocation.MyCommand)] [$VhdxFileName] : Error Adding Drive Letter "
                throw $_.Exception.Message
            } finally {
                #dismount
                Write-Verbose -Message "[$($MyInvocation.MyCommand)] [$VhdxFileName] : Dismounting"
                $null = Dismount-DiskImage -ImagePath $Path
                if ($isoPath -and (Get-DiskImage $isoPath).Attached) {
                    $null = Dismount-DiskImage -ImagePath $isoPath
                    [System.GC]::Collect()
                }
                Write-Verbose -Message "[$($MyInvocation.MyCommand)] [$VhdxFileName] : Finished"
            }
        }
    }
}
