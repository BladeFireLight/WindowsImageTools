function Get-WindowsImageFromIso {
<#
    .SYNOPSIS
    Lists Windows images available in a WIM file inside an ISO.

    .DESCRIPTION
    Mounts the specified ISO, locates the WIM file, lists its contents using Get-WindowsImage, and then dismounts the ISO.

    .PARAMETER Path
    The path to the ISO file containing the Windows image.

    .EXAMPLE
    Get-WindowsImageFromIso -Path 'C:\Images\Win10.iso'

    Lists the available Windows images in the WIM file inside the specified ISO.

    .NOTES
    Author: WindowsImageTools Team
    Requires: Administrator privileges
#>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0, HelpMessage = 'Enter the path to the ISO file')]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({ Test-Path $_ })]
        [string]$Path
    )

    $mountResult = Mount-DiskImage -ImagePath $Path -PassThru
    $driveLetter = ($mountResult | Get-Volume).DriveLetter
    if (-not $driveLetter) {
        throw "Failed to get drive letter for mounted ISO."
    }
    $mountedPath = $driveLetter + ":\"

    $wimFiles = Get-ChildItem -Path $mountedPath -Filter *.wim -Recurse
    if ($wimFiles.Count -eq 0) {
        Dismount-DiskImage -ImagePath $Path
        throw "No WIM files found in mounted ISO."
    }
    foreach ($wim in $wimFiles) {
        Write-Host "Listing images in $($wim.FullName):"
        Get-WindowsImage -ImagePath $wim.FullName
    }
    Dismount-DiskImage -ImagePath $Path
}
