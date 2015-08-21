function Set-GenTwoBootDiskFromWim
{
    <#
            .Synopsis
            Configure Windows image and recovery partitions
            .DESCRIPTION
            This command will update partitions for a Generate 2 VHDX file, configured for UEFI. 
            You must supply the path to the VHDX file and a valid WIM. You should also
            include the index number for the Windows Edition to install. The WIM will be
            copied to the recovery partition.
            Optionally, you can also specify an XML file to be inserted into the OS
            partition as unattend.xml
            CAUTION: This command will reformat partitions.
            .EXAMPLE
            PS C:\> Set-Gen2BootDiskFromWim -Path D:\vhd\demo3.vhdx -WIMPath D:\wim\Win2012R2-Install.wim -verbose
            .EXAMPLE
            PS C:\> Set-Gen2BootDiskFromWim -Path D:\vhd\demo3.vhdx -WIMPath D:\wim\Win2012R2-Install.wim -verbose
    #>
    [CmdletBinding(SupportsShouldProcess = $true, 
            PositionalBinding = $true,
    ConfirmImpact = 'High')]
    Param
    (
        # Path to VHDX 
        [parameter(Position = 0,Mandatory = $true,
                HelpMessage = 'Enter the path to the VHDX file',
                ValueFromPipeline = $true,
        ValueFromPipelineByPropertyName = $true)]
        [Alias('FullName','pspath')]
        [ValidateScript({
                    Test-Path $_
        })]
        [string]$Path,
        
        # Path to WIM used to populate VHDX
        [parameter(Position = 1,Mandatory = $true,
        HelpMessage = 'Enter the path to the WIM file')]
        [ValidateScript({
                    Test-Path $_
        })]
        [string]$WIMPath,
        
        # Index of image inside of WIM (Default 1)
        [ValidateScript({
                    ,
                    $last = (Get-WindowsImage -ImagePath $PSBoundParameters.WIMPath |
                        Sort-Object ImageIndex |
                    Select-Object -Last 1).ImageIndex
                    If ($_ -gt $last -OR $_ -lt 1) 
                    {
                        Throw "enter a valid index between 1 and $last"
                    }
                    else 
                    {
                        #index is valid
                        $true
                    }
        })]
        [int]$Index = 1,
        
        # Path to file to copy inside of VHDX as C:\unattent.xml
        [ValidateScript({
                    Test-Path $_
        })]
        [string]$Unattend,

        # Bypass the warning and about lost data
        [switch]$Force
    )
    begin
    {
        # make paths absolute
        $Path = Resolve-Path $Path
        $WIMPath = Resolve-Path $WIMPath
    }
    Process {

        $VhdxFileName = Split-Path -Leaf -Path $Path
        $WIMFileName = Split-Path -Leaf -Path $WIMPath
        if ($pscmdlet.ShouldProcess("Overwrite partitions inside [$Path] with contentce of [$WIMPath]",
                "Overwrite partitions inside [$Path] with contentce of [$WIMPath]?, Any existin data will be lost!",
        'Overwrite WARNING!'))
        {
            if($Force -Or $pscmdlet.ShouldContinue('', '')) 
            {
                #mount the VHDX file
                Write-Verbose "[$($MyInvocation.MyCommand)] [$VhdxFileName] : Mounting "
                Mount-DiskImage -ImagePath $Path
                #get the disk number
                $disknumber = (Get-DiskImage -ImagePath $Path | Get-Disk).Number
                #pre-processing
                $partitions = Get-Partition -DiskNumber $disknumber
                Write-Verbose ($partitions | Out-String)
        
                try 
                {
                    Write-Verbose "[$($MyInvocation.MyCommand)] [$VhdxFileName] : Processing disknumber [$disknumber]"
           
                    # region Recovery Image
                    $Recovery = $partitions | Where-Object Type -EQ -Value Recovery
                    if ($Recovery)
                    { 
                        if ($Recovery.count -ne 2) 
                        {
                            Throw "Recovery partition count = 2 was expecting [$($Recovery.count)]"
                        }
                        #prepare Recovery Image partition
            
                        $partitionNumber = $Recovery[1].PartitionNumber
                        Write-Verbose "[$($MyInvocation.MyCommand)] [$VhdxFileName] Partition [$partitionNumber] : Formatting Recovery Image Partition"
                        $null = Get-Partition -DiskNumber $disknumber -PartitionNumber $partitionNumber   |
                        Format-Volume -FileSystem NTFS -NewFileSystemLabel 'RecoveryImage' -Confirm:$false -ErrorAction Stop
            
                        #mount the Recovery image partition with a drive letter
                        if (-Not (Get-Partition -DiskNumber $disknumber -PartitionNumber $partitionNumber).DriveLetter) 
                        {
                            Write-Verbose "[$($MyInvocation.MyCommand)] [$VhdxFileName] Partition [$partitionNumber] : Assigning drive letter to Recovery Image partition"
                            Get-Partition -DiskNumber $disknumber -PartitionNumber $partitionNumber -ErrorAction Stop |
                            Add-PartitionAccessPath -AssignDriveLetter -ErrorAction Stop
                        }
                        $null = Get-PSDrive
                        $RecoveryPartition = Get-Partition -DiskNumber $disknumber -PartitionNumber $partitionNumber -ErrorAction Stop
                        #copy the WIM to recovery image partition as Install.wim
                        $recoverfolder = Join-Path "$($RecoveryPartition.DriveLetter):" -ChildPath 'Recovery'
                        $null = mkdir $recoverfolder
                        $recoveryPath = Join-Path $recoverfolder -ChildPath 'install.wim'
                        Write-Verbose "[$($MyInvocation.MyCommand)] [$VhdxFileName] Partition [$partitionNumber] : copying $WIMPath to $recoveryPath"
                        Copy-Item -Path $WIMPath -Destination $recoveryPath -ErrorAction Stop
                    } # end if Recovery
                    #endregion

                    #region OS partition 
                    $OS = $partitions | Where-Object Type -EQ -Value Basic
                    if (-not $OS)
                    {
                        throw 'Unable to find OS partition'
                    }
                    $partitionNumber = $OS[0].PartitionNumber
                    Write-Verbose "[$($MyInvocation.MyCommand)] [$VhdxFileName] Partition [$partitionNumber] : Formatting Windows partition"
                    #$null = 
                    Get-Partition -DiskNumber $disknumber -PartitionNumber $partitionNumber |
                    Format-Volume -FileSystem NTFS -NewFileSystemLabel 'Windows' -Confirm:$false
                    if (-Not (Get-Partition -DiskNumber $disknumber -PartitionNumber $partitionNumber).DriveLetter) 
                    {
                        Write-Verbose "[$($MyInvocation.MyCommand)] [$VhdxFileName] Partition [$partitionNumber] : Assigning drive letter to Windows partition"
                        Get-Partition -DiskNumber $disknumber -PartitionNumber $partitionNumber |
                        Add-PartitionAccessPath -AssignDriveLetter
                    }
                    $null = Get-PSDrive
                    $windowsPartition = Get-Partition -DiskNumber $disknumber -PartitionNumber $partitionNumber
                    $WinPath = Join-Path "$($windowsPartition.DriveLetter):" -ChildPath '\'
                    $windir = Join-Path $WinPath -ChildPath Windows
                    Write-Verbose "[$($MyInvocation.MyCommand)] [$VhdxFileName] Partition [$partitionNumber] : Applying image from [$WIMPath] to [$WinPath] using Index [$Index]"
                    Expand-WindowsImage -ImagePath $WIMPath -Index $Index -ApplyPath $WinPath
                    #copy XML file if specified
                    if ($Unattend) 
                    {
                        $unattendpath = Join-Path $WinPath -ChildPath 'Unattend.xml'
                        Write-Verbose "[$($MyInvocation.MyCommand)] [$VhdxFileName] Partition [$partitionNumber] : Copying [$Unattend] to [$unattendpath]"
                        Copy-Item $Unattend -Destination $unattendpath
                    }
                    #endregion
                
                    #region System partition
                    $System = $partitions | Where-Object Type -EQ -Value System
                    if (-not $System)
                    {
                        throw 'Unable to find System partition'
                    }
                    $partitionNumber = $System[0].PartitionNumber
                
                    Write-Verbose "[$($MyInvocation.MyCommand)] [$VhdxFileName] Partition [$partitionNumber] : Assigning drive letter to System partition"
                    Get-Partition -DiskNumber $disknumber -PartitionNumber $partitionNumber |
                    Add-PartitionAccessPath -AssignDriveLetter
                    $null = Get-PSDrive
                    $systemPartition = Get-Partition -DiskNumber $disknumber -PartitionNumber $partitionNumber
                    $sysDrive = "$($systemPartition.driveletter):"
                    Write-Verbose "[$($MyInvocation.MyCommand)] [$VhdxFileName] Partition [$partitionNumber] : Running bcdboot-> [$windir] /s [$sysDrive] /f UEFI"
                    $cmd = "$windir\System32\bcdboot.exe $windir /s $sysDrive /F UEFI"
                    Invoke-Expression $cmd
                    #post processing
                    Write-Verbose "[$($MyInvocation.MyCommand)] [$VhdxFileName] :"
                    Write-Verbose (Get-Partition -DiskNumber $disknumber | Out-String)
                    #endregion

                    if ($Recovery)
                    { 
                        $cmd = "$windir\System32\reagentc.exe /setosimage /path $recoverfolder /index $Index /target $windir"
                        Write-Verbose "[$($MyInvocation.MyCommand)] [$VhdxFileName] Partition [$partitionNumber] : $cmd"
                        Invoke-Expression $cmd
                        #mount the recovery tools partition with a drive letter
                        $partitionNumber = $Recovery[0].PartitionNumber
                        Write-Verbose "[$($MyInvocation.MyCommand)] [$VhdxFileName] Partition [$partitionNumber] : Formatting Windows RE Tools partition"
                        $null = Get-Partition -DiskNumber $disknumber -PartitionNumber $partitionNumber |
                        Format-Volume -FileSystem NTFS -NewFileSystemLabel 'Windows RE Tools' -Confirm:$false
                        if (-Not (Get-Partition -DiskNumber $disknumber -PartitionNumber $partitionNumber).DriveLetter) 
                        {
                            Write-Verbose "[$($MyInvocation.MyCommand)] [$VhdxFileName] Partition [$partitionNumber] : Assigning drive letter to Windows RE Tools partition"
                            Get-Partition -DiskNumber $disknumber -PartitionNumber $partitionNumber |
                            Add-PartitionAccessPath -AssignDriveLetter
                        }
                        $null = Get-PSDrive
                        $retools = Get-Partition -DiskNumber $disknumber -PartitionNumber $partitionNumber
                        #create \Recovery\WindowsRE
                        Write-Verbose "[$($MyInvocation.MyCommand)] [$VhdxFileName] Partition [$partitionNumber] : Creating Recovery\WindowsRE folder"
                        $repath = mkdir "$($retools.driveletter):\Recovery\WindowsRE"
                        Write-Verbose "[$($MyInvocation.MyCommand)] [$VhdxFileName] Partition [$partitionNumber] : Copying $($windowsPartition.DriveLetter):\Windows\System32\recovery\winre.wim to $($repath.fullname)"
                        #the winre.wim file is hidden
                        Get-ChildItem "$($windowsPartition.DriveLetter):\Windows\System32\recovery\winre.wim" -Hidden |
                        Copy-Item -Destination $repath.FullName
                    } # end if Recovery
                }
                catch 
                {
                    Write-Error "[$($MyInvocation.MyCommand)] [$VhdxFileName] : Error setting partition content "
                    throw $_.Exception.Message
                }
                finally 
                {
                    Write-Verbose "[$($MyInvocation.MyCommand)] [$VhdxFileName] : Removing Drive letters"
                    Get-Partition -DiskNumber $disknumber |
                    Where-Object {
                        $_.driveletter
                    }  |
                    ForEach-Object {
                        $dl = "$($_.DriveLetter):"
                        $_ |
                        Remove-PartitionAccessPath -AccessPath $dl
                    }
                    #dismount
                    Write-Verbose "[$($MyInvocation.MyCommand)] [$VhdxFileName] : Dismounting"
                    Dismount-DiskImage -ImagePath $Path
                    Write-Verbose "[$($MyInvocation.MyCommand)] [$VhdxFileName] : Finished"
                }
            }
            else 
            {
                Write-Warning 'Process aborted by user'
            }
        }
        else 
        {
            Write-Warning 'Process aborted by user'
        }
       
    }
}
