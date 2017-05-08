function Initialize-DiskPartition {
  <#
    .Synopsis
    Initialize a disk and create partitions
    .DESCRIPTION
    This command will will create partition(s) on a give disk. Supported layours are: BIOS, UEFI, WindowsToGo, Data. 

    To create a recovery partitions use -RecoveryTools and -RecoveryImage

    .EXAMPLE
    Initialize-VDiskPartition -DiskNumber 5 -dynamic -size 30GB -DiskLayout BIOS
    .EXAMPLE
    Initialize-VHDPartition -DiskNumber 4 -dynamic -size 40GB -DiskLayout UEFI -RecoveryTools
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
        if (Get-Disk -Number $_) {
          $true
        }
        else {
          Throw "Disk number $_ does not exist."
        }
      })]
    [string]$DiskNumber,
        
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

    # Output the disk object
    [switch]$Passthru,
         
    # Create the Recovery Environment Tools Partition. Only valid on UEFI layout
    [switch]$RecoveryTools,

    # Create the Recovery Environment Tools and Recovery Image Partitions. Only valid on UEFI layout
    [switch]$RecoveryImage,

    # Force the overwrite of existing files
    [switch]$force
  )
  Begin { 

 
    if ($pscmdlet.ShouldProcess("[$($MyInvocation.MyCommand)] Create [$DiskLayout] partition structure on Disk [$DiskNumber]",
        "Replace existing Partitions on disk [$DiskNumber] ? ",
        'Overwrite WARNING!')) {
      if (-not (Get-Disk -Number $DiskNumber | Get-Partition -ErrorAction SilentlyContinue) -Or 
        $force -Or 
        ((Get-Disk -Number $DiskNumber | Get-Partition -ErrorAction SilentlyContinue) -and $pscmdlet.ShouldContinue("Target Disk [$DiskNumber] has existing partitions! Any existing data will be lost! (suppress with -force)", 'Warning'))) {
        #region Validate input

        # Recovery Image requires the Recovery Tools
        if ($RecoveryImage) {
          $RecoveryTools = $true
        }
          
        $SysSize = 200MB
        $MSRSize = 128MB
        $RESize = 0 
        $RecoverySize = 0
        if ($RecoveryTools) {
          $RESize = 350MB
        }
        if ($RecoveryImage) {
          $RecoverySize = 15GB
        }
                

        #region create partitions
        try {
          switch ($DiskLayout) {             
            'BIOS' {
              Write-Verbose -Message "[$($MyInvocation.MyCommand)] [$disknumber] : Clearing disk"
              Clear-disk -Number $disknumber -RemoveData -Confirm:$false -ErrorAction SilentlyContinue

              Write-Verbose -Message "[$($MyInvocation.MyCommand)] [$disknumber] : Initializing disk as MBR"
              Initialize-Disk -Number $disknumber -PartitionStyle MBR -ErrorAction Stop

              $initiaPartition = Get-Disk -Number $disknumber -ErrorAction Stop |
                Get-Partition -ErrorAction SilentlyContinue
              if ($initiaPartition) {
                Write-Verbose -Message "[$($MyInvocation.MyCommand)] [$disknumber] : Clearing disk to start all over"
                Remove-Partition -Confirm:$false -ErrorAction SilentlyContinue
              }

              # Create the Windows/system partition 
              # Refresh $disk to update free space
              $disk = Get-Disk -Number $disknumber | Get-Disk
              Write-Verbose -Message "[$($MyInvocation.MyCommand)] [$disknumber] : Creating single partition of [$($disk.LargestFreeExtent)] bytes"
              $windowsPartition = New-Partition -DiskNumber $disknumber -UseMaximumSize -MbrType IFS -IsActive #-Size $disk.LargestFreeExtent
              $systemPartition = $windowsPartition
    
              Write-Verbose -Message "[$($MyInvocation.MyCommand)] [$disknumber] : Formatting windows volume"
              $null = Format-Volume -Partition $windowsPartition -FileSystem NTFS -Force -Confirm:$false
            } 
                
            'UEFI' {
              Write-Verbose -Message "[$($MyInvocation.MyCommand)] [$disknumber] : Clearing disk"
              Clear-disk -Number $disknumber -RemoveData -RemoveOEM -Confirm:$false  -ErrorAction SilentlyContinue

              Write-Verbose -Message "[$($MyInvocation.MyCommand)] [$disknumber] : Initializing disk [$disknumber] as GPT"
              Initialize-Disk -Number $disknumber -PartitionStyle GPT -ErrorAction SilentlyContinue

              $initiaPartition = Get-Disk -Number $disknumber -ErrorAction Stop |
                Get-Partition -ErrorAction SilentlyContinue
              if ($initiaPartition) {
                Write-Verbose -Message "[$($MyInvocation.MyCommand)] [$disknumber] : Clearing disk to start all over"
                Remove-Partition -Confirm:$false -ErrorAction SilentlyContinue
              }

              if ($RecoveryTools) {
                Write-Verbose "[$($MyInvocation.MyCommand)] [$disknumber] : Recovery tools : Creating partition of [$RESize] bytes"
                $recoveryToolsPartition = New-Partition -DiskNumber $disknumber -Size $RESize -GptType '{de94bba4-06d1-4d40-a16a-bfd50179d6ac}'
                Write-Verbose "[$($MyInvocation.MyCommand)] [$disknumber] : Recovery tools : Formatting NTFS"
                $null = Format-Volume -Partition $recoveryToolsPartition -FileSystem NTFS -NewFileSystemLabel 'Windows RE Tools' -Force -Confirm:$false
                #run diskpart to set GPT attribute to prevent partition removal
                #the here string must be left justified
                $null = @"
select disk $($disknumber)
select partition $($recoveryToolsPartition.partitionNumber)
gpt attributes=0x8000000000000001
exit
"@ |
                  diskpart.exe
              }
                    
                    
              # Create the system partition.  Create a data partition so we can format it, then change to ESP
              Write-Verbose "[$($MyInvocation.MyCommand)] [$disknumber] : EFI system : Creating partition of [$SysSize] bytes"
              $systemPartition = New-Partition -DiskNumber $diskNumber -Size $SysSize -GptType '{ebd0a0a2-b9e5-4433-87c0-68b6b72699c7}'
                
              Write-Verbose "[$($MyInvocation.MyCommand)] [$disknumber] : EFI system : Formatting FAT32"
              $null = Format-Volume -Partition $systemPartition -FileSystem FAT32 -Force -Confirm:$false

              Write-Verbose "[$($MyInvocation.MyCommand)] [$disknumber] : EFI system : Setting system partition as ESP"
              $systemPartition | Set-Partition -GptType '{c12a7328-f81f-11d2-ba4b-00a0c93ec93b}'
                
              # Create the reserved partition 
              Write-Verbose "[$($MyInvocation.MyCommand)] [$disknumber] : MSR : Creating partition of [$MSRSize] bytes"
              $null = New-Partition -DiskNumber $disknumber -Size $MSRSize -GptType '{e3c9e316-0b5c-4db8-817d-f92df00215ae}'
                    
              # Create the Windows partition
              # Refresh $disk to update free space
              $disk = Get-Disk -Number $disknumber | Get-Disk
              Write-Verbose "[$($MyInvocation.MyCommand)] [$disknumber] : Windows : Creating partition of [$($disk.LargestFreeExtent - $RecoverySize)] bytes"
              $windowsPartition = New-Partition -DiskNumber $diskNumber -Size ($disk.LargestFreeExtent - $RecoverySize) -GptType '{ebd0a0a2-b9e5-4433-87c0-68b6b72699c7}'
              Write-Verbose "[$($MyInvocation.MyCommand)] [$disknumber] : Windows : Formatting volume NTFS"
              $null = Format-Volume -Partition $windowsPartition -NewFileSystemLabel 'OS' -FileSystem NTFS -Force -Confirm:$false
                    
              if ($RecoveryImage) {
                Write-Verbose "[$($MyInvocation.MyCommand)] [$disknumber] : Recovery Image : Creating partition using remaing free space"
                $recoveryImagePartition = New-Partition -DiskNumber $diskNumber -UseMaximumSize -GptType '{de94bba4-06d1-4d40-a16a-bfd50179d6ac}'
                Write-Verbose "[$($MyInvocation.MyCommand)] [$disknumber] : Recovery Image : Formatting volume NTFS"
                $null = Format-Volume -Partition $recoveryImagePartition -NewFileSystemLabel 'Windows Recovery' -FileSystem NTFS -Force -Confirm:$false
                #run diskpart to set GPT attribute to prevent partition removal
                #the here string must be left justified
                $null = @"
select disk $($diskNumber)
select partition $($recoveryImagePartition.partitionNumber)
gpt attributes=0x8000000000000001
exit
"@ |
                  diskpart.exe
              }
            }

            'WindowsToGo' {                
              Write-Verbose -Message "[$($MyInvocation.MyCommand)] [$disknumber] : Clearing disk"
              Clear-disk -Number $disknumber -RemoveData -Confirm:$false -ErrorAction SilentlyContinue

              Write-Verbose -Message "[$($MyInvocation.MyCommand)] [$disknumber] : Initializing disk as MBR"
              Initialize-Disk -Number $disknumber -PartitionStyle MBR -ErrorAction Stop 
                    
              $initiaPartition = Get-Disk -Number $disknumber -ErrorAction Stop |
                Get-Partition -ErrorAction SilentlyContinue
              if ($initiaPartition) {
                Write-Verbose -Message "[$($MyInvocation.MyCommand)] [$disknumber] : Clearing disk to start all over"
                Remove-Partition -Confirm:$false -ErrorAction SilentlyContinue
              }
                
              # Create the system partition 
              Write-Verbose "[$($MyInvocation.MyCommand)] [$disknumber] : System : Creating partition of [$SysSize] bytes"
              $systemPartition = New-Partition -DiskNumber $disknumber -Size $SysSize -MbrType FAT32 -IsActive 
        
              Write-Verbose "[$($MyInvocation.MyCommand)] [$disknumber] : EFI system : Formatting FAT32"
              $null = Format-Volume -Partition $systemPartition -FileSystem FAT32 -Force -Confirm:$false
            
              # Create the Windows partition
              Write-Verbose "[$($MyInvocation.MyCommand)] [$disknumber] : Windows : Creating partition useing remaning space"
              $windowsPartition = New-Partition -DiskNumber $disknumber -Size $disk.LargestFreeExtent -MbrType IFS
        
              Write-Verbose "[$($MyInvocation.MyCommand)] [$disknumber] : Windows : Formatting volume NTFS"
              $null = Format-Volume -Partition $windowsPartition -FileSystem NTFS -Force -Confirm:$false
            }
            'Data' {
              Write-Verbose -Message "[$($MyInvocation.MyCommand)] [$disknumber] : Clearing disk"
              Clear-disk -Number $disknumber -RemoveData -Confirm:$false  -ErrorAction SilentlyContinue

              Write-Verbose -Message "[$($MyInvocation.MyCommand)] [$disknumber] : Initializing disk as GPT"
              Initialize-Disk -Number $disknumber -PartitionStyle GPT -ErrorAction Stop 

              $initiaPartition = Get-Disk -Number $disknumber -ErrorAction Stop |
                Get-Partition -ErrorAction SilentlyContinue
              if ($initiaPartition) {
                Write-Verbose -Message "[$($MyInvocation.MyCommand)] [$disknumber] : Clearing disk to start all over"
                Remove-Partition -Confirm:$false -ErrorAction SilentlyContinue
              }

              # Refresh $disk to update free space
              $disk = Get-Disk -Number $disknumber | Get-Disk
              Write-Verbose -Message "[$($MyInvocation.MyCommand)] [$disknumber] : Creating single partition of [$($disk.LargestFreeExtent)] bytes"
              $windowsPartition = New-Partition -DiskNumber $disknumber -UseMaximumSize -GptType '{ebd0a0a2-b9e5-4433-87c0-68b6b72699c7}'
              $systemPartition = $windowsPartition
    
              Write-Verbose -Message "[$($MyInvocation.MyCommand)] [$disknumber] : Formatting Data volume as [$dataFormat]"
              $null = Format-Volume -Partition $windowsPartition -FileSystem $dataFormat -Force -Confirm:$false -NewFileSystemLabel 'Data' 
              $windowsPartition | Add-PartitionAccessPath -AssignDriveLetter -ErrorAction Stop
            } 
          }
        }
        catch {
          Write-Error -Message "[$($MyInvocation.MyCommand)] [$disknumber] : Creating Partitions"
          throw $_.Exception.Message
        }
        #endregion create partitions
                   
        if ($Passthru) {
          #write the new disk object to the pipeline
          Get-Disk -Number $DiskNumber
        }
      }
      else {
        Throw "[$($MyInvocation.MyCommand)] Aborted by user"
      }
    }
  }
}
