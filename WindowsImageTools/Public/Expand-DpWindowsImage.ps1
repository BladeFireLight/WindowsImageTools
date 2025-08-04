function Expand-DpWindowsImage {
<#
    .SYNOPSIS
    Applies a Windows image from a WIM file to a target directory using DISM.

    .DESCRIPTION
    Wrapper for DISM.exe to apply a specific image index from a WIM file to a target directory. Mimics Expand-WindowsImage. Optionally uses /Compact for compact OS deployment.

    .PARAMETER ImagePath
    Path to the WIM file containing the Windows image.

    .PARAMETER Index
    Index of the image inside the WIM to apply.

    .PARAMETER ApplyPath
    Target directory where the image will be applied.

    .PARAMETER Compact
    If specified, applies the image using the /Compact option for compact OS deployment.

    .EXAMPLE
    Expand-DpWindowsImage -ImagePath 'C:\images\install.wim' -Index 1 -ApplyPath 'D:\Windows'

    Applies the first image from install.wim to the D:\Windows directory using DISM.

    .EXAMPLE
    Expand-DpWindowsImage -ImagePath 'C:\images\install.wim' -Index 1 -ApplyPath 'D:\Windows' -Compact

    Applies the first image from install.wim to the D:\Windows directory using DISM with the /Compact option for compact OS deployment.

    .NOTES
    Author: WindowsImageTools Team
    Requires: Administrator privileges
#>
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param (
        [Parameter(Mandatory, Position = 0, HelpMessage = 'Path to the WIM file')]
        [ValidateNotNullOrEmpty()]
        [string]$ImagePath,

        [Parameter(Mandatory, Position = 1, HelpMessage = 'Index of the image inside the WIM')]
        [ValidateNotNullOrEmpty()]
        [int]$Index,

        [Parameter(Mandatory, Position = 2, HelpMessage = 'Target directory to apply the image')]
        [ValidateNotNullOrEmpty()]
        [string]$ApplyPath,

        [switch]$Compact
    )

    $ImagePath = Get-FullFilePath -Path $ImagePath
    $ApplyPath = Get-FullFilePath -Path $ApplyPath

    $dismArgs = @(
        '/Apply-Image',
        "/ImageFile:$ImagePath",
        "/Index:$Index",
        "/ApplyDir:$ApplyPath"
    )
    if ($Compact) {
        $dismArgs += '/Compact'
    }

    if ($PSCmdlet.ShouldProcess("Apply image index $Index from $ImagePath to $ApplyPath")) {
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = 'dism.exe'
        $psi.Arguments = $dismArgs -join ' '
        $psi.RedirectStandardOutput = $true
        $psi.RedirectStandardError = $true
        $psi.UseShellExecute = $false
        $psi.CreateNoWindow = $true
        $process = [System.Diagnostics.Process]::Start($psi)
        $progressActivity = 'Expand Windows Image'
        $progressId = 0
        $lastPercent = 0
        while (-not $process.HasExited) {
            while ($null -ne ($line = $process.StandardOutput.ReadLine())) {
                if ($line -match '(\d{1,3}\.\d)%') {
                    $percent = [double]$Matches[1]
                    $lastPercent = $percent
                    Write-Progress -Id $progressId -Activity $progressActivity -Status "$percent% Complete" -PercentComplete $percent
                }
            }
            Start-Sleep -Milliseconds 100
        }
        # Read any remaining output after exit
        while ($null -ne ($line = $process.StandardOutput.ReadLine())) {
            if ($line -match '(\d{1,3}\.\d)%') {
                $percent = [double]$Matches[1]
                $lastPercent = $percent
                Write-Progress -Id $progressId -Activity $progressActivity -Status "$percent% Complete" -PercentComplete $percent
            }
        }
        # Always write 100% on exit
        Write-Progress -Id $progressId -Activity $progressActivity -Status '100% Complete' -PercentComplete 100 -Completed
        $stderr = $process.StandardError.ReadToEnd()
        if ($process.ExitCode -ne 0) {
            throw "DISM failed with exit code $($process.ExitCode): $stderr"
        }
    }
}
