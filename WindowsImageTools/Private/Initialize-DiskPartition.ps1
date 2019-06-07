function Initialize-DiskPartition
{
    <#
    .Synopsis
    Initialize a disk and create partitions
    .DESCRIPTION
    This command will will create partition(s) on a give disk. Supported layours are: BIOS, UEFI, WindowsToGo, Data.

    To create a recovery partitions use -RecoveryTools and -RecoveryImage

    .EXAMPLE
    Initialize-VDiskPartition -DiskNumber 5 -dynamic -size 30GB -DiskLayout BIOS
    .EXAMPLE
    Initialize-VHDPartition -DiskNumber 4 -dynamic -size 40GB -DiskLayout UEFI -NoRecoveryTools
    .EXAMPLE
    Initialize-VHDPartition -DiskNumber 1 -dynamic -size 40GB -DiskLayout Data -DataFormat ReFS
    .NOTES
    This function is intended as a helper for Intilize-VHDDiskPartition
    #>
    [CmdletBinding(SupportsShouldProcess,
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
        [int]$DiskNumber,

        # Specifies whether to build the image for BIOS (MBR), UEFI (GPT), Data (GPT), or WindowsToGo (MBR).
        # Generation 1 VMs require BIOS (MBR) images and have 2-3 partitions. Generation 2 VMs require
        # UEFI (GPT) images and have 3-4 partitions.
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

        # Alocation Unit Size to format the primary partition
        [int]
        [ValidateSet(4kb, 8kb, 16kb, 32kb, 64kb, 128kb, 256kb, 512kb, 1024kb, 2048kb)]
        $AllocationUnitSize,

        # Output the disk object
        [switch]$Passthru,

        # Skip Creation of the Recovery Environment Tools Partition.
        [switch]$NoRecoveryTools,

        # System (boot loader) Partition Size
        [ValidateScript({$_ -ge 100mb})]
        [int]$SystemSize = 260MB,

        # MS Reserved Partition Size
        [ValidateScript({$_ -ge 16mb})]
        [int]$ReservedSize = 128MB,

        # Recovery Tools Partition Size
        [ValidateScript({$_ -ge 200mb})]
        [int]$RecoverySize = 905MB,

        # Force the overwrite of existing files
        [switch]$force
    )
    Begin
    {


        if ($pscmdlet.ShouldProcess("[$($MyInvocation.MyCommand)] Create [$DiskLayout] partition structure on Disk [$DiskNumber]",
                "Replace existing Partitions on disk [$DiskNumber] ? ",
                'Overwrite WARNING!'))
        {
            if (-not (Get-Disk -Number $DiskNumber | Get-Partition -ErrorAction SilentlyContinue) -Or
                $force -Or
                ((Get-Disk -Number $DiskNumber | Get-Partition -ErrorAction SilentlyContinue) -and $pscmdlet.ShouldContinue("Target Disk [$DiskNumber] has existing partitions! Any existing data will be lost! (suppress with -force)", 'Warning')))
            {
                #region Validate input

                switch ($DiskLayout)
                {
                    'BIOS'
                    {
                        $PartitionStyle = 'MBR'
                        $System = $SystemSize
                        $MsReserved = 0
                        $Recovery = $RecoverySize
                    }
                    'UEFI'
                    {
                        $PartitionStyle = 'GPT'
                        $System = $SystemSize
                        $MsReserved = $ReservedSize
                        $Recovery = $RecoverySize
                    }
                    'Data'
                    {
                        $PartitionStyle = 'GPT'
                        $System = 0
                        $MsReserved = $ReservedSize
                        $Recovery = 0
                    }
                    'WindowsToGo'
                    {
                        $PartitionStyle = 'MBR'
                        $System = $SystemSize
                        $MsReserved = 0
                        $Recovery = 0
                    }
                }
                if ($NoRecoveryTools)
                {
                    $Recovery = 0
                }
                #endregion

                #region create partitions
                try
                {
                    Write-Verbose -Message "[$($MyInvocation.MyCommand)] [$disknumber] : Clearing disk"
                    Clear-disk -Number $disknumber -RemoveData -RemoveOEM -Confirm:$false -ErrorAction SilentlyContinue
                    Write-Verbose -Message "[$($MyInvocation.MyCommand)] [$disknumber] : Initializing disk [$disknumber] as [$PartitionStyle]"
                    $null = Initialize-Disk -Number $disknumber -PartitionStyle $PartitionStyle -ErrorAction SilentlyContinue

                    $InitialPartition = Get-Disk -Number $disknumber -ErrorAction Stop |
                    Get-Partition -ErrorAction SilentlyContinue
                    if ($InitialPartition)
                    {
                        Write-Verbose -Message "[$($MyInvocation.MyCommand)] [$disknumber] : Clearing disk to start all over"
                        $InitialPartition | Remove-Partition -Confirm:$false -ErrorAction SilentlyContinue
                    }

                    if ($System)
                    {
                        # Create the system partition.  Create a data partition so we can format it, then change to ESP
                        $NewPartitionParam = @{
                            DiskNumber = $diskNumber
                            Size       = $System
                        }
                        switch ($PartitionStyle)
                        {
                            GPT { $NewPartitionParam.add('GptType', '{ebd0a0a2-b9e5-4433-87c0-68b6b72699c7}') }
                            MBR { $NewPartitionParam.add('IsActive', $true) }
                        }
                        Write-Verbose "[$($MyInvocation.MyCommand)] [$disknumber] : System : Creating partition of [$SysSize] bytes"
                        $systemPartition = New-Partition @NewPartitionParam

                        $FileSystem = 'FAT32'
                        if ($DiskLayout -eq 'Bios')
                        {
                            $FileSystem = 'NTFS'
                        }
                        Write-Verbose "[$($MyInvocation.MyCommand)] [$disknumber] : System : Formatting [$FileSystem]"
                        $null = Format-Volume -Partition $systemPartition -NewFileSystemLabel 'System' -FileSystem $FileSystem -Force -Confirm:$false

                        if ($DiskLayout -eq 'UEFI')
                        {
                            Write-Verbose "[$($MyInvocation.MyCommand)] [$disknumber] : System : Setting system partition as ESP"
                            $systemPartition | Set-Partition -GptType '{c12a7328-f81f-11d2-ba4b-00a0c93ec93b}'
                        }
                    }

                    if ($MsReserved)
                    {
                        $NewPartitionParam = @{
                            DiskNumber = $disknumber
                            Size       = $MsReserved
                            GptType    = '{e3c9e316-0b5c-4db8-817d-f92df00215ae}'
                        }
                        Write-Verbose "[$($MyInvocation.MyCommand)] [$disknumber] : MSR : Creating partition of [$MsReserved] bytes"
                        $null = New-Partition @NewPartitionParam

                    }

                    #region Create the Primay partition
                    # Refresh $disk to update free space
                    $disk = Get-Disk -Number $disknumber | Get-Disk

                    $NewPartitionParam = @{
                        DiskNumber = $disknumber
                        Size       = $disk.LargestFreeExtent - $Recovery
                    }
                    if ($PartitionStyle -eq 'GPT') { $NewPartitionParam.add('GptType', '{ebd0a0a2-b9e5-4433-87c0-68b6b72699c7}') }
                    Write-Verbose "[$($MyInvocation.MyCommand)] [$disknumber] : Primary : Creating partition of [$($disk.LargestFreeExtent - $Recovery)] bytes"
                    Write-Verbose ($NewPartitionParam | out-string)
                    $windowsPartition = New-Partition @NewPartitionParam

                    $FileSystem = 'NTFS'
                    $Label = 'Windows'
                    if ($DiskLayout -eq 'Data')
                    {
                        $FileSystem = $DataFormat
                        $Label = 'Data'
                    }
                    Write-Verbose "[$($MyInvocation.MyCommand)] [$disknumber] : Primary : Formatting volume [$FileSystem]"
                    $FormatPartitionParam = @{
                        Partition = $windowsPartition
                        NewFileSystemLabel = $Label
                        FileSystem = $FileSystem
                    }
                    if ($AllocationUnitSize) { $FormatPartitionParam.add('AllocationUnitSize', $AllocationUnitSize) }
                    $null = Format-Volume @FormatPartitionParam -Force -Confirm:$false
                    #endregion Primay Partiton

                    if ($Recovery)
                    {
                        Write-Verbose "[$($MyInvocation.MyCommand)] [$disknumber] : Recovery Tools : Creating partition using remaing free space"
                        $NewPartitionParam = @{
                            DiskNumber = $disknumber
                            Size       = $Recovery
                        }
                        if ($PartitionStyle -eq 'GPT') { $NewPartitionParam.add('GptType', '{de94bba4-06d1-4d40-a16a-bfd50179d6ac}') }
                        $recoveryImagePartition = New-Partition @NewPartitionParam
                        Write-Verbose "[$($MyInvocation.MyCommand)] [$disknumber] : Recovery Tools : Formatting volume NTFS"
                        $null = Format-Volume -Partition $recoveryImagePartition -NewFileSystemLabel 'Recovery Tools' -FileSystem NTFS -Force -Confirm:$false
                        #run diskpart to set partition to hidden and prevent deletion
                        #the here string must be left justified
                        if ($PartitionStyle -eq 'GPT')
                        {
                            $null = @"
select disk $($diskNumber)
select partition $($recoveryImagePartition.partitionNumber)
gpt attributes=0x8000000000000001
exit
"@ |
                            diskpart.exe
                        }
                        else
                        {
                          $null = @"
select disk $($diskNumber)
select partition $($recoveryImagePartition.partitionNumber)
set id=27
exit
"@ |
                            diskpart.exe
                        }
                    }

                }
                catch
                {
                    Write-Error -Message "[$($MyInvocation.MyCommand)] [$disknumber] : Creating Partitions"
                    throw $_.Exception.Message
                }
                #endregion create partitions

                if ($Passthru)
                {
                    #write the new disk object to the pipeline
                    Get-Disk -Number $DiskNumber
                }
            }
            else
            {
                Throw "[$($MyInvocation.MyCommand)] Aborted by user"
            }
        }
    }
}
