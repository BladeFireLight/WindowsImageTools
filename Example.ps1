if (get-module WindowsImageTools) { Remove-Module WindowsImageTools}

import-module $PSScriptRoot\WindowsImageTools

Initialize-VHDPartition -Path $env:temp\temp1.vhdx -Dynamic -Verbose -DiskLayout UEFI -RecoveryImage -force -Passthru |  
    Set-VHDPartition  -SourcePath C:\iso\Win10ent_x64.ISO -Index 1  -Confirm:$false -force -Verbose 

Convert-Wim2VHD -Path $env:temp\test2.vhdx -SourcePath C:\iso\Server2012R2.ISO -DiskLayout UEFI -Dynamic -Index 1 -Size 60GB  -Force -Verbose -RecoveryImage

