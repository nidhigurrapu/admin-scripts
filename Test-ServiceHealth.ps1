<#
.SYNOPSIS
    Checks that a defined set of Windows services is running on one or more servers.

.DESCRIPTION
    This is the scheduled daily health check written down. Instead of opening
    services.msc on each box, it takes a server list and a service list and returns
    only what you need to act on.

    Read only by default. The -Restart switch is available but asks for confirmation
    on every service, because restarting a service on a production server belongs
    inside an approved change window, not in a reporting script.

.PARAMETER ComputerName
    One or more server names.

.PARAMETER ServiceName
    Service names to check. Defaults to a small set of common ones.

.PARAMETER FailedOnly
    Return only services that are not running. Useful for a shift handover note.

.EXAMPLE
    .\Test-ServiceHealth.ps1 -ComputerName SRV01,SRV02 -FailedOnly

.EXAMPLE
    .\Test-ServiceHealth.ps1 -ComputerName (Get-Content .\servers.txt) `
                             -ServiceName W32Time,Spooler,WinRM
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory, ValueFromPipeline)]
    [string[]]$ComputerName,

    [string[]]$ServiceName = @('W32Time', 'WinRM', 'EventLog'),

    [switch]$FailedOnly,

    [switch]$Restart
)

begin {
    $results = [System.Collections.Generic.List[object]]::new()
}

process {
    foreach ($computer in $ComputerName) {
        foreach ($service in $ServiceName) {

            try {
                $svc = Get-Service -Name $service -ComputerName $computer -ErrorAction Stop

                $results.Add([pscustomobject]@{
                    ComputerName = $computer
                    Service      = $svc.Name
                    DisplayName  = $svc.DisplayName
                    State        = $svc.Status
                    StartType    = $svc.StartType
                    Healthy      = ($svc.Status -eq 'Running')
                })

                # Only act if explicitly asked, and only on something actually stopped.
                if ($Restart -and $svc.Status -ne 'Running') {
                    if ($PSCmdlet.ShouldProcess("$computer\$service", 'Start service')) {
                        Start-Service -InputObject $svc -ErrorAction Stop
                        Write-Verbose "Started $service on $computer"
                    }
                }
            }
            catch {
                $results.Add([pscustomobject]@{
                    ComputerName = $computer
                    Service      = $service
                    DisplayName  = 'n/a'
                    State        = 'NotFound or Unreachable'
                    StartType    = 'n/a'
                    Healthy      = $false
                })
                Write-Warning "$computer / $service : $($_.Exception.Message)"
            }
        }
    }
}

end {
    if ($FailedOnly) {
        $results | Where-Object { -not $_.Healthy }
    }
    else {
        $results
    }
}
