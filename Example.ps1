if (get-module WindowsImageTools) { Remove-Module WindowsImageTools}

import-module $PSScriptRoot\WindowsImageTools

# del $env:temp\temp1.vhdx
Initialize-VHDPartition -Path $env:temp\temp1.vhdx -Dynamic -Verbose -DiskLayout UEFI -RecoveryImage -force -Passthru |  
    Set-VHDPartition  -SourcePath $PSScriptRoot\Example.wim -Index 1  -Confirm:$false -force -Verbose 

#Mount-VHD  $env:temp\temp1.vhdx
#Get-DiskImage -ImagePath $env:temp\temp1.vhdx 
#Get-Partition -Number 5 | ft PartitionNumber, DriveLetter, Size, Type
#Get-Partition -DiskNumber 5 | Where-Object -Property Type -EQ -Value Recovery | select -First 1 | get-volume
#disMount-VHD  $env:temp\temp1.vhdx

#Convert-Wim2VHD -Path $env:temp\test2.vhdx -WIMPath $PSScriptRoot\Example.wim -Dynamic -Index 1 -Size 50GB  -Force -Verbose

#Create partitions
#Populate Partitions
#Configure OS unattend, install drivers, patches and features