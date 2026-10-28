<#
.SYNOPSIS
    Reports the last installed update and pending reboot state for one or more servers.

.DESCRIPTION
    Written to triage patch deployment after a maintenance window. A deployment
    reporting success is not the same as a server being patched and rebooted, and
    this is the gap where failures used to hide.

    Returns the most recent hotfix installed, how many days ago that was, and
    whether the machine is waiting on a reboot. Read only.

.PARAMETER ComputerName
    One or more server names.

.PARAMETER StaleAfterDays
    Flag a server as Stale if its last update is older than this. Default 45.

.EXAMPLE
    .\Get-PatchStatus.ps1 -ComputerName (Get-Content .\servers.txt) |
        Where-Object Status -ne 'OK'
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory, ValueFromPipeline)]
    [string[]]$ComputerName,

    [int]$StaleAfterDays = 45
)

begin {
    # Registry keys that indicate a reboot is outstanding. Any one of these is enough.
    $rebootKeys = @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending'
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired'
    )
    $results = [System.Collections.Generic.List[object]]::new()
}

process {
    foreach ($computer in $ComputerName) {

        try {
            $lastPatch = Get-CimInstance -ClassName Win32_QuickFixEngineering `
                                         -ComputerName $computer `
                                         -ErrorAction Stop |
                         Where-Object InstalledOn |
                         Sort-Object InstalledOn -Descending |
                         Select-Object -First 1

            # Run the reboot check remotely so it reflects the target, not this machine.
            $rebootPending = Invoke-Command -ComputerName $computer -ErrorAction Stop -ScriptBlock {
                param($keys)
                foreach ($key in $keys) {
                    if (Test-Path $key) { return $true }
                }
                return $false
            } -ArgumentList (,$rebootKeys)

            $daysSince = if ($lastPatch.InstalledOn) {
                (New-TimeSpan -Start $lastPatch.InstalledOn -End (Get-Date)).Days
            } else { $null }

            $status = if ($rebootPending)                              { 'RebootPending' }
                      elseif ($null -eq $daysSince)                     { 'Unknown' }
                      elseif ($daysSince -gt $StaleAfterDays)           { 'Stale' }
                      else                                             { 'OK' }

            $results.Add([pscustomobject]@{
                ComputerName   = $computer
                LastHotfix     = $lastPatch.HotFixID
                InstalledOn    = $lastPatch.InstalledOn
                DaysSincePatch = $daysSince
                RebootPending  = $rebootPending
                Status         = $status
            })
        }
        catch {
            $results.Add([pscustomobject]@{
                ComputerName   = $computer
                LastHotfix     = $null
                InstalledOn    = $null
                DaysSincePatch = $null
                RebootPending  = $null
                Status         = 'Unreachable'
            })
            Write-Warning "$computer could not be queried: $($_.Exception.Message)"
        }
    }
}

end {
    $results | Sort-Object Status, DaysSincePatch -Descending
}
