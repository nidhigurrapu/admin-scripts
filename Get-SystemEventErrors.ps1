<#
.SYNOPSIS
    Collects recent error and critical events from the System and Application logs
    across one or more servers.

.DESCRIPTION
    The first thing I did on a server that came back unreachable or misbehaving after
    a change was read its event logs. This does that across a list of machines at once
    and groups the output so a repeating fault is obvious rather than buried.

    Read only.

.PARAMETER ComputerName
    One or more server names.

.PARAMETER Hours
    How far back to look. Default 24.

.PARAMETER LogName
    Which logs to read. Default System and Application.

.PARAMETER GroupByProvider
    Summarise by source and event ID with a count, instead of listing every entry.
    Useful for spotting the one fault that fired two hundred times.

.EXAMPLE
    .\Get-SystemEventErrors.ps1 -ComputerName SRV01 -Hours 48

.EXAMPLE
    .\Get-SystemEventErrors.ps1 -ComputerName (Get-Content .\servers.txt) -GroupByProvider
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory, ValueFromPipeline)]
    [string[]]$ComputerName,

    [int]$Hours = 24,

    [string[]]$LogName = @('System', 'Application'),

    [switch]$GroupByProvider
)

begin {
    $since   = (Get-Date).AddHours(-$Hours)
    $results = [System.Collections.Generic.List[object]]::new()
}

process {
    foreach ($computer in $ComputerName) {
        foreach ($log in $LogName) {

            try {
                # Level 1 is Critical, Level 2 is Error. Warnings are deliberately excluded
                # because they are too noisy to be useful in a shift handover.
                $events = Get-WinEvent -ComputerName $computer -ErrorAction Stop -FilterHashtable @{
                    LogName   = $log
                    Level     = 1, 2
                    StartTime = $since
                }
            }
            catch [Exception] {
                # "No events were found" is a normal, good result, not a failure.
                if ($_.Exception.Message -match 'No events were found') {
                    Write-Verbose "$computer / $log : no errors in the last $Hours hours"
                    continue
                }
                Write-Warning "$computer / $log : $($_.Exception.Message)"
                continue
            }

            foreach ($event in $events) {
                $results.Add([pscustomobject]@{
                    ComputerName = $computer
                    Log          = $log
                    TimeCreated  = $event.TimeCreated
                    Level        = $event.LevelDisplayName
                    Provider     = $event.ProviderName
                    EventID      = $event.Id
                    Message      = ($event.Message -split "`r?`n")[0]
                })
            }
        }
    }
}

end {
    if ($GroupByProvider) {
        $results |
            Group-Object ComputerName, Provider, EventID |
            Sort-Object Count -Descending |
            Select-Object  @{N='ComputerName'; E={$_.Group[0].ComputerName}},
                           @{N='Provider';     E={$_.Group[0].Provider}},
                           @{N='EventID';      E={$_.Group[0].EventID}},
                           Count,
                           @{N='FirstSeen';    E={($_.Group | Sort-Object TimeCreated | Select-Object -First 1).TimeCreated}},
                           @{N='LastSeen';     E={($_.Group | Sort-Object TimeCreated | Select-Object -Last  1).TimeCreated}},
                           @{N='Message';      E={$_.Group[0].Message}}
    }
    else {
        $results | Sort-Object TimeCreated -Descending
    }
}
