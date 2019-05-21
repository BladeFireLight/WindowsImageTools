function RunExecutable
{
    <#
      .SYNOPSIS
      Runs an external executable file, and validates the error level.

      .PARAMETER Executable
      The path to the executable to run and monitor.

      .PARAMETER Arguments
      An array of arguments to pass to the executable when it's executed.

      .PARAMETER SuccessfulErrorCode
      The error code that means the executable ran successfully.
      The default value is 0.
      #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory, HelpMessage = 'Path to Executable')]
        [string]
        [ValidateNotNullOrEmpty()]
        $Executable,

        [Parameter(Mandatory, HelpMessage = 'aray of arguments to pass to executable')]
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

    if ($ret.ExitCode -ne $SuccessfulErrorCode)
    {
        throw "$Executable failed with code $($ret.ExitCode)!"
    }
}
