function New-TemporaryDirectory {
    <#
    .SYNOPSIS
    Creates a new temporary directory in the user's temp folder.

    .DESCRIPTION
    Creates a new directory inside $env:TEMP with a random name and returns a System.IO.DirectoryInfo object for the new directory. Handles errors and supports ShouldProcess for confirmation.

    .EXAMPLE
    $TempDirPath = New-TemporaryDirectory

    Creates a new temporary directory and returns its DirectoryInfo object.

    .NOTES
    Author: BladeFireLight
    #>
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([System.IO.DirectoryInfo])]
    Param
    (
    )

    #return [System.IO.Directory]::CreateDirectory((Join-Path $env:Temp -Ch ([System.IO.Path]::GetRandomFileName().split('.')[0])))

    Begin {
        try {
            if ($PSCmdlet.ShouldProcess($env:temp)) {
                $tempDirPath = [System.IO.Directory]::CreateDirectory((Join-Path -Path $env:temp -ChildPath ([System.IO.Path]::GetRandomFileName().split('.')[0])))
            }
        } catch {
            $errorRecord = [System.Management.Automation.ErrorRecord]::new($_.Exception, 'NewTemporaryDirectoryWriteError', 'WriteError', $env:temp)
            Write-Error -ErrorRecord $errorRecord
            return
        }

        if ($tempDirPath) {
            Get-Item -Path $env:temp\$tempDirPath
        }
    }
}
