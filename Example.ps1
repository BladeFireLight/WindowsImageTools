if (get-module WindowsImageTools) { Remove-Module WindowsImageTools}

import-module $PSScriptRoot\WindowsImageTools

#Initialize-VHDPartition -Path g:\temp\temp1.vhdx -Dynamic -Verbose -DiskLayout BIOS -RecoveryImage -force -Passthru |  
#    Set-VHDPartition -SourcePath C:\iso\Win7ent_x64.ISO -Index 1  -Confirm:$false -force -Verbose 

#Convert-Wim2VHD -Path g:\temp\test2.vhdx -SourcePath C:\iso\Server2012R2.ISO -DiskLayout UEFI -Dynamic -Index 1 -Size 60GB  -Force -Verbose -RecoveryImage
$commonParams = @{
    'Dynamic' = $true
    'Verbose' = $true
    'Force' = $true
    'Unattend' = (New-UnattendXml -AdminPassword 'Local!admin' -logonCount  1)
    'filesToInject' = 'g:\temp\inject\pstemp\'
}

$vhds = @(
    @{
     'SourcePath' = 'C:\iso\server_2016_preview_3.iso'
     'DiskLayout' = 'UEFI'
     'index' = 1
     'size' = 40Gb
     'Path' = 'G:\temp\2016_CoreStd.vhdx'
    },
    @{
     'SourcePath' = 'C:\iso\server_2016_preview_3.iso'
     'DiskLayout' = 'UEFI'
     'index' = 2
     'size' = 40Gb
     'Path' = 'G:\temp\2016_GUIStd.vhdx'
    },
    @{
     'SourcePath' = 'C:\iso\server_2016_preview_3.iso'
     'DiskLayout' = 'UEFI'
     'index' = 3
     'size' = 40Gb
     'Path' = 'G:\temp\2016_CoreDC.vhdx'
    },
    @{
     'SourcePath' = 'C:\iso\server_2016_preview_3.iso'
     'DiskLayout' = 'UEFI'
     'index' = 4
     'size' = 40Gb
     'Path' = 'G:\temp\2016_GUIDC.vhdx'
    },
    @{
     'SourcePath' = 'C:\iso\Svr_2012_R2.ISO'
     'DiskLayout' = 'UEFI'
     'index' = 1
     'size' = 40Gb
     'Path' = 'G:\temp\2012r2_CoreStd.vhdx'
    },
    @{
     'SourcePath' = 'C:\iso\Svr_2012_R2.ISO'
     'DiskLayout' = 'UEFI'
     'index' = 2
     'size' = 40Gb
     'Path' = 'G:\temp\2012r2_GUIStd.vhdx'
    },
    @{
     'SourcePath' = 'C:\iso\Svr_2012_R2.ISO'
     'DiskLayout' = 'UEFI'
     'index' = 3
     'size' = 40Gb
     'Path' = 'G:\temp\2012r2_CoreDC.vhdx'
    },
    @{
     'SourcePath' = 'C:\iso\Svr_2012_R2.ISO'
     'DiskLayout' = 'UEFI'
     'index' = 4
     'size' = 40Gb
     'Path' = 'G:\temp\2012r2_GUIDC.vhdx'
    },
    @{
     'SourcePath' = 'C:\iso\Win10ent_x64.ISO'
     'DiskLayout' = 'UEFI'
     'index' = 1
     'size' = 40GB
     'Path' = 'G:\temp\Win10E_x64_UEFI.vhdx'
    },
    @{
     'SourcePath' = 'C:\iso\Win10ent_x64.ISO'
     'DiskLayout' = 'BIOS'
     'index' = 1
     'size' = 40GB
     'Path' = 'G:\temp\Win10E_x64_BIOS.vhdx'
    },
    @{
     'SourcePath' = 'C:\ISO\Win10ent_x86.ISO'
     'DiskLayout' = 'BIOS'
     'index' = 1
     'size' = 40GB
     'Path' = 'G:\temp\Win10E_x86_BIOS.vhdx'
    },
    @{
     'SourcePath' = 'C:\ISO\Win7ent_x64.ISO'
     'DiskLayout' = 'BIOS'
     'index' = 1
     'size' = 40GB
     'Path' = 'G:\temp\Win7end_x64_BIOS.vhdx'
    },
    @{
     'SourcePath' = 'C:\ISO\Win7ent_x86.ISO'
     'DiskLayout' = 'BIOS'
     'Index' = 1
     'size' = 40GB
     'Path' = 'G:\temp\Win7end_x86_BIOS.vhdx'
    }
)

foreach ($VhdParms in $vhds)
{
    Convert-Wim2VHD @VhdParms @commonParams #-WhatIf
}
