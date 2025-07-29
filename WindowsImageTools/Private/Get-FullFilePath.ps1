function Get-FullFilePath {
    <#
    .SYNOPSIS
    Returns the absolute path for a given relative or absolute file path.

    .DESCRIPTION
    Takes a relative path (e.g., .\file.txt) or an absolute path and returns the full absolute path as a string. The target file does not have to exist, but the parent directory must exist. If the file exists, its resolved path is returned. If only the parent exists, the function constructs the absolute path.

    .PARAMETER Path
    The path to the file. Can be relative or absolute. The parent directory must exist.

    .EXAMPLE
    $path = Get-FullFilePath -Path .\file.txt

    Returns the absolute path for .\file.txt, even if the file does not exist, as long as the parent directory exists.

    .EXAMPLE
    $path = Get-FullFilePath -Path C:\Temp\myfile.txt

    Returns the absolute path for C:\Temp\myfile.txt.

    .NOTES
    Author: BladeFireLight
    #>
    [CmdletBinding()]
    [OutputType([string])]
    Param
    (
        # Path to file
        [Parameter(Mandatory, HelpMessage = 'Path to file',
            ValueFromPipeline,
            Position = 0)]
        [String]$Path
    )

    process {
        if (-not (Test-Path -Path $Path)) {
            if (Test-Path -Path (Split-Path -Path $Path -Parent )) {
                $Parent = Resolve-Path -Path (Split-Path -Path $Path -Parent )
                $Leaf = Split-Path -Path $Path -Leaf

                if ($Parent.path[-1] -eq '\') {
                    $Path = "$Parent" + "$Leaf"
                } else {
                    $Path = "$Parent" + "\$Leaf"
                }
            } else {
                throw "Parent [$(Split-Path -Path $Path -Parent)] does not exist"
            }
        } else {
            $Path = Resolve-Path -Path $Path
        }

        return $Path
    }
}
