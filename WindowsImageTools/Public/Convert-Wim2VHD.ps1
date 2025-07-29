function Convert-Wim2VHD
{
  <#
    .SYNOPSIS
    Creates a VHD or VHDX and populates it from a WIM or ISO image.

    .DESCRIPTION
    This command creates a VHD or VHDX file formatted for UEFI (Gen 2/GPT), BIOS (Gen 1/MBR), or Windows To Go (MBR).
    You must supply the path to the VHD/VHDX file and a valid WIM or ISO image. Optionally, specify the index number for the Windows edition to install.
    Additional options allow customization of disk layout, partition sizes, features, drivers, and packages.

    .EXAMPLE
    Convert-Wim2VHD -Path c:\windows8.vhdx -SourcePath d:\Source\install.wim -DiskLayout UEFI

    Creates a VHDX of the default size with GPT partitions for UEFI (Gen2).

    .EXAMPLE
    Convert-Wim2VHD -Path c:\windowsServer.vhdx -SourcePath d:\Source\install.wim -Index 3 -Size 40GB -Force -DiskLayout UEFI

    Creates a 40GB VHDX using index 3 with GPT partitions for UEFI (Gen2), overwriting any existing file.

    .EXAMPLE
    Convert-Wim2VHD -Path c:\win2go.vhd -SourcePath d:\Source\install.wim -DiskLayout WindowsToGo

    Creates a Windows To Go VHD image that can boot in UEFI or BIOS mode.

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
    [ValidateNotNullorEmpty()]
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

    # Path to file to copy inside of VHD(X) as C:\unattent.xml
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

    # Path of packages to install via DSIM
    [ValidateNotNullOrEmpty()]
    [ValidateScript( {
        foreach ($Path in $_)
        {
          Test-Path -Path $(Resolve-Path $Path)
        }
      })]
    [string[]]$Package,
    # Files/Folders to copy to root of Winodws Drive (to place files in directories mimic the direcotry structure off of C:\)
    [ValidateNotNullOrEmpty()]
    [ValidateScript( {
        foreach ($Path in $_)
        {
          Test-Path -Path $(Resolve-Path $Path)
        }
      })]
    [string[]]$filesToInject

  )
  $Path = $Path | Get-FullFilePath
  $SourcePath = $SourcePath | Get-FullFilePath

  #$VhdxFileName = Split-Path -Leaf -Path $Path

  if ($pscmdlet.ShouldProcess("[$($MyInvocation.MyCommand)] : Overwrite partitions inside [$Path] with content of [$SourcePath]",
      "Overwrite partitions inside [$Path] with contentce of [$SourcePath]? ",
      'Overwrite WARNING!'))
  {
    if ((-not (Test-Path $Path)) -Or $force -Or $pscmdlet.ShouldContinue('Are you sure? Any existin data will be lost!', 'Warning'))
    {
      $ParametersToPass = @{ }
      foreach ($key in ('Whatif', 'Verbose', 'Debug'))
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


