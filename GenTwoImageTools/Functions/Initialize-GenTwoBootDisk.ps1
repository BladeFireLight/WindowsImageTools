#requires -Version 2 -Modules Hyper-V, Storage

function Initialize-GenTwoBootDisk
{
    <#
            .Synopsis
            Create a Generation 2 VHDX
            .DESCRIPTION
            This command will create a generation 2 VHDX file. Many of the parameters are
            from the New-VHD cmdlet. The disk name must end in .vhdx

            To create a recovery partition use -Recovery

            .EXAMPLE
            Initialize-Gen2BootDisk d:\disks\disk001.vhdx -dynamic -size 30GB
            .EXAMPLE
            Initialize-Gen2BootDisk d:\disks\disk001.vhdx -dynamic -size 40GB -Recovery
            .NOTES
            General notes
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
        [ValidatePattern("\.vhdx$")]
        [ValidateScript({
                    if (Split-Path -Path $_ | Test-Path) 
                    {
                        $true
                    }
                    else 
                    {
                        Throw "Parent folder for $_ does not exist."
                    }
        })]
        [string]$Path,
        [ValidateRange(25GB,64TB)]
        
        # Size in Bytes (Default 40B)
        [uint64]$Size = 40GB,
        
        # Create Dynamic disk
        [switch]$Dynamic,
        
        # Block Size (Default 2MB)
        [UInt32]$BlockSizeBytes = 2MB,
        
        #Logical Sector size of 512 or 4098 bytes (Default 512)
        [ValidateSet(512,4096)]
        [Uint32]$LogicalSectorSizeBytes = 512,
        
        #Phisical Sector size of 512 or 4096 bytes (Default 512)
        [ValidateSet(512,4096)]
        [Uint32]$PhysicalSectorSizeBytes = 512,
        
        # Create the Recovery Partition (Pet vs Cattle)
        [switch]
        $Recovery
    )

    if ($Recovery)
    {
        $RESize = 300MB
        $RecoverySize = 15GB
    }
    else 
    {
        $RESize = 1MB
        $RecoverySize = 1MB
    }
    $SysSize = 100MB
    $MSRSize = 128MB
    $fileName = Split-Path -Leaf -Path $Path
    # make paths absolute
    #$Path = Resolve-Path $Path -Verbose

    if ($pscmdlet.ShouldProcess("$Path", 'Create new Generation Two disk'))
    {
        if (Test-Path -Path $Path) 
        {
            Throw "Disk image at $Path already exists."
        }
        Write-Verbose -Message "[$($MyInvocation.MyCommand)] [$fileName] : Creating"
            
        $vhdParams = @{
            ErrorAction             = 'Stop'
            Path                    = $Path
            SizeBytes               = $Size
            Dynamic                 = $Dynamic
            BlockSizeBytes          = $BlockSizeBytes
            LogicalSectorSizeBytes  = $LogicalSectorSizeBytes
            PhysicalSectorSizeBytes = $PhysicalSectorSizeBytes
        }
        Try 
        {
            Write-Verbose -Message "[$($MyInvocation.MyCommand)] [$fileName] : @vhdParms"
            Write-Verbose -Message ($vhdParams | Out-String)
            $disk = New-VHD @vhdParams 
        } 
        catch
        {
            Throw "Failed to create $Path. $($_.Exception.Message)"
        }
        if ($disk) 
        {
            #region Mount Image
            try 
            {
                Write-Verbose -Message "[$($MyInvocation.MyCommand)] [$fileName] : Mounting disk image"
                Mount-DiskImage -ImagePath $Path -ErrorAction Stop
            }
            catch 
            {
                throw $_.Exception.Message
            }
            #endregion

            #region create partitions
            try
            {
                $disknumber = (Get-DiskImage -ImagePath $Path | Get-Disk).Number

                $WinPartSize = (Get-Disk -Number $disknumber).Size - ($RESize+$SysSize+$MSRSize+$RecoverySize)
                    
                Write-Verbose -Message "[$($MyInvocation.MyCommand)] [$fileName] : Initializing disk $disknumber as GPT"
                Initialize-Disk -Number $disknumber -PartitionStyle GPT -ErrorAction Stop
                    
                Write-Verbose -Message "[$($MyInvocation.MyCommand)] [$fileName] : Clearing disk partitions to start all over"
                Get-Disk -Number $disknumber -ErrorAction Stop |
                Get-Partition -ErrorAction Stop |
                Remove-Partition -Confirm:$false -ErrorAction Stop
                if ($Recovery)
                {
                    #create the RE Tools partition
                    Write-Verbose -Message "[$($MyInvocation.MyCommand)] [$fileName] : Creating a [$RESize] byte Recovery tools partition on disknumber [$disknumber]"
                    $null = New-Partition -DiskNumber $disknumber -GptType '{de94bba4-06d1-4d40-a16a-bfd50179d6ac}' -Size $RESize -ErrorAction Stop |
                    Format-Volume -FileSystem NTFS -NewFileSystemLabel 'Windows RE Tools' -Confirm:$false -ErrorAction Stop
                    $partitionNumber = (Get-Disk $disknumber |
                        Get-Partition |
                        Where-Object -FilterScript {
                            $_.type -eq 'recovery'
                    }).PartitionNumber
                    Write-Verbose -Message "[$($MyInvocation.MyCommand)] [$fileName] : Retrieved partition number [$partitionNumber]"
                    #run diskpart to set GPT attribute to prevent partition removal
                    #the here string must be left justified
                    $null = @"
select disk $disknumber
select partition $partitionNumber
gpt attributes=0x8000000000000001
exit
"@ |
                    diskpart.exe
                } # end if Recovery

                #create the system partition
                Write-Verbose -Message "[$($MyInvocation.MyCommand)] [$fileName] : Creating a [$SysSize] byte System partition on disknumber [$disknumber]"
                <#
                        There is a known bug where Format-Volume cannot format an EFI partition
                        so formatting will be done with Diskpart
                #>
                $sysPartition = New-Partition -DiskNumber $disknumber -GptType '{c12a7328-f81f-11d2-ba4b-00a0c93ec93b}' -Size $SysSize -ErrorAction Stop
                $systemNumber = $sysPartition.PartitionNumber
                Write-Verbose -Message "[$($MyInvocation.MyCommand)] [$fileName] : Retrieved system partition number [$systemNumber]"
                $null = @"
select disk $disknumber
select partition $systemNumber
format quick fs=fat32 label=System
exit
"@ |
                diskpart.exe
                #create MSR
                Write-Verbose -Message "[$($MyInvocation.MyCommand)] [$fileName] : Creating a [$MSRSize] MSR partition"
                $null = New-Partition -DiskNumber $disknumber -GptType '{e3c9e316-0b5c-4db8-817d-f92df00215ae}' -Size $MSRSize -ErrorAction Stop
                #create OS partition
                Write-Verbose -Message "[$($MyInvocation.MyCommand)] [$fileName] : Creating a [$WinPartSize] byte OS partition on disknumber [$disknumber]"
                $null = New-Partition -DiskNumber $disknumber -Size $WinPartSize -ErrorAction Stop
                if ($Recovery)
                {
                    #create recovery
                    Write-Verbose -Message "[$($MyInvocation.MyCommand)] [$fileName] : Creating a [$RecoverySize] byte Recovery partition"
                    $RecoveryPartition = $null = New-Partition -DiskNumber $disknumber -GptType '{de94bba4-06d1-4d40-a16a-bfd50179d6ac}' -UseMaximumSize -ErrorAction Stop
                    $RecoveryPartitionNumber = $RecoveryPartition.PartitionNumber
                    $RecoveryPartition | Format-Volume -FileSystem NTFS -NewFileSystemLabel 'Windows Recovery' -Confirm:$false -ErrorAction Stop
                    #run diskpart to set GPT attribute to prevent partition removal
                    #the here string must be left justified
                    $null = @"
select disk $disknumber
select partition $RecoveryPartitionNumber
gpt attributes=0x8000000000000001
exit
"@ |
                    diskpart.exe
                } #end if Recovery
            }
            catch 
            {
                Write-Error -Message "[$($MyInvocation.MyCommand)] [$fileName] : Creating Partitions"
                throw $_.Exception.Message
            }
            #endregion create partitions
                
            #region Dismount
            finally 
            {
                Write-Verbose -Message "[$($MyInvocation.MyCommand)] [$fileName] : Dismounting disk image"
                Dismount-DiskImage -ImagePath $Path 
            }
            #endregion
        }#end if disk
    }
    #write the new disk object to the pipeline
    Get-Item -Path $Path
}
