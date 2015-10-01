#requires -Version 1

function Get-FullFilePath
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

    if (-not (Test-Path $Path))
    {
        if (Test-Path (Split-Path -Path $Path -Parent ))
        {
            $Parent = Resolve-Path (Split-Path -Path $Path -Parent )
            $Leaf = Split-Path -Path $Path -Leaf
            
            if ($Parent.path[-1] -eq '\') 
            {
                $Path = "$Parent" + "$Leaf"
            }
            else 
            {
                $Path = "$Parent" + "\$Leaf"
            }
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
    
    return $Path
}

function 
Test-Admin 
{
    <#
            .SYNOPSIS
            Short function to determine whether the logged-on user is an administrator.

            .EXAMPLE
            Do you honestly need one?  There are no parameters!

            .OUTPUTS
            $true if user is admin.
            $false if user is not an admin.
    #>
    [CmdletBinding()]
    param()

    $currentUser = New-Object -TypeName Security.Principal.WindowsPrincipal -ArgumentList $([Security.Principal.WindowsIdentity]::GetCurrent())
    $isAdmin = $currentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
    Write-Verbose -Message "[$($MyInvocation.MyCommand)] : is User Admin? [$isAdmin]"

    return $isAdmin
}


function
Run-Executable 
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
        [Parameter(Mandatory = $true)]
        [string]
        [ValidateNotNullOrEmpty()]
        $Executable,

        [Parameter(Mandatory = $true)]
        [string[]]
        [ValidateNotNullOrEmpty()]
        $Arguments,

        [Parameter()]
        [int]
        [ValidateNotNullOrEmpty()]
        $SuccessfulErrorCode = 0

    )

    $exeName = Split-Path -Path $Executable -Leaf
    Write-Verbose -Message "[$($MyInvocation.MyCommand)] : Running [$Executable] [$Arguments]"
    $Params = @{
        'FilePath'             = $Executable
        'ArgumentList'         = $Arguments
        'NoNewWindow'          = $true
        'Wait'                 = $true
        'RedirectStandardOutput' = "$($env:temp)\$($exeName)-StandardOutput.txt"
        'RedirectStandardError' = "$($env:temp)\$($exeName)-StandardError.txt"
        'PassThru'             = $true
    }

    Write-Verbose -Message ($Params | Out-String)
    $ret = Start-Process @Params

    Write-Verbose "[$($MyInvocation.MyCommand)] : Return code was [$($ret.ExitCode)]"

    if ($ret.ExitCode -ne $SuccessfulErrorCode) 
    {
        throw "$Executable failed with code $($ret.ExitCode)!"
    }
}

Function Test-IsNetworkLocation 
{
    <#
            .SYNOPSIS
            Determines whether or not a given path is a network location or a local drive.
            
            .DESCRIPTION
            Function to determine whether or not a specified path is a local path, a UNC path,
            or a mapped network drive.

            .PARAMETER Path
            The path that we need to figure stuff out about,
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeLine = $true)]
        [string]
        [ValidateNotNullOrEmpty()]
        $Path
    )

    $result = $false
    
    if ([bool]([URI]$Path).IsUNC) 
    {
        $result = $true
    } 
    else 
    {
        $driveInfo = [IO.DriveInfo]((Resolve-Path $Path).Path)

        if ($driveInfo.DriveType -eq 'Network') 
        {
            $result = $true
        }
    }

    return $result
}

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
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([System.IO.DirectoryInfo])]
    Param
    (
    )

    #return [System.IO.Directory]::CreateDirectory((Join-Path $env:Temp -Ch ([System.IO.Path]::GetRandomFileName().split('.')[0])))

    Begin
    {
        try
        {
            if($PSCmdlet.ShouldProcess($env:temp))
            {
                $tempDirPath = [System.IO.Directory]::CreateDirectory((Join-Path $env:temp -ChildPath ([System.IO.Path]::GetRandomFileName().split('.')[0])))
            }
        }
        catch
        {
            $errorRecord = [System.Management.Automation.ErrorRecord]::new($_.Exception,'NewTemporaryDirectoryWriteError', 'WriteError', $env:temp)
            Write-Error -ErrorRecord $errorRecord
            return
        } 

        if($tempDirPath)
        {
            Get-Item $env:temp\$tempDirPath
        }
    }
}
