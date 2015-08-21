if (get-module GenTwoImageTools) { Remove-Module GenTwoImageTools}

import-module C:\GitRepo\GenTwoImageTools\GenTwoImageTools

cd g:\temp
Initialize-GenTwoBootDisk -Path .\temp1.vhdx -Dynamic -Recovery -Verbose
Set-GenTwoBootDiskFromWim -Path .\temp1.vhdx -WIMPath .\test.wim -Index 1 -Verbose -Confirm:$false

#Convert-Wim2GenTwoVhdx -Path g:\temp\test1.vhdx -WIMPath g:\temp\test.wim -Dynamic -Index 1 -Size 50GB -Verbose

<# todo
* fix confirm
* replace invoke expression
* add example
* add about_
#>
