properties {
    # Disable "compiling" module into monolithinc PSM1.
    # This modifies the default behavior from the "Build" task
    # in the PowerShellBuild shared psake task module
    $PSBPreference.Build.CompileModule = $true
}

task default -depends Test

task Test -FromModule PowerShellBuild -Version '0.3.0'
