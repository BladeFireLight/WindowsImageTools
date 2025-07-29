function MountVhdAndRunBlock
{
    param
    (
        [string]$vhd,
        [scriptblock]$block,
        [switch]$ReadOnly
    )

    # This function mounts a VHD, runs a script block and unmounts the VHD.
    # Drive letter of the mounted VHD is stored in $driveLetter - can be used by script blocks
    if ($ReadOnly)
    {
        $virtualDisk = Mount-VHD -Path $vhd -ReadOnly -PassThru
    }
    else
    {
        $virtualDisk = Mount-VHD -Path $vhd -PassThru
    }
    # Workaround for new drive letters in script modules
    $null = Get-PSDrive
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "")]
    $driveLetter = ($virtualDisk |
            Get-Disk |
            Get-Partition |
            Get-Volume).DriveLetter
    & $block

    Dismount-VHD -Path $vhd

    # Wait 2 seconds for activity to clean up
    Start-Sleep -Seconds 2
}
