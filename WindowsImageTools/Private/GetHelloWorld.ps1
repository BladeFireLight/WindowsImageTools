function GetHelloWorld {
    <#
    .SYNOPSIS
    Returns the string 'Hello world'.

    .DESCRIPTION
    Simple function to demonstrate output of a static string.

    .EXAMPLE
    GetHelloWorld

    Returns 'Hello world'.

    .NOTES
    Author: BladeFireLight
    #>
    [CmdletBinding()]
    param()

    process {
        'Hello world'
    }
}
