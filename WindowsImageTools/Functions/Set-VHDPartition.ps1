function Set-VHDPartition
{
    <#
            .Synopsis
            Sets the content of a VHD(X) using a source WIM or ISO
            .DESCRIPTION
            This command will copy the content of the SourcePath ISO or WIM and populate the 
            partitions found in the VHD(X) You must supply the path to the VHD(X) file and a 
            valid WIM/ISO. You should also include the index number for the Windows Edition 
            to install. If two Recovery paritiotns are present the source WIM will be copied 
            to the recovery partition. Optionally, you can also specify an XML file to be 
            inserted into the OS partition as unattend.xml, any Drivers, WindowsUpdate (MSU)
            or Optional Features you want installed.
            CAUTION: This command will replace the content partitions.
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
        [ValidateScript({ if ($_){ Test-Path -Path $_}
                          else { $true} })]
        [string]$Unattend,

        # Native Boot does not have the boot code iniside the VHD(x) it must exist on the phisical disk. 
        [switch]$NativeBoot,

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

        if ($pscmdlet.ShouldProcess("[$($MyInvocation.MyCommand)] : Overwrite partitions inside [$Path] with content of [$SourcePath]",
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
                        Write-Verbose -Message "[$($MyInvocation.MyCommand)] : Copying ISO [$(Split-Path -Path $SourcePath -Leaf)] to [$env:temp]"
                        $null = Robocopy.exe $(Split-Path -Path $SourcePath -Parent) $env:temp $(Split-Path -Path $SourcePath -Leaf)
                        $SourcePath = "$($env:temp)\$(Split-Path -Path $SourcePath -Leaf)"
            
                        $tempSource = $SourcePath
                    }

                    $isoPath = (Resolve-Path $SourcePath).Path

                    Write-Verbose -Message "[$($MyInvocation.MyCommand)] : Opening ISO $(Split-Path -Path $isoPath -Leaf)"
                    $openIso     = Mount-DiskImage -ImagePath $isoPath -StorageType ISO -PassThru
                    # Refresh the DiskImage object so we can get the real information about it.  I assume this is a bug.
                    $openIso     = Get-DiskImage -ImagePath $isoPath
                    $driveLetter = ($openIso | Get-Volume).DriveLetter

                    $SourcePath  = "$($driveLetter):\sources\install.wim"

                    # Check to see if there's a WIM file we can muck about with.
                    Write-Verbose -Message "[$($MyInvocation.MyCommand)] : Looking for $($SourcePath)"
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
                    Write-Verbose -Message "[$($MyInvocation.MyCommand)] : Copying WIM $(Split-Path -Path $SourcePath -Leaf) to [$env:temp]"
                    $null = Robocopy.exe $(Split-Path -Path $SourcePath -Parent) $env:temp $(Split-Path -Path $SourcePath -Leaf)
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
                    Write-Verbose -Message "[$($MyInvocation.MyCommand)] [$VhdxFileName] : Munted as disknumber [$($disk.Number)]"
                    
                    #region Assign Drive Letters
                    foreach ($partition in (Get-Partition -DiskNumber $disk.Number | 
                    Where-Object -Property Type -NE -Value Reserved))
                    {
                        $partition | Add-PartitionAccessPath -AssignDriveLetter -ErrorAction Stop
                    } 
                    # Workarround for new drive letters in script modules
                    $null = Get-PSDrive
                    Write-Verbose -Message "[$($MyInvocation.MyCommand)] [$VhdxFileName] : Partition Table"
                    Write-Verbose -Message (Get-Partition -DiskNumber $disk.Number | select PartitionNumber, DriveLetter, Size, Type| Out-String)
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

                    if (-not ($WindowsPartition -and $SystemPartition))
                    {
                        $WindowsPartition = Get-Partition -DiskNumber $disk.Number | 
                        Where-Object -Property Type -EQ -Value IFS| 
                        Select-Object -First 1 
                        $SystemPartition = $WindowsPartition
                    }
                    #endregion

                    # region Recovery Image
                    if ($RecoveryImagePartition)
                    {
                        #copy the WIM to recovery image partition as Install.wim
                        $recoverfolder = Join-Path -Path "$($RecoveryImagePartition.DriveLetter):" -ChildPath 'Recovery'
                        $null = mkdir -Path $recoverfolder
                        $recoveryPath = Join-Path -Path $recoverfolder -ChildPath 'install.wim'
                        Write-Verbose -Message "[$($MyInvocation.MyCommand)] [$VhdxFileName] Recovery Image Partition [$($RecoveryImagePartition.PartitionNumber)] : copying [$SourcePath] to [$recoveryPath]"
                        Copy-Item -Path $SourcePath -Destination $recoveryPath -ErrorAction Stop
                    } # end if Recovery
                    #endregion

                    #region Windows partition 
                    if ($WindowsPartition)
                    {
                        $WinPath = Join-Path -Path "$($WindowsPartition.DriveLetter):" -ChildPath '\'
                        $windir = Join-Path -Path $WinPath -ChildPath Windows
                        Write-Verbose -Message "[$($MyInvocation.MyCommand)] [$VhdxFileName] Windows Partition [$($WindowsPartition.partitionNumber)] : Applying image from [$SourcePath] to [$WinPath] using Index [$Index]"
                        $null = Expand-WindowsImage -ImagePath $SourcePath -Index $Index -ApplyPath $WinPath -ErrorAction Stop
                    }
                    else 
                    {
                        throw 'Unable to find OS partition'
                    }
                    #endregion
 
                     #region System partition
                    if ($SystemPartition -and (-not ($NativeBoot)))
                    {
                        $sysDrive = "$($SystemPartition.driveletter):"
                        Write-Verbose -Message "[$($MyInvocation.MyCommand)] [$VhdxFileName] System Partition [$($SystemPartition.partitionNumber)] : Running bcdboot-> [$windir] /s [$sysDrive] /f UEFI"
                        Start-Process -Wait -FilePath "$windir\System32\bcdboot.exe" -ArgumentList "$windir /s $sysDrive /F UEFI"  -NoNewWindow
                    }
                                    

                    #region Recovery Tools
                    if ($RecoveryToolsPartition)
                    {
                        $recoverfolder = Join-Path -Path "$($RecoveryToolsPartition.DriveLetter):" -ChildPath 'Recovery'
                        Write-Verbose -Message "[$($MyInvocation.MyCommand)] [$VhdxFileName] Recovery Tools Partition [$($RecoveryToolsPartition.partitionNumber)] : [$cmd]"
                        Start-Process -Wait -FilePath "$windir\System32\reagentc.exe" -ArgumentList "/setosimage /path $recoverfolder /index $Index /target $windir"  -NoNewWindow
                        
                        Write-Verbose -Message "[$($MyInvocation.MyCommand)] [$VhdxFileName] Recovery Tools Partition [$($RecoveryToolsPartition.partitionNumber)] : Creating Recovery\WindowsRE folder [$($RecoveryToolsPartition.driveletter):\Recovery\WindowsRE]"
                        $repath = mkdir -Path "$($RecoveryToolsPartition.driveletter):\Recovery\WindowsRE"
                        Write-Verbose -Message "[$($MyInvocation.MyCommand)] [$VhdxFileName] Recovery Tools Partition [$($RecoveryToolsPartition.partitionNumber)] : Copying [$($WindowsPartition.DriveLetter):\Windows\System32\recovery\winre.wim] to [$($repath.fullname)]"
                        #the winre.wim file is hidden
                        Get-ChildItem -Path "$($WindowsPartition.DriveLetter):\Windows\System32\recovery\winre.wim" -Hidden |
                        Copy-Item -Destination $repath.FullName
                    }
                    #endregion

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
                    if ($isopath -and (Get-DiskImage $isoPath).Attached)
                    { 
                        $null = Dismount-DiskImage -ImagePath $isoPath 
                    }
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
