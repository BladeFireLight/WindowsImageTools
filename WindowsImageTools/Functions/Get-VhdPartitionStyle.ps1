Function Get-VhdPartitionStyle
{
    param
    (
        [string]$vhd 
    )
    $PartitionStyle = (Mount-VHD $vhd -ReadOnly -Passthru | Get-Disk).PartitionStyle
    Dismount-VHD $vhd
    Start-Sleep -Seconds 2
    return $PartitionStyle
}         
