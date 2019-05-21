function New-TemporaryDirectory
{
    <#
      .Synopsis
      Create a new Temporary Directory
      .DESCRIPTION
      Creates a new Directory in the $env:temp and returns the System.IO.DirectoryInfo (dir)
      .EXAMPLE
      $TempDirPath = NewTemporaryDirectory
      #>
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([System.IO.DirectoryInfo])]
    Param
    (
    )

    #return [System.IO.Directory]::CreateDirectory((Join-Path $env:Temp -Ch ([System.IO.Path]::GetRandomFileName().split('.')[0])))

    Begin
    {
        try
        {
            if ($PSCmdlet.ShouldProcess($env:temp))
            {
                $tempDirPath = [System.IO.Directory]::CreateDirectory((Join-Path -Path $env:temp -ChildPath ([System.IO.Path]::GetRandomFileName().split('.')[0])))
            }
        }
        catch
        {
            $errorRecord = [System.Management.Automation.ErrorRecord]::new($_.Exception, 'NewTemporaryDirectoryWriteError', 'WriteError', $env:temp)
            Write-Error -ErrorRecord $errorRecord
            return
        }

        if ($tempDirPath)
        {
            Get-Item -Path $env:temp\$tempDirPath
        }
    }
}
