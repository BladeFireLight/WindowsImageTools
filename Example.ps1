if (get-module GenTwoImageTools) { Remove-Module GenTwoImageTools}

import-module $PSScriptRoot\GenTwoImageTools

Initialize-GenTwoBootDisk -Path $env:temp\temp1.vhdx -Dynamic -Recovery -Verbose|  
    Set-GenTwoBootDiskFromWim  -WIMPath $PSScriptRoot\Example.wim -Index 1  -Confirm:$false -force -Verbose

Convert-Wim2GenTwoVhdx -Path $env:temp\test2.vhdx -WIMPath $PSScriptRoot\Example.wim -Dynamic -Index 1 -Size 50GB  -Force