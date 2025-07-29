
Function Get-HelloWorld {
    <#
    .SYNOPSIS
    Returns a Hello World string or a custom value.

    .DESCRIPTION
    Returns the string 'Hello World' or a custom value if specified. This function is useful for testing or demonstration purposes.

    .PARAMETER Value
    The string value to return. Defaults to 'GetHelloWorld'.

    .EXAMPLE
    PS> Get-HelloWorld
    Returns 'GetHelloWorld'.

    .EXAMPLE
    PS> Get-HelloWorld -Value 'Hello World!'
    Returns 'Hello World!'.

    .NOTES
    Author: WindowsImageTools Team
    #>
    [OutputType([string])]
    [CmdletBinding()]
    param (
        # Parameter description can go here or above in format: .PARAMETER  <Parameter-Name>
        [Parameter()]
        [string]$Value = 'GetHelloWorld'
    )

    $Value
}
