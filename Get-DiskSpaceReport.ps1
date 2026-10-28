<#
.SYNOPSIS
    Reports free disk space across a list of Windows servers and flags any volume
    below a threshold.

.DESCRIPTION
    Replaces a manual check I used to run by hand each shift. Reads a list of
    server names, queries logical disks on each, and returns a single table
    sorted so the lowest free space appears first.

    Read only. Nothing is changed on any target machine.

.PARAMETER ComputerName
    One or more server names. Accepts pipeline input.

.PARAMETER ThresholdPercent
    Volumes at or below this percentage free are marked as Low. Default 15.

.EXAMPLE
    .\Get-DiskSpaceReport.ps1 -ComputerName (Get-Content .\servers.txt)

.EXAMPLE
    .\Get-DiskSpaceReport.ps1 -ComputerName SRV01,SRV02 -ThresholdPercent 10 |
        Where-Object Status -eq 'Low'

.NOTES
    Requires permission to query WMI or CIM on the target machines.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory, ValueFromPipeline)]
    [string[]]$ComputerName,

    [ValidateRange(1, 99)]
    [int]$ThresholdPercent = 15
)

begin {
    $results = [System.Collections.Generic.List[object]]::new()
}

process {
    foreach ($computer in $ComputerName) {

        try {
            # DriveType 3 is a local fixed disk. Excludes CD drives and network shares.
            $disks = Get-CimInstance -ClassName Win32_LogicalDisk `
                                     -Filter 'DriveType = 3' `
                                     -ComputerName $computer `
                                     -ErrorAction Stop
        }
        catch {
            # Record the failure rather than stopping the whole run. A server being
            # unreachable is itself a finding worth reporting.
            $results.Add([pscustomobject]@{
                ComputerName = $computer
                Drive        = 'n/a'
                SizeGB       = $null
                FreeGB       = $null
                PercentFree  = $null
                Status       = 'Unreachable'
                Detail       = $_.Exception.Message
            })
            Write-Warning "$computer could not be queried: $($_.Exception.Message)"
            continue
        }

        foreach ($disk in $disks) {

            # Guard against a reported size of zero, which would divide by zero below.
            if (-not $disk.Size) { continue }

            $percentFree = [math]::Round(($disk.FreeSpace / $disk.Size) * 100, 1)

            $results.Add([pscustomobject]@{
                ComputerName = $computer
                Drive        = $disk.DeviceID
                SizeGB       = [math]::Round($disk.Size / 1GB, 1)
                FreeGB       = [math]::Round($disk.FreeSpace / 1GB, 1)
                PercentFree  = $percentFree
                Status       = if ($percentFree -le $ThresholdPercent) { 'Low' } else { 'OK' }
                Detail       = ''
            })
        }
    }
}

end {
    # Lowest free space first, so anything needing attention is at the top.
    $results | Sort-Object PercentFree
}
