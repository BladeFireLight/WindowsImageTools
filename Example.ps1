if (get-module WindowsImageTools) { Remove-Module WindowsImageTools}

import-module $PSScriptRoot\WindowsImageTools

#Initialize-VHDPartition -Path $env:temp\temp1.vhdx -Dynamic -Recovery -Verbose|  
#    Set-VHDPartition  -WIMPath $PSScriptRoot\Example.wim -Index 1  -Confirm:$false -force -Verbose

Convert-Wim2VHD -Path $env:temp\test2.vhdx -WIMPath $PSScriptRoot\Example.wim -Dynamic -Index 1 -Size 50GB  -Force -Verbose