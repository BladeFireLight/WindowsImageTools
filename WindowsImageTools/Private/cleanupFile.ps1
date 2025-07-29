function cleanupFile {
    <#
    .SYNOPSIS
    Removes files or directories if they exist.

    .DESCRIPTION
    Accepts one or more file or directory paths and deletes them if present.

    .PARAMETER File
    The path(s) to the file(s) or directory(ies) to remove.

    .EXAMPLE
    cleanupFile -File 'C:\Temp\test.txt','C:\Temp\folder'

    Removes the specified file and folder if they exist.

    .NOTES
    Uses Remove-Item with -Recurse and -Force.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName, Position = 0)]
        [Alias('Path')]
        [string[]] $File
    )

    process {
        foreach ($target in $File) {
            if (Test-Path -Path $target) {
                Remove-Item -Path $target -Recurse -Force
            }
        }
    }
}
