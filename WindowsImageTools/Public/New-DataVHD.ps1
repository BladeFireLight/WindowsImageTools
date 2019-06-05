function New-DataVHD
{
    <#
    .Synopsis
    Create a VHDX Data Drive with GPT partitions
    .DESCRIPTION
    This command will create a VHD or VHDX with a GPT partition table
    formated ReFS(Default) or NTFS. You must supply the path to the VHD/VHDX file
    Use -Force to overwite existing file (ACLs will be copied to new file)
    .EXAMPLE
    New-DataVHD -Path c:\Data.vhdx -Size 20GB -Dynamic
    Creats a new 20GB Data VHDX that is dynamic, formated ReFS
    .EXAMPLE
    New-DataVHD -Path c:\data.vhdx -Size 100GB -DataFormat NTFS
    Creats a new 100GB Data VHDX formated NTFS
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

        # Format drive as NTFS or ReFS (Only applies when DiskLayout = Data)
        [string]
        [ValidateNotNullOrEmpty()]
        [ValidateSet('NTFS', 'ReFS')]
        $DataFormat = 'ReFS',

        # Size in Bytes (Default 40B)
        [ValidateRange(100mb, 64TB)]
        [long]$Size = 40GB,

        # MS Reserved Partition Size (Default : 128MB)
        [int]$ReservedSize,

        # Create Dynamic disk
        [switch]$Dynamic,

        # Force the overwrite of existing files
        [switch]$force

    )
    $Path = $Path | Get-FullFilePath
    $VhdxFileName = Split-Path -Leaf -Path $Path

    if ($pscmdlet.ShouldProcess("[$($MyInvocation.MyCommand)] : Overwrite partitions inside [$Path] with GPT Data Partitions",
            "Overwrite partitions inside [$Path] with GPT Data Partitions ? ",
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
                'DiskLayout' = 'Data'
                'DataFormat' = $DataFormat
            }
            if ($Dynamic)
            {
                $InitializeVHDPartitionParam.add('Dynamic', $true)
            }
            if ($ReservedSize)
            {
                $InitializeVHDPartitionParam.add('ReservedSize', $ReservedSize)
            }
            Write-Verbose -Message "[$($MyInvocation.MyCommand)] : InitializeVHDPartitionParam"
            Write-Verbose -Message ($InitializeVHDPartitionParam | Out-String)
            Write-Verbose -Message "[$($MyInvocation.MyCommand)] : ParametersToPass"
            Write-Verbose -Message ($ParametersToPass | Out-String)
            Try
            {
                Initialize-VHDPartition @InitializeVHDPartitionParam @ParametersToPass
            }
            Catch
            {
                throw "$($_.Exception.Message) at $($_.Exception.InvocationInfo.ScriptLineNumber)"
            }
            #region mount the VHDX file
            try
            {
                Write-Verbose -Message "[$($MyInvocation.MyCommand)] [$VhdxFileName] : Mounting disk image [$Path]"
                $disk = Mount-DiskImage -ImagePath $Path -PassThru |
                Get-DiskImage |
                Get-Disk
                $DiskNumber = $disk.Number
            }
            catch
            {
                throw $_.Exception.Message
            }
            #endregion

            try
            {
                #! Workarround for new drive letters in script modules
                $null = Get-PSDrive

                #region Assign Drive Letters (disable explorer popup and reset afterwords)
                $DisableAutoPlayOldValue = (Get-ItemProperty -path hkcu:\Software\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers -name DisableAutoplay).DisableAutoplay
                Set-ItemProperty -Path hkcu:\Software\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers -Name DisableAutoplay -Value 1
                foreach ($partition in (Get-Partition -DiskNumber $DiskNumber |
                        where-object -FilterScript { $_.Type -eq 'IFS' -or $_.type -eq 'basic' }))
                {
                    $partition | Add-PartitionAccessPath -AssignDriveLetter -ErrorAction Stop
                }
                #! Workarround for new drive letters in script modules
                $null = Get-PSDrive
                Set-ItemProperty -Path hkcu:\Software\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers -Name DisableAutoplay -Value $DisableAutoPlayOldValue
            }
            catch
            {
                Write-Error -Message "[$($MyInvocation.MyCommand)] [$VhdxFileName] : Error Adding Drive Letter "
                throw $_.Exception.Message
            }
            finally
            {
                #dismount
                Write-Verbose -Message "[$($MyInvocation.MyCommand)] [$VhdxFileName] : Dismounting"
                $null = Dismount-DiskImage -ImagePath $Path
                if ($isoPath -and (Get-DiskImage $isoPath).Attached)
                {
                    $null = Dismount-DiskImage -ImagePath $isoPath
                    [System.GC]::Collect()
                }
                Write-Verbose -Message "[$($MyInvocation.MyCommand)] [$VhdxFileName] : Finished"
            }
        }
    }
}
