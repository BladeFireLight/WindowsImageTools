function New-DpVhd {
<#
    .SYNOPSIS
    Creates a new VHD or VHDX file using diskpart.

    .DESCRIPTION
    Uses diskpart to create a new VHD or VHDX file at the specified path and size. If the file exists, -Force is required to overwrite it. Ensures the path is a file, not a folder.

    .PARAMETER Path
    The path to the new VHD or VHDX file. Must end in .vhd or .vhdx.

    .PARAMETER Size
    The size of the VHD(X) in MB, GB, or TB (e.g., 40GB).

    .PARAMETER Force
    If specified, overwrites the existing file at the path.

    .EXAMPLE
    New-DpVhd -Path 'C:\disks\disk1.vhdx' -Size 40GB -Force

    .NOTES
    Author: WindowsImageTools Team
    Requires: Administrator privileges
#>
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param (
        [Parameter(Mandatory, Position = 0, HelpMessage = 'Path to the new VHD/VHDX file')]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern("\.vhdx?$")]
        [string]$Path,

        [Parameter(Mandatory, Position = 1, HelpMessage = 'Size of the VHD/VHDX in bytes (e.g., 40GB, 128849018880)')]
        [ValidateNotNullOrEmpty()]
        [double]$Size,

        [switch]$Force,

        # If specified, creates a dynamic (expandable) VHD(X). Otherwise, creates a fixed VHD(X).
        [switch]$Dynamic
    )

    # Make path absolute
    $Path = Get-FullFilePath -Path $Path

    # Ensure path is not a folder
    if (Test-Path $Path -PathType Container) {
        throw "The specified path '$Path' is a directory. Please specify a file path ending in .vhd or .vhdx."
    }

    # If file exists, require -Force or confirmation
    if (Test-Path $Path -PathType Leaf) {
        $shouldDelete = $false
        if ($Force) {
            $shouldDelete = $PSCmdlet.ShouldProcess($Path, 'Remove existing file')
        } else {
            $shouldDelete = $PSCmdlet.ShouldProcess($Path, 'Remove existing file') -and $PSCmdlet.ShouldContinue("The file '$Path' already exists. Do you want to overwrite it?", 'Confirm Overwrite')
        }
        if ($shouldDelete) {
            Remove-Item -Path $Path -Force
        } else {
            throw "The file '$Path' already exists. Use -Force to overwrite or confirm the action."
        }
    }

    # Calculate maximum size in MB for diskpart
    $maxMB = [long]($Size / 1MB)

    $type = if ($Dynamic) { 'expandable' } else { 'fixed' }
    $diskpartScript = @"
create vdisk file="$Path" maximum=$maxMB type=$type
"@
    $scriptFile = [System.IO.Path]::GetTempFileName()
    Set-Content -Path $scriptFile -Value $diskpartScript -Encoding ASCII

    try {
        Write-Verbose "Running diskpart to create VHD: $Path"
        $output = diskpart /s $scriptFile 2>&1
        if ($LASTEXITCODE -ne 0 -or ($output -join "`n") -match 'error') {
            throw "diskpart failed: $($output -join "`n")"
        }
    } finally {
        Remove-Item -Path $scriptFile -ErrorAction SilentlyContinue
    }
}

