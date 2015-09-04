if (get-module WindowsImageTools) { Remove-Module WindowsImageTools}

import-module $PSScriptRoot\WindowsImageTools

Initialize-VHDPartition -Path $env:temp\temp1.vhdx -Dynamic -Verbose -DiskLayout UEFI -RecoveryImage -force -Passthru |  
    Set-VHDPartition  -SourcePath $PSScriptRoot\Example.wim -Index 1  -Confirm:$false -force -Verbose 

Convert-Wim2VHD -Path $env:temp\test2.vhdx -SourcePath $PSScriptRoot\Example.wim -DiskLayout UEFI -Dynamic -Index 1 -Size 50GB  -Force -Verbose -RecoveryImage

#to test : Configure OS unattend, install drivers, patches and features