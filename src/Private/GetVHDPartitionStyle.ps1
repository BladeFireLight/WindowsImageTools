Function GetVHDPartitionStyle
{
    param
    (
        [string]$vhd
    )
    $PartitionStyle = (Mount-VHD -Path $vhd -ReadOnly -Passthru | Get-Disk).PartitionStyle
    Dismount-VHD -Path $vhd
    Start-Sleep -Seconds 2
    return $PartitionStyle
}
