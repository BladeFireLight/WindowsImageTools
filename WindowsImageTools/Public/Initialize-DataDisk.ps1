function Initialize-DataDisk {
    <#
    .SYNOPSIS
    Partitions a disk as GPT and formats it as a Data Drive.

    .DESCRIPTION
    This command partitions the specified disk as GPT and formats it as a Data Drive using either NTFS or ReFS. You can specify allocation unit size, reserved partition size, and force overwrite of existing partitions. The function also assigns drive letters to the new partitions.

    .PARAMETER DiskNumber
    The disk number to partition and format. Must exist and be visible to Get-Disk.

    .PARAMETER DataFormat
    The file system format for the data drive. Valid values are NTFS or ReFS. Default is ReFS.

    .PARAMETER AllocationUnitSize
    The allocation unit size to use when formatting the primary partition. Valid values are 4kb, 8kb, 16kb, 32kb, 64kb, 128kb, 256kb, 512kb, 1024kb, 2048kb.

    .PARAMETER ReservedSize
    The size of the MS Reserved partition in MB. Default is 128MB.

    .PARAMETER Force
    If specified, overwrites any existing partitions or data on the disk.

    .EXAMPLE
    Initialize-DataDisk -DiskNumber 1 -DataFormat ReFS

    Partitions and formats disk number 1 as a Data Drive with ReFS.

    .EXAMPLE
    Initialize-DataDisk -DiskNumber 1 -DataFormat NTFS -AllocationUnitSize 64kb -Force

    Partitions and formats disk number 1 as a Data Drive with NTFS, using a 64kb allocation unit size and overwriting any existing data.

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

        # Format drive as NTFS or ReFS (Only applies when DiskLayout = Data)
        [string]
        [ValidateNotNullOrEmpty()]
        [ValidateSet('NTFS', 'ReFS')]
        $DataFormat = 'ReFS',

        # Allocation Unit Size to format the primary partition
        [int]
        [ValidateSet(4kb, 8kb, 16kb, 32kb, 64kb, 128kb, 256kb, 512kb, 1024kb, 2048kb)]
        $AllocationUnitSize,

        # MS Reserved Partition Size (Default : 128MB)
        [int]$ReservedSize,

        # Force the overwrite of existing files
        [switch]$force
    )
    if ($psCmdlet.ShouldProcess("[$($MyInvocation.MyCommand)] : Overwrite partitions on disk [$DiskNumber]",
            "Overwrite partitions on disk [$DiskNumber]? ",
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
                'DiskLayout' = 'Data'
                'DataFormat' = $DataFormat
            }
            if ($ReservedSize) {
                $InitializeDiskPartitionParam.add('ReservedSize', $ReservedSize)
            }
            if ($AllocationUnitSize) { $InitializeDiskPartitionParam.add('AllocationUnitSize', $AllocationUnitSize) }

            Write-Verbose -Message "[$($MyInvocation.MyCommand)] : InitializeDiskPartitionParam"
            Write-Verbose -Message ($InitializeVHDPartitionParam | Out-String)
            Write-Verbose -Message "[$($MyInvocation.MyCommand)] : ParametersToPass"
            Write-Verbose -Message ($ParametersToPass | Out-String)

            Try {
                Initialize-DiskPartition @InitializeDiskPartitionParam @ParametersToPass
            } Catch {
                throw "$($_.Exception.Message) at $($_.Exception.InvocationInfo.ScriptLineNumber)"
            }
            try {
                #! Workaround for new drive letters in script modules
                $null = Get-PSDrive

                #region Assign Drive Letters (disable explorer popup and reset afterwords)
                $DisableAutoPlayOldValue = (Get-ItemProperty -path hkcu:\Software\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers -name DisableAutoplay).DisableAutoplay
                Set-ItemProperty -Path hkcu:\Software\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers -Name DisableAutoplay -Value 1
                foreach ($partition in (Get-Partition -DiskNumber $DiskNumber |
                        where-object -FilterScript { $_.Type -eq 'IFS' -or $_.type -eq 'basic' })) {
                    $partition | Add-PartitionAccessPath -AssignDriveLetter -ErrorAction Stop
                }
                #! Workaround for new drive letters in script modules
                $null = Get-PSDrive
                Set-ItemProperty -Path hkcu:\Software\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers -Name DisableAutoplay -Value $DisableAutoPlayOldValue
            } catch {
                Write-Error -Message "[$($MyInvocation.MyCommand)] [$DiskNumber] : Error Adding Drive Letter "
                throw $_.Exception.Message
            }
        }
    }
}


