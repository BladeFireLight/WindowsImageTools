function Convert-Wim2GenTwoVhdx
{
    <#
            .Synopsis
            Create a VHDX and populate it from a WIM
            .DESCRIPTION
            This command will update partitions for a Generate 2 VHDX file, configured for UEFI. 
            You must supply the path to the VHDX file and a valid WIM. You should also
            include the index number for the Windows Edition to install.
            .EXAMPLE
            Convert-WIM2VHDX -Path c:\windows8.vhdx -WimPath d:\Source\install.wim -Recovery
            .EXAMPLE
            Convert-WIM2VHDX -Path c:\windowsServer.vhdx -WimPath d:\Source\install.wim -index 3 -Size 40GB -force
    #>
    [CmdletBinding(SupportsShouldProcess = $true, 
            PositionalBinding = $false,
    ConfirmImpact = 'Medium')]
    Param
    (
        # Path to VHDX 
        [parameter(Position = 0,Mandatory = $true,
        HelpMessage = 'Enter the path to the VHDX file')]
        [Alias('FullName','pspath')]
        [ValidateNotNullorEmpty()]
        [ValidatePattern(".\.vhdx$")]
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
        
        # Path to WIM used to populate VHDX
        [parameter(Position = 1,Mandatory = $true,
        HelpMessage = 'Enter the path to the WIM file')]
        [ValidateScript({
                    Test-Path -Path $_
        })]
        [string]$WIMPath,
        
        # Index of image inside of WIM (Default 1)
        [ValidateScript({
                    ,
                    $last = (Get-WindowsImage -ImagePath $PSBoundParameters.WIMPath |
                        Sort-Object -Property ImageIndex |
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
                    Test-Path  -Path $_ 
        })]
        [string]$Unattend,
        
        # Size in Bytes from 25GB - 64TB (Default 40GB)
        [ValidateRange(25GB,64TB)]
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
        $Recovery,

        # Force overwrite of vhdx
        [switch]
        $Force


    )
    $ParametersToPass = @{}
    foreach ($key in ('Whatif', 'Verbose', 'Debug'))
    {
        if ($PSBoundParameters.ContainsKey($key)) 
        {
            $ParametersToPass[$key] = $PSBoundParameters[$key]
        }
    }
    # make paths absolute
    $Path = $Path | get-AbsoluteFilePath 
    $WIMPath = $WIMPath | get-AbsoluteFilePath


    if ($pscmdlet.ShouldProcess("[$Path]", "Create new Bootable VHDX and populate from [$WIMPath]"))
    {
        if ((Test-Path -Path $Path) -and $Force)
        {
            Write-Warning -Message "Replacing $Path"
            Remove-Item $Path -Force @ParametersToPass
        }
        
        if (-not (Test-Path -Path $Path)) 
        {
            $InitializeGen2BootDiskParam = @{
                'BlockSizeBytes'        = $BlockSizeBytes
                'LogicalSectorSizeBytes' = $LogicalSectorSizeBytes
                'PhysicalSectorSizeBytes' = $PhysicalSectorSizeBytes
                'Size'                  = $Size
                'Path'                  = $Path
            }
            if ($Recovery)
            {
                $InitializeGen2BootDiskParam.add('Recovery', $true)
            }
            if ($Dynamic)
            {
                $InitializeGen2BootDiskParam.add('Dynamic', $true)
            }
            $SetGenTwoBootDiskFromWimParam = @{
                'Confirm' = $false
                'WIMPath' = $WIMPath
                'Path'  = $Path
                'Index' = $Index
                'force' = $true
            }
            if ($Unattend)
            {
                $SetGenTwoBootDiskFromWimParam.add('Unattend', $Unattend)
            }
            Write-Verbose -Message "[$($MyInvocation.MyCommand)] : InitializeGen2BootDiskParam"
            Write-Verbose -Message ($InitializeGen2BootDiskParam | Out-String)
            Write-Verbose -Message "[$($MyInvocation.MyCommand)] : SetGenTwoBootDiskFromWimParam"
            Write-Verbose -Message ($SetGenTwoBootDiskFromWimParam | Out-String)
            Write-Verbose -Message "[$($MyInvocation.MyCommand)] : ParametersToPass"
            Write-Verbose -Message ($ParametersToPass | Out-String)
            
            Try
            {
                $null = Initialize-GenTwoBootDisk @InitializeGen2BootDiskParam @ParametersToPass 
                Set-GenTwoBootDiskFromWim @SetGenTwoBootDiskFromWimParam @ParametersToPass
            }
            Catch
            {
                throw "$($_.Exception.Message) at $($_.Exception.InvocationInfo.ScriptLineNumber)"
            }
        }
            
        else
        {
            Throw "$Path allready exists"
        }
    }
}

