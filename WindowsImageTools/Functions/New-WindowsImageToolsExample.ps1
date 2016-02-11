<#
        .Synopsis
        Create folders and script examples on the use of Windows Image Tools
        .DESCRIPTION
        Creates the folders structures and example files needed to use Windows Image Tools to auto update windows images.
        .EXAMPLE
        New-WitExample -Path c:\WitExample
        .NOTES
        This is a work in progress
#>
function New-WindowsImageToolsExample
{
    [CmdletBinding(SupportsShouldProcess = $true
    )]
    [OutputType([System.IO.DirectoryInfo])]
    Param
    (
        # Path path to Folder/Directory to create (should not exist)
        [Parameter(Mandatory = $true, 
        Position = 0)]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({
                    If (Test-Path -Path $_) 
                    {
                        throw "$_ allready exist"
                    }
                    else 
                    {
                        $true
                    }
        })]
        [Alias('FullName')] 
        [string]$Path
    )

    if ($pscmdlet.ShouldProcess($Path, 'Create new Windows Image Tools Example'))
    {
        #region File Content
        $ExampleContent = @"

"@
   
        #endregion

        #region varify needed prerequsits

        #endregion
        #region Creat Directories   
        try 
        { 
            $null = New-Item -ItemType Directory -Path $Path -ErrorAction Stop
            $null = New-Item -ItemType Directory -Path $Path\UpdatedImageShare -ErrorAction Stop
            $null = New-Item -ItemType Directory -Path $Path\BaseImage -ErrorAction Stop
            $null = New-Item -ItemType Directory -Path $Path\ISO -ErrorAction Stop
            $null = New-Item -ItemType Directory -Path $Path\Resource -ErrorAction Stop
        }
        catch
        {
            throw "Error creating Directories in $Path"
        }
        #endregion
      
        #region create Files
        try 
        {      
            $null = Set-WitUpdateConfig -Path $Path -WarningAction SilentlyContinue
            $null = New-Item -ItemType File -Path $Path -Name Example.ps1 -Value $ExampleContent -ErrorAction Stop
        }
        catch 
        {
            throw "trying to create files in $Path"
        }
        #endregion

        #region Download Modules
        try 
        {
            Find-Module -Name PSWindowsUpdate -ErrorAction Stop | Save-Module -Force -Path $Path\Resource -ErrorAction Stop
        }
        catch
        {
            Write-Warning -Message 'Unable to download PSWindowsUpdate useing PowerShellGet'
        }
        #endregion
    }
    return (Get-Item $Path)
}
