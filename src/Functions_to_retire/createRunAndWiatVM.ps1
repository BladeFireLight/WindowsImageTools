function createRunAndWaitVM
{
    [CmdletBinding()]
    param
    (
        [string] $vhdPath,
        [string] $vmGeneration,
        [Hashtable] $configData
    )

    $vmName = [System.IO.Path]::GetRandomFileName().split('.')[0]

    Write-Verbose -Message "[$($MyInvocation.MyCommand)] : Creating VM $vmName at $(Get-Date)"
    $null = New-VM -Name $vmName -MemoryStartupBytes 2048mb -VHDPath $vhdPath -Generation $vmGeneration -SwitchName $configData.vmSwitch -ErrorAction Stop

    If ($configData.vLan -ne 0)
    {
        Get-VMNetworkAdapter -VMName $vmName | Set-VMNetworkAdapterVlan -Access -VlanId $configData.vLan
    }

    Set-VM -Name $vmName -ProcessorCount 2
    Start-VM -Name $vmName

    # Give the VM a moment to start before we start checking for it to stop
    Start-Sleep -Seconds 10

    # Wait for the VM to be stopped for a good solid 5 seconds
    do
    {
        $state1 = (Get-VM | Where-Object name -EQ -Value $vmName).State
        Start-Sleep -Seconds 5

        $state2 = (Get-VM | Where-Object name -EQ -Value $vmName).State
        Start-Sleep -Seconds 5
    }
    until (($state1 -eq 'Off') -and ($state2 -eq 'Off'))

    # Clean up the VM
    Write-Verbose -Message "[$($MyInvocation.MyCommand)] : VM $vmName Stoped"
    Remove-VM -Name $vmName -Force
    Write-Verbose -Message "[$($MyInvocation.MyCommand)] : VM $vmName Deleted at $(Get-Date)"
}

