function Set-VHDPartition
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
            PS C:\> Set-Gen2BootDiskFromWim -Path D:\vhd\demo3.vhdx -SourcePath D:\wim\Win2012R2-Install.wim -verbose
            .EXAMPLE
            PS C:\> Set-Gen2BootDiskFromWim -Path D:\vhd\demo3.vhdx -SourcePath D:\wim\Win2012R2-Install.wim -verbose
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
        [Alias('FullName','pspath','ImagePath')]
        [ValidateScript({
                    Test-Path -Path (get-FullFilePath -Path $_)
        })]
        [string]$Path,
        
        # Path to WIM or ISO used to populate VHDX
        [parameter(Position = 1,Mandatory = $true,
        HelpMessage = 'Enter the path to the WIM/ISO file')]
        [ValidateScript({
                    Test-Path -Path (get-FullFilePath -Path $_ )
        })]
        [string]$SourcePath,
        
        # Index of image inside of WIM (Default 1)
        [int]$Index = 1,
        
        # Path to file to copy inside of VHD(X) as C:\unattent.xml
        [ValidateScript({
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

        # Include Boot info in VHD(X)
        [ValidateNotNullOrEmpty()]
        [ValidateSet('NativeBoot', 'VirtualMachine')]
        [string]$BCDinVHD = 'VirtualMachine',

        # Featurs to turn on (in DISM format)
        [ValidateNotNullOrEmpty()]
        [string[]]$Feature,

        # Path to drivers to inject
        [ValidateNotNullOrEmpty()]
        [ValidateScript({
                    Test-Path -Path $(Resolve-Path $_)
        })]
        [string[]]$Driver,

        # Path of packages to install via DSIM
        [ValidateNotNullOrEmpty()]
        [ValidateScript({
                    Test-Path -Path $(Resolve-Path $_)
        })]
        [string[]]$Package,

        # Bypass the warning and about lost data
        [switch]$Force
    )
    Process {
        $Path = $Path | get-FullFilePath 
        $SourcePath = $SourcePath | get-FullFilePath

        $VhdxFileName = Split-Path -Leaf -Path $Path

        if ($pscmdlet.ShouldProcess("Overwrite partitions inside [$Path] with contentce of [$SourcePath]",
                "Overwrite partitions inside [$Path] with contentce of [$SourcePath]? ",
        'Overwrite WARNING!'))
        {
            if($Force -Or $pscmdlet.ShouldContinue('Are you sure? Any existin data will be lost!', 'Warning')) 
            {
                #region ISO detection
                # If we're using an ISO, mount it and get the path to the WIM file.
                if (([IO.FileInfo]$SourcePath).Extension -ilike '.ISO') 
                {
                    # If the ISO isn't local, copy it down so we don't have to worry about resource contention
                    # or about network latency.
                    if (Test-IsNetworkLocation $SourcePath) 
                    {
                        Write-Verbose -Message "[$($MyInvocation.MyCommand)] : Copying ISO [$(Split-Path -Path $SourcePath -Leaf)] to temp folder"
                        $null = Robocopy.exe $(Split-Path -Path $SourcePath -Parent) $env:temp $(Split-Path -Path $SourcePath -Leaf)
                        $SourcePath = "$($env:temp)\$(Split-Path -Path $SourcePath -Leaf)"
            
                        $tempSource = $SourcePath
                    }

                    $isoPath = (Resolve-Path $SourcePath).Path

                    Write-Verbose -Message "Opening ISO $(Split-Path -Path $isoPath -Leaf)..."
                    $openIso     = Mount-DiskImage -ImagePath $isoPath -StorageType ISO -PassThru
                    # Refresh the DiskImage object so we can get the real information about it.  I assume this is a bug.
                    $openIso     = Get-DiskImage -ImagePath $isoPath
                    $driveLetter = ($openIso | Get-Volume).DriveLetter

                    $SourcePath  = "$($driveLetter):\sources\install.wim"

                    # Check to see if there's a WIM file we can muck about with.
                    Write-Verbose -Message "Looking for $($SourcePath)..."
                    if (!(Test-Path $SourcePath)) 
                    {
                        throw 'The specified ISO does not appear to be valid Windows installation media.'
                    }
                }
                #endregion
                
                #region WIM on network
                # Check to see if the WIM is local, or on a network location.  If the latter, copy it locally.
                if (Test-IsNetworkLocation $SourcePath) 
                {
                    Write-Verbose -Message "Copying WIM $(Split-Path -Path $SourcePath -Leaf) to temp folder..."
                    $null = Robocopy.exe $(Split-Path -Path $SourcePath -Parent) $TempDirectory $(Split-Path -Path $SourcePath -Leaf)
                    $SourcePath = "$($TempDirectory)\$(Split-Path -Path $SourcePath -Leaf)"
            
                    $tempSource = $SourcePath
                }

                $SourcePath  = (Resolve-Path $SourcePath).Path
                #endregion
                
                #region mount the VHDX file
                try 
                {
                    Write-Verbose -Message "[$($MyInvocation.MyCommand)] [$VhdxFileName] : Mounting disk image [$Path]"
                    $disk = Mount-DiskImage -ImagePath $Path -PassThru |
                    Get-DiskImage |
                    Get-Disk
                }
                catch 
                {
                    throw $_.Exception.Message
                }
                #endregion
               
                
                try 
                {
                    Write-Verbose -Message "[$($MyInvocation.MyCommand)] [$VhdxFileName] : Processing disknumber [$($disk.Number)]"
                    
                    #region Assign Drive Letters
                    foreach ($partition in (Get-Partition -DiskNumber $disk.Number | 
                    Where-Object -Property Type -NE -Value Reserved))
                    {
                        $partition | Add-PartitionAccessPath -AssignDriveLetter -ErrorAction Stop
                    } 
                    # Workarround for new drivletters in script modules
                    $null = Get-PSDrive
                    Write-Verbose -Message (Get-Partition -DiskNumber $disk.Number | Out-String)
                    #endregion

                    #region get partitions
                    $RecoveryToolsPartition = Get-Partition -DiskNumber $disk.Number | 
                    Where-Object -Property Type -EQ -Value Recovery | 
                    Select-Object -First 1 
                    if ((Get-Partition -DiskNumber $disk.Number | 
                    Where-Object -Property Type -EQ -Value Recovery).count -gt 1)
                    {
                        $RecoveryImagePartition = Get-Partition -DiskNumber $disk.Number | 
                        Where-Object -Property Type -EQ -Value Recovery | 
                        Select-Object -Last 1 
                    }
                    $WindowsPartition = Get-Partition -DiskNumber $disk.Number | 
                    Where-Object -Property Type -EQ -Value Basic| 
                    Select-Object -First 1 
                    $SystemPartition = Get-Partition -DiskNumber $disk.Number | 
                    Where-Object -Property Type -EQ -Value System| 
                    Select-Object -First 1 
                    #endregion

                    # region Recovery Image
                    if ($RecoveryImagePartition)
                    {
                        #copy the WIM to recovery image partition as Install.wim
                        $recoverfolder = Join-Path -Path "$($RecoveryImagePartition.DriveLetter):" -ChildPath 'Recovery'
                        $null = mkdir -Path $recoverfolder
                        $recoveryPath = Join-Path -Path $recoverfolder -ChildPath 'install.wim'
                        Write-Verbose -Message "[$($MyInvocation.MyCommand)] [$VhdxFileName] Partition [$($RecoveryImagePartition.PartitionNumber)] : copying $SourcePath to $recoveryPath"
                        #Copy-Item -Path $SourcePath -Destination $recoveryPath -ErrorAction Stop
                    } # end if Recovery
                    #endregion

                    

                    #region Windows partition 

                    if ($WindowsPartition)
                    {
                        $WinPath = Join-Path -Path "$($WindowsPartition.DriveLetter):" -ChildPath '\'
                        $windir = Join-Path -Path $WinPath -ChildPath Windows
                        Write-Verbose -Message "[$($MyInvocation.MyCommand)] [$VhdxFileName] Partition [$($WindowsPartition.partitionNumber)] : Applying image from [$SourcePath] to [$WinPath] using Index [$Index]"
                        $null = Expand-WindowsImage -ImagePath $SourcePath -Index $Index -ApplyPath $WinPath -ErrorAction Stop
                    }
                    else 
                    {
                        throw 'Unable to find OS partition'
                    }

                    if ($Unattend) 
                    {
                        $unattendpath = Join-Path -Path $WinPath -ChildPath 'Unattend.xml'
                        Write-Verbose -Message "[$($MyInvocation.MyCommand)] [$VhdxFileName] Partition [$($WindowsPartition.partitionNumber)] : Copying [$Unattend] to [$unattendpath]"
                        Copy-Item -Path $Unattend -Destination $unattendpath -ErrorAction Stop
                    }

                    if ($Driver) 
                    {
                        Write-Verbose -text 'Adding Windows Drivers to the Image'

                        $Driver | ForEach-Object -Process 
                        {
                            Write-Verbose -text "Driver path: $PSItem"
                            $Dism = Add-WindowsDriver -Path $WinPath -Recurse -Driver $PSItem
                        }
                    }

                    If ($Feature) 
                    {            
                        Write-Verbose -text "Installing Windows Feature(s) $Feature to the Image"
                        $FeatureSourcePath = Join-Path -Path "$($driveLetter):" -ChildPath 'sources\sxs'
                        Write-Verbose -text "From $FeatureSourcePath"
                        $Dism = Enable-WindowsOptionalFeature -FeatureName $Feature -Source $FeatureSourcePath -Path $windowsDrive -All
                    }

                    if ($Package) 
                    {
                        Write-Verbose -text 'Adding Windows Packages to the Image'
            
                        $Package | ForEach-Object -Process {
                            Write-Verbose -text "Package path: $PSItem"
                            $Dism = Add-WindowsPackage -Path $windowsDrive -PackagePath $PSItem
                        }
                    }

                    #endregion
                    break                
                    #region System partition
                    $System = $partitions | Where-Object -Property Type -EQ -Value System
                    if (-not $System)
                    {
                        throw 'Unable to find System partition'
                    }
                    $partitionNumber = $System[0].PartitionNumber
                
                    Write-Verbose -Message "[$($MyInvocation.MyCommand)] [$VhdxFileName] Partition [$partitionNumber] : Assigning drive letter to System partition"
                    Get-Partition -DiskNumber $disknumber -PartitionNumber $partitionNumber |
                    Add-PartitionAccessPath -AssignDriveLetter
                    $null = Get-PSDrive
                    $SystemPartition = Get-Partition -DiskNumber $disknumber -PartitionNumber $partitionNumber
                    $sysDrive = "$($SystemPartition.driveletter):"
                    Write-Verbose -Message "[$($MyInvocation.MyCommand)] [$VhdxFileName] Partition [$partitionNumber] : Running bcdboot-> [$windir] /s [$sysDrive] /f UEFI"
                    $cmd = "$windir\System32\bcdboot.exe $windir /s $sysDrive /F UEFI"
                    #Invoke-Expression -Command $cmd
                    Start-Process -Wait -FilePath "$windir\System32\bcdboot.exe" -ArgumentList "$windir /s $sysDrive /F UEFI"  -NoNewWindow
                    #post processing
                    Write-Verbose -Message "[$($MyInvocation.MyCommand)] [$VhdxFileName] :"
                    Write-Verbose -Message (Get-Partition -DiskNumber $disknumber | Out-String)
                    #endregion

                    if ($Recovery)
                    { 
                        $RecoveryPartition = Get-Partition -DiskNumber $disknumber -PartitionNumber $partitionNumber -ErrorAction Stop
                        $recoverfolder = Join-Path -Path "$($RecoveryPartition.DriveLetter):" -ChildPath 'Recovery'
                        
                        $cmd = "$windir\System32\reagentc.exe /setosimage /path $recoverfolder /index $Index /target $windir" 
                        Write-Verbose -Message "[$($MyInvocation.MyCommand)] [$VhdxFileName] Partition [$partitionNumber] : $cmd"
                        #Invoke-Expression -Command $cmd
                        Start-Process -Wait -FilePath "$windir\System32\reagentc.exe" -ArgumentList "/setosimage /path $recoverfolder /index $Index /target $windir"  -NoNewWindow
                        #mount the recovery tools partition with a drive letter
                        $partitionNumber = $Recovery[0].PartitionNumber
                        Write-Verbose -Message "[$($MyInvocation.MyCommand)] [$VhdxFileName] Partition [$partitionNumber] : Formatting Windows RE Tools partition"
                        $null = Get-Partition -DiskNumber $disknumber -PartitionNumber $partitionNumber |
                        Format-Volume -FileSystem NTFS -NewFileSystemLabel 'Windows RE Tools' -Confirm:$false
                        if (-Not (Get-Partition -DiskNumber $disknumber -PartitionNumber $partitionNumber).DriveLetter) 
                        {
                            Write-Verbose -Message "[$($MyInvocation.MyCommand)] [$VhdxFileName] Partition [$partitionNumber] : Assigning drive letter to Windows RE Tools partition"
                            Get-Partition -DiskNumber $disknumber -PartitionNumber $partitionNumber |
                            Add-PartitionAccessPath -AssignDriveLetter
                        }
                        $null = Get-PSDrive
                        $retools = Get-Partition -DiskNumber $disknumber -PartitionNumber $partitionNumber
                        #create \Recovery\WindowsRE
                        Write-Verbose -Message "[$($MyInvocation.MyCommand)] [$VhdxFileName] Partition [$partitionNumber] : Creating Recovery\WindowsRE folder"
                        $repath = mkdir -Path "$($retools.driveletter):\Recovery\WindowsRE"
                        Write-Verbose -Message "[$($MyInvocation.MyCommand)] [$VhdxFileName] Partition [$partitionNumber] : Copying $($WindowsPartition.DriveLetter):\Windows\System32\recovery\winre.wim to $($repath.fullname)"
                        #the winre.wim file is hidden
                        Get-ChildItem -Path "$($WindowsPartition.DriveLetter):\Windows\System32\recovery\winre.wim" -Hidden |
                        Copy-Item -Destination $repath.FullName
                    } # end if Recovery
                }
                catch 
                {
                    Write-Error -Message "[$($MyInvocation.MyCommand)] [$VhdxFileName] : Error setting partition content "
                    throw $_.Exception.Message
                }
                finally 
                {
                    Write-Verbose -Message "[$($MyInvocation.MyCommand)] [$VhdxFileName] : Removing Drive letters"
                    Get-Partition -DiskNumber $disk.number |
                    Where-Object -FilterScript {
                        $_.driveletter
                    }  |
                    ForEach-Object -Process {
                        $dl = "$($_.DriveLetter):"
                        $_ |
                        Remove-PartitionAccessPath -AccessPath $dl
                    }
                    #dismount
                    Write-Verbose -Message "[$($MyInvocation.MyCommand)] [$VhdxFileName] : Dismounting"
                    $null = Dismount-DiskImage -ImagePath $Path
                    $null = Dismount-DiskImage -ImagePath $isoPath -ErrorAction SilentlyContinue
                    Write-Verbose -Message "[$($MyInvocation.MyCommand)] [$VhdxFileName] : Finished"
                }
            }
            else 
            {
                Write-Warning -Message 'Process aborted by user'
            }
        }
        else 
        {
            # Write-Warning 'Process aborted by user'
        }
       
    }
}
