function cleanupFile
{
    param
    (
        [string[]] $file
    )

    foreach ($target in $file)
    {
        if (Test-Path -Path $target)
        {
            Remove-Item -Path $target -Recurse -Force
        }
    }
}
