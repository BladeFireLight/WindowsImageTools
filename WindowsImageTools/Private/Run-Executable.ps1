function RunExecutable {
    <#
    .SYNOPSIS
    Runs an external executable file and validates the exit code.

    .DESCRIPTION
    Runs the specified executable with arguments, waits for completion, and checks the exit code. Standard output and error are redirected to temporary files. Throws an error if the exit code does not match the expected value.

    .PARAMETER Executable
    The path to the executable to run and monitor.

    .PARAMETER Arguments
    An array of arguments to pass to the executable when it's executed.

    .PARAMETER SuccessfulErrorCode
    The exit code that means the executable ran successfully. Default is 0.

    .EXAMPLE
    RunExecutable -Executable 'C:\Windows\System32\notepad.exe' -Arguments @('file.txt')

    Runs notepad.exe with file.txt as an argument and checks for exit code 0.

    .EXAMPLE
    RunExecutable -Executable 'C:\Temp\myTool.exe' -Arguments @('-run', '-quiet') -SuccessfulErrorCode 1

    Runs myTool.exe with arguments and expects exit code 1 for success.

    .NOTES
    Author: BladeFireLight
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory, HelpMessage = 'Path to Executable')]
        [string]
        [ValidateNotNullOrEmpty()]
        $Executable,

        [Parameter(Mandatory, HelpMessage = 'array of arguments to pass to executable')]
        [string[]]
        [ValidateNotNullOrEmpty()]
        $Arguments,

        [Parameter()]
        [int]
        $SuccessfulErrorCode = 0

    )

    $exeName = Split-Path -Path $Executable -Leaf
    Write-Verbose -Message "[$($MyInvocation.MyCommand)] : Running [$Executable] [$Arguments]"
    $Params = @{
        'FilePath'               = $Executable
        'ArgumentList'           = $Arguments
        'NoNewWindow'            = $true
        'Wait'                   = $true
        'RedirectStandardOutput' = "$($env:temp)\$($exeName)-StandardOutput.txt"
        'RedirectStandardError'  = "$($env:temp)\$($exeName)-StandardError.txt"
        'PassThru'               = $true
    }

    Write-Verbose -Message ($Params | Out-String)
    $ret = Start-Process @Params -ErrorAction SilentlyContinue

    Write-Verbose -Message "[$($MyInvocation.MyCommand)] : Return code was [$($ret.ExitCode)]"

    if ($ret.ExitCode -ne $SuccessfulErrorCode) {
        throw "$Executable failed with code $($ret.ExitCode)!"
    }
}
