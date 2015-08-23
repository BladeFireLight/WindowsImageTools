#requires -Version 2 -Modules Hyper-V, Storage
. $PSScriptRoot\Functions\Convert-Wim2GenTwoVhdx.ps1
. $PSScriptRoot\Functions\Initialize-GenTwoBootDisk.ps1
. $PSScriptRoot\Functions\Set-GenTwoBootDiskFromWim.ps1

function get-AbsoluteFilePath
{
    <#
            .Synopsis
            Get Absolute path from relative path
            .DESCRIPTION
            Takes a relative path like .\file.txt and returns the full path.
            Parent folder must exist, but target file does not.
            The target file does not have to exist, but the parent folder must exist
            .EXAMPLE
            $path = Get-AbsoluteFilePath -Path .\file.txt
    #>
    [CmdletBinding()]
    [OutputType([string])]
    Param
    (
        # Path to file
        [Parameter(Mandatory = $true,
                ValueFromPipeline = $true,
        Position = 0)]
        $Path
    )

    if ([string]::IsNullOrEmpty($path)) { return 'c:\' }
    else {
    if (-not (Test-Path $Path))
    {
        if (Test-Path (Split-Path -Path $Path -Parent ))
        {
            $Parent = Resolve-Path (Split-Path -Path $Path -Parent )
            $Leaf = Split-Path -Path $Path -Leaf
            
            if ($Parent.path[-1] -eq '\') { $Path = "$Parent" + "$Leaf" }
            else {$Path = "$Parent" + "\$Leaf"}
        }
        else 
        {
            throw "Parent [$(Split-Path -Path $Path -Parent)] does not exist"
        }
    }
    else 
    {
        $Path = Resolve-Path $Path
    }
    }
    return $Path
}
