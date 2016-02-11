function Mount-VhdAndRunBlock 
{
    param
    (
        [string]$vhd, 
        [scriptblock]$block,
        [switch]$ReadOnly
    )
     
    # This function mounts a VHD, runs a script block and unmounts the VHD.
    # Drive letter of the mounted VHD is stored in $driveLetter - can be used by script blocks
    if($ReadOnly) 
    {
        $virtualDisk = Mount-VHD $vhd -ReadOnly -Passthru
    }
    else 
    {
        $virtualDisk = Mount-VHD $vhd -Passthru
    }
    # Workarround for new drive letters in script modules                  
    $null = Get-PSDrive
    $driveLetter = ($virtualDisk |
        Get-Disk |
        Get-Partition |
        Get-Volume).DriveLetter
    & $block

    Dismount-VHD $vhd

    # Wait 2 seconds for activity to clean up
    Start-Sleep -Seconds 2
}
