function Get-FullFilePath
{
    <#
      .Synopsis
      Get Absolute path from relative path
      .DESCRIPTION
      Takes a relative path like .\file.txt and returns the full path.
      The target file does not have to exist, but the parent folder must exist
      .EXAMPLE
      $path = Get-AbsoluteFilePath -Path .\file.txt
      #>
    [CmdletBinding()]
    [OutputType([string])]
    Param
    (
        # Path to file
        [Parameter(Mandatory, HelpMessage = 'Path to file',
            ValueFromPipeline,
            Position = 0)]
        [String]$Path
    )

    process {
        if (-not (Test-Path -Path $Path))
        {
            if (Test-Path -Path (Split-Path -Path $Path -Parent ))
            {
                $Parent = Resolve-Path -Path (Split-Path -Path $Path -Parent )
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
            $Path = Resolve-Path -Path $Path
        }

        return $Path
    }
}
