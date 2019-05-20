function Initialize-DataDisk
{
    <#
    .Synopsis
    Partition GPT and Fomat as a Data Drive
    .DESCRIPTION
    This command will Partition and Format the disk as a Data Drive.
    .EXAMPLE
    Initialize-DataDisk -DiskNumber 1 -DataFormat ReFS
    .EXAMPLE
    Initialize-DataDisk -DiskNumber 1 -DataFormat NTFS
    #>
    [CmdletBinding(SupportsShouldProcess = $true,
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
        [string]$DiskNumber,

        # Format drive as NTFS or ReFS (Only applies when DiskLayout = Data)
        [string]
        [ValidateNotNullOrEmpty()]
        [ValidateSet('NTFS', 'ReFS')]
        $DataFormat = 'ReFS',

        # Force the overwrite of existing files
        [switch]$force
    )
    if ($pscmdlet.ShouldProcess("[$($MyInvocation.MyCommand)] : Overwrite partitions on disk [$DiskNumber]",
            "Overwrite partitions on disk [$DiskNumber]? ",
            'Overwrite WARNING!'))
    {
        if ((Get-Disk -Number $DiskNumber | Get-Partition -ErrorAction SilentlyContinue) -Or $force -Or $pscmdlet.ShouldContinue('Are you sure? Any existin data will be lost!', 'Warning'))
        {
            $ParametersToPass = @{ }
            foreach ($key in ('Whatif', 'Verbose', 'Debug'))
            {
                if ($PSBoundParameters.ContainsKey($key))
                {
                    $ParametersToPass[$key] = $PSBoundParameters[$key]
                }
            }

            $InitializeDiskPartitionParam = @{
                'DiskNumber' = $DiskNumber
                'force'      = $true
                'DiskLayout' = 'Data'
                'DataFormat' = $DataFormat
            }
            Write-Verbose -Message "[$($MyInvocation.MyCommand)] : InitializeDiskPartitionParam"
            Write-Verbose -Message ($InitializeVHDPartitionParam | Out-String)
            Write-Verbose -Message "[$($MyInvocation.MyCommand)] : ParametersToPass"
            Write-Verbose -Message ($ParametersToPass | Out-String)

            Try
            {
                Initialize-DiskPartition @InitializeDiskPartitionParam @ParametersToPass
            }
            Catch
            {
                throw "$($_.Exception.Message) at $($_.Exception.InvocationInfo.ScriptLineNumber)"
            }
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
                Write-Error -Message "[$($MyInvocation.MyCommand)] [$DiskNumber] : Error Adding Drive Letter "
                throw $_.Exception.Message
            }
        }
    }
}


