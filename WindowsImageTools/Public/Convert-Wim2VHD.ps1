function Convert-Wim2VHD
{
  <#
    .SYNOPSIS
    Creates a VHD or VHDX and populates it from a WIM or ISO image.

    .DESCRIPTION
    Creates a VHD or VHDX file formatted for UEFI (Gen 2/GPT), BIOS (Gen 1/MBR), or Windows To Go (MBR). You must supply the path to the VHD/VHDX file and a valid WIM or ISO image. Optionally, specify the index number for the Windows edition to install. Additional options allow customization of disk layout, partition sizes, features, drivers, packages, and more.

    .PARAMETER Path
    The path to the new VHD or VHDX file. Must end in .vhd or .vhdx.

    .PARAMETER SourcePath
    The path to the WIM or ISO file used to populate the VHD(X).

    .PARAMETER DiskLayout
    Specifies the disk layout: BIOS (MBR), UEFI (GPT), or WindowsToGo (MBR).

    .PARAMETER Size
    The size of the VHD(X) in bytes. Default is 40GB.

    .PARAMETER Index
    The index of the image inside the WIM. Default is 1.

    .PARAMETER Dynamic
    If specified, creates a dynamic disk.

    .PARAMETER NoRecoveryTools
    If specified, skips creation of the recovery tools partition.

    .PARAMETER SystemSize
    Size of the system (boot loader) partition.

    .PARAMETER ReservedSize
    Size of the MS Reserved partition.

    .PARAMETER RecoverySize
    Size of the recovery tools partition.

    .PARAMETER Force
    If specified, overwrites existing files.

    .PARAMETER Unattend
    Path to an unattend.xml file to copy into the VHD(X).

    .PARAMETER NativeBoot
    If specified, prepares the VHD(X) for native boot.

    .PARAMETER Feature
    Features to enable (in DISM format).

    .PARAMETER RemoveFeature
    Features to remove (in DISM format).

    .PARAMETER FeatureSource
    Path to feature source files or folders.

    .PARAMETER FeatureSourceIndex
    Index for feature source WIM. Default is 1.

    .PARAMETER Driver
    Paths to drivers to inject.

    .PARAMETER AddPayloadForRemovedFeature
    If specified, adds payload for all removed features.

    .PARAMETER Package
    Paths to packages to install via DISM.


    .PARAMETER filesToInject
    Files or folders to copy to the root of the Windows drive.

    .PARAMETER UseDismExpansion
    If specified, uses DISM.exe for image expansion instead of native PowerShell.

    .EXAMPLE
    Convert-Wim2VHD -Path c:\windows8.vhdx -SourcePath d:\Source\install.wim -DiskLayout UEFI

    Creates a VHDX of the default size with GPT partitions for UEFI (Gen2).

    .EXAMPLE
    Convert-Wim2VHD -Path c:\windowsServer.vhdx -SourcePath d:\Source\install.wim -Index 3 -Size 40GB -Force -DiskLayout UEFI

    Creates a 40GB VHDX using index 3 with GPT partitions for UEFI (Gen2), overwriting any existing file.

    .EXAMPLE
    Convert-Wim2VHD -Path c:\win2go.vhd -SourcePath d:\Source\install.wim -DiskLayout WindowsToGo

    Creates a Windows To Go VHD image that can boot in UEFI or BIOS mode.

    .EXAMPLE
    Convert-Wim2VHD -Path c:\windows8.vhdx -SourcePath d:\Source\install.wim -DiskLayout UEFI -UseDismExpansion $true

    Creates a VHDX using DISM.exe for image expansion. This is required due to CrowdStrike blocking PowerShell from writing core files like SAM to the target disk.

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

    # Size in Bytes (Default 40B)
    [ValidateRange(35GB, 64TB)]
    [long]$Size = 40GB,

    # Create Dynamic disk
    [switch]$Dynamic,

    # Specifies whether to build the image for BIOS (MBR), UEFI (GPT), or WindowsToGo (MBR).
    # Generation 1 VMs require BIOS (MBR) images.  Generation 2 VMs require UEFI (GPT) images.
    # Windows To Go images will boot in UEFI or BIOS
    [Parameter(Mandatory = $true)]
    [Alias('Layout')]
    [string]
    [ValidateNotNullOrEmpty()]
    [ValidateSet('BIOS', 'UEFI', 'WindowsToGo')]
    $DiskLayout,

    # Skip the creation of the Recovery Environment Tools Partition.
    [switch]$NoRecoveryTools,

    # System (boot loader) Partition Size (Default : 260MB)
    [int]$SystemSize,

    # MS Reserved Partition Size (Default : 128MB)
    [int]$ReservedSize,

    # Recovery Tools Partition Size (Default : 905MB)
    [int]$RecoverySize,

    # Force the overwrite of existing files
    [switch]$force,

    # Path to WIM or ISO used to populate VHDX
    [parameter(Position = 1, Mandatory = $true,
      HelpMessage = 'Enter the path to the WIM/ISO file')]
    [ValidateScript( {
        Test-Path -Path (Get-FullFilePath -Path $_ )
      })]
    [string]$SourcePath,

    # Index of image inside of WIM (Default 1)
    [int]$Index = 1,

    # Path to file to copy inside of VHD(X) as C:\unattend.xml
    [ValidateScript( {
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

    # Native Boot does not have the boot code inside the VHD(x) it must exist on the physical disk.
    [switch]$NativeBoot,

    # Features to turn on (in DISM format)
    [ValidateNotNullOrEmpty()]
    [string[]]$Feature,

    # Feature to remove (in DISM format)
    [ValidateNotNullOrEmpty()]
    [string[]]$RemoveFeature,

    # Feature Source path. If not provided, all ISO and WIM images in $sourcePath searched
    [ValidateNotNullOrEmpty()]
    [ValidateScript( {
        ($_ -eq 'NONE') -or (Test-Path -Path $(Resolve-Path $_))
      })]
    [string]$FeatureSource,

    # Feature Source index. If the source is a .wim provide an index Default =1
    [int]$FeatureSourceIndex = 1,

    # Path to drivers to inject
    [ValidateNotNullOrEmpty()]
    [ValidateScript( {
        foreach ($Path in $_)
        {
          Test-Path -Path $(Resolve-Path $Path)
        }
      })]
    [string[]]$Driver,

    # Add payload for all removed features
    [switch]$AddPayloadForRemovedFeature,

    # Path of packages to install via DISM
    [ValidateNotNullOrEmpty()]
    [ValidateScript( {
        foreach ($Path in $_)
        {
          Test-Path -Path $(Resolve-Path $Path)
        }
      })]
    [string[]]$Package,
    # Files/Folders to copy to root of Windows Drive (to place files in directories mimic the directory structure off of C:\)
    [ValidateNotNullOrEmpty()]
    [ValidateScript( {
        foreach ($Path in $_)
        {
          Test-Path -Path $(Resolve-Path $Path)
        }
      })]
    [string[]]$filesToInject,

    # Use DISM for expansion instead of native PowerShell
    [Parameter(HelpMessage = 'Use DISM for expansion instead of native PowerShell')]
    [switch]$UseDismExpansion

  )
  $Path = $Path | Get-FullFilePath
  $SourcePath = $SourcePath | Get-FullFilePath

  #$VhdxFileName = Split-Path -Leaf -Path $Path

  if ($psCmdlet.ShouldProcess("[$($MyInvocation.MyCommand)] : Overwrite partitions inside [$Path] with content of [$SourcePath]",
      "Overwrite partitions inside [$Path] with content of [$SourcePath]? ",
      'Overwrite WARNING!'))
  {
    if ((-not (Test-Path $Path)) -Or $force -Or $psCmdlet.ShouldContinue('Are you sure? Any existing data will be lost!', 'Warning'))
    {
      $ParametersToPass = @{ }
      foreach ($key in ('WhatIf', 'Verbose', 'Debug'))
      {
        if ($PSBoundParameters.ContainsKey($key))
        {
          $ParametersToPass[$key] = $PSBoundParameters[$key]
        }
      }

      $InitializeVHDPartitionParam = @{
        'Size'       = $Size
        'Path'       = $Path
        'force'      = $true
        'DiskLayout' = $DiskLayout
      }
      if ($NoRecoveryTools)
      {
        $InitializeVHDPartitionParam.add('NoRecoveryTools', $true)
      }
      if ($Dynamic)
      {
        $InitializeVHDPartitionParam.add('Dynamic', $true)
      }
      if ($SystemSize) { $InitializeVHDPartitionParam.add('SystemSize', $SystemSize) }
      if ($ReservedSize) { $InitializeVHDPartitionParam.add('ReservedSize', $ReservedSize) }
      if ($RecoverySize) { $InitializeVHDPartitionParam.add('RecoverySize', $RecoverySize) }

      $SetVHDPartitionParam = @{
        'SourcePath' = $SourcePath
        'Path'       = $Path
        'Index'      = $Index
        'force'      = $true
        'Confirm'    = $false
      }
      if ($Unattend)
      {
        $SetVHDPartitionParam.add('Unattend', $Unattend)
      }
      if ($NativeBoot)
      {
        $SetVHDPartitionParam.add('NativeBoot', $NativeBoot)
      }
      if ($Feature)
      {
        $SetVHDPartitionParam.add('Feature', $Feature)
      }
      if ($RemoveFeature)
      {
        $SetVHDPartitionParam.add('RemoveFeature', $RemoveFeature)
      }
      if ($FeatureSource)
      {
        $SetVHDPartitionParam.add('FeatureSource', $FeatureSource)
      }
      if ($FeatureSourceIndex)
      {
        $SetVHDPartitionParam.add('FeatureSourceIndex', $FeatureSourceIndex)
      }
      if ($AddPayloadForRemovedFeature)
      {
        $SetVHDPartitionParam.add('AddPayloadForRemovedFeature', $AddPayloadForRemovedFeature)
      }
      if ($Driver)
      {
        $SetVHDPartitionParam.add('Driver', $Driver)
      }
      if ($Package)
      {
        $SetVHDPartitionParam.add('Package', $Package)
      }
      if ($filesToInject)
      {
        $SetVHDPartitionParam.add('filesToInject', $filesToInject)
      }
      if ($PSBoundParameters.ContainsKey('UseDismExpansion')) {
        $SetVHDPartitionParam.add('UseDismExpansion', $UseDismExpansion.IsPresent)
      }
      Write-Verbose -Message "[$($MyInvocation.MyCommand)] : InitializeVHDPartitionParam"
      Write-Verbose -Message ($InitializeVHDPartitionParam | Out-String)
      Write-Verbose -Message "[$($MyInvocation.MyCommand)] : SetVHDPartitionParam"
      Write-Verbose -Message ($SetVHDPartitionParam | Out-String)
      Write-Verbose -Message "[$($MyInvocation.MyCommand)] : ParametersToPass"
      Write-Verbose -Message ($ParametersToPass | Out-String)

      Try
      {
        Initialize-VHDPartition @InitializeVHDPartitionParam @ParametersToPass
        Set-VHDPartition @SetVHDPartitionParam @ParametersToPass
      }
      Catch
      {
        throw "$($_.Exception.Message) at $($_.Exception.InvocationInfo.ScriptLineNumber)"
      }
    }
  }
}


