function Set-VHDPartition {
  <#
    .Synopsis
    Sets the content of a VHD(x/s) using a source WIM or ISO
    .DESCRIPTION
    This command will copy the content of the SourcePath ISO or WIM and populate the
    partitions found in the VHD(x/s) You must supply the path to the VHD(X/s) file and a
    valid WIM/ISO. You should also include the index number for the Windows Edition
    to install. If the recovery partitions are present the source WIM will be copied
    to the recovery partition. Optionally, you can also specify an XML file to be
    inserted into the OS partition as unattend.xml, any Drivers, WindowsUpdate (MSU)
    or Optional Features you want installed. And any additional files to add.
    CAUTION: This command will replace the content partitions.
    .EXAMPLE
    PS C:\> Set-VHDPartition -Path D:\vhd\demo3.vhdx -SourcePath D:\wim\Win2012R2-Install.wim -Index 1
    .EXAMPLE
    PS C:\> Set-VHDPartition -Path D:\vhd\demo3.vhdx -SourcePath D:\wim\Win2012R2-Install.wim -Index 1 -Confirm:$false -force -Verbose
    #>
  [CmdletBinding(SupportsShouldProcess = $true,
    PositionalBinding = $true,
    ConfirmImpact = 'High')]
  Param
  (
    # Path to VHDX
    [parameter(Position = 0, Mandatory = $true,
      HelpMessage = 'Enter the path to the VHDX file',
      ValueFromPipeline = $true,
      ValueFromPipelineByPropertyName = $true)]
    [Alias('FullName', 'psPath', 'ImagePath')]
    [ValidateScript( {
        Test-Path -Path (Get-FullFilePath -Path $_)
      })]
    [string]$Path,

    # Path to WIM or ISO used to populate VHDX
    [parameter(Position = 1, Mandatory = $true,
      HelpMessage = 'Enter the path to the WIM/ISO file')]
    [ValidateScript( {
        Test-Path -Path (Get-FullFilePath -Path $_ )
      })]
    [string]$SourcePath,

    # Index of image inside of WIM (Default 1)
    [int]$Index = 1,

    # Path to file to copy inside of VHD(X/s) as C:\unattend.xml
    [ValidateScript( {
        if ($_) {
          Test-Path -Path $_
        } else {
          $true
        }
      })]
    [string]$Unattend,

    # Native Boot does not have the boot code inside the VHD(x/s) it must exist on the physical disk.
    [switch]$NativeBoot,

    # Add payload for all removed features
    [switch]$AddPayloadForRemovedFeature,

    # Feature to turn on (in DISM format)
    [ValidateNotNullOrEmpty()]
    [string[]]$Feature,

    # Feature to remove (in DISM format)
    [ValidateNotNullOrEmpty()]
    [string[]]$RemoveFeature,

    # Feature Source path. If not provided, all ISO and WIM images in $sourcePath searched (unused if run on WinPE)
    [ValidateNotNullOrEmpty()]
    [ValidateScript( {
        ($_ -eq 'NONE') -or (Test-Path -Path $(Resolve-Path $_) )
      })]
    [string]$FeatureSource,

    # Feature Source index. If the source is a .wim provide an index Default =1
    [int]$FeatureSourceIndex = 1,

    # Path to drivers to inject
    [ValidateNotNullOrEmpty()]
    [ValidateScript( {
        foreach ($Path in $_) {
          Test-Path -Path $(Resolve-Path $Path)
        }
      })]
    [string[]]$Driver,

    # Path of packages to install via DISM
    [ValidateNotNullOrEmpty()]
    [ValidateScript( {
        foreach ($Path in $_) {
          Test-Path -Path $(Resolve-Path $Path)
        }
      })]
    [string[]]$Package,

    # Files/Folders to copy to root of Windows Drive (to place files in directories mimic the directory structure off of C:\)
    [ValidateNotNullOrEmpty()]
    [ValidateScript( {
        foreach ($Path in $_) {
          Test-Path -Path $(Resolve-Path $Path)
        }
      })]
    [string[]]$filesToInject,

    # Bypass the warning and about lost data
    [switch]$Force
  )


  Process {
    $Path = $Path | Get-FullFilePath
    $SourcePath = $SourcePath | Get-FullFilePath

    $VhdxFileName = Split-Path -Leaf -Path $Path

    if ($psCmdlet.ShouldProcess("[$($MyInvocation.MyCommand)] : Overwrite partitions inside [$Path] with content of [$SourcePath]",
        "Overwrite partitions inside [$Path] with content of [$SourcePath]? ",
        'Overwrite WARNING!')) {
      if ($Force -Or $psCmdlet.ShouldContinue('Are you sure? Any existing data will be lost!', 'Warning')) {
        $ParametersToPass = @{}
        foreach ($key in ('WhatIf', 'Verbose', 'Debug')) {
          if ($PSBoundParameters.ContainsKey($key)) {
            $ParametersToPass[$key] = $PSBoundParameters[$key]
          }
        }


        #region mount the VHDX file
        try {
          Write-Verbose -Message "[$($MyInvocation.MyCommand)] [$VhdxFileName] : Mounting disk image [$Path]"
          $disk = Mount-DiskImage -ImagePath $Path -PassThru |
          Get-DiskImage |
          Get-Disk
        } catch {
          throw $_.Exception.Message
        }
        #endregion

        try {
          Write-Verbose -Message "[$($MyInvocation.MyCommand)] [$VhdxFileName] : Mounted as diskNumber [$($disk.Number)]"

          $SetDiskParam = @{
            DiskNumber = $disk.Number
            SourcePath = $SourcePath
            Index      = $Index
            force      = $force
          }
          if ($Unattend) { $SetDiskParam.add('Unattend', $Unattend) }
          if ($NativeBoot) { $SetDiskParam.add('NativeBoot', $NativeBoot) }
          if ($AddPayloadForRemovedFeature) { $SetDiskParam.add('AddPayloadForRemovedFeature', $AddPayloadForRemovedFeature) }
          if ($Feature) { $SetDiskParam.add('Feature', $Feature) }
          if ($RemoveFeature) { $SetDiskParam.add('RemoveFeature', $RemoveFeature) }
          if ($FeatureSource) { $SetDiskParam.add('FeatureSource', $FeatureSource) }
          if ($FeatureSourceIndex) { $SetDiskParam.add('FeatureSourceIndex', $FeatureSourceIndex) }
          if ($Driver) { $SetDiskParam.add('Driver', $Driver) }
          if ($Package) { $SetDiskParam.add('Package', $Package) }
          if ($filesToInject) { $SetDiskParam.add('filesToInject', $filesToInject) }

          Set-DiskPartition @ParametersToPass @SetDiskParam

        } catch {
          Write-Error -Message "[$($MyInvocation.MyCommand)] [$VhdxFileName] : Error setting partition content "
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
      } else {
        Write-Warning -Message 'Process aborted by user'
      }
    } else {
      # Write-Warning 'Process aborted by user'
    }

  }
}
