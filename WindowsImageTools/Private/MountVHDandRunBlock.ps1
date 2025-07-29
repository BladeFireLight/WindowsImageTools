function MountVhdAndRunBlock {
    <#
    .SYNOPSIS
    Mounts a VHD, runs a script block, and unmounts the VHD.

    .DESCRIPTION
    Mounts the specified VHD file, executes the provided script block, and then dismounts the VHD. The drive letter of the mounted VHD is stored in $driveLetter and can be used within the script block. Supports read-only mounting.

    .PARAMETER vhd
    The path to the VHD or VHDX file to mount.

    .PARAMETER block
    The script block to execute while the VHD is mounted.

    .PARAMETER ReadOnly
    If specified, mounts the VHD in read-only mode.

    .EXAMPLE
    MountVhdAndRunBlock -vhd 'C:\Temp\disk.vhdx' -block { Write-Output "Mounted!" }
    Mounts the VHD and runs the script block, then unmounts the VHD.

    .EXAMPLE
    MountVhdAndRunBlock -vhd 'C:\Temp\disk.vhdx' -block { Get-ChildItem "$driveLetter:\" } -ReadOnly
    Mounts the VHD in read-only mode, lists files, then unmounts.

    .NOTES
    Author: BladeFireLight
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position=0)]
        [string]$vhd,
        [Parameter(Mandatory, Position=1)]
        [scriptblock]$block,
        [switch]$ReadOnly
    )

    process {
        # Mount the VHD
        if ($ReadOnly) {
            $virtualDisk = Mount-VHD -Path $vhd -ReadOnly -PassThru
        } else {
            $virtualDisk = Mount-VHD -Path $vhd -PassThru
        }
        # Workaround for new drive letters in script modules
        $null = Get-PSDrive
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "")]
        $driveLetter = ($virtualDisk |
            Get-Disk |
            Get-Partition |
            Get-Volume).DriveLetter
        & $block

        Dismount-VHD -Path $vhd

        # Wait 2 seconds for activity to clean up
        Start-Sleep -Seconds 2
    }
}
