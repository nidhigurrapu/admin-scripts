# admin-scripts

Windows administration and automation scripts, based on real-world
infrastructure operations work — server patching, health checks, and
system monitoring.

## About

I maintain these scripts as part of building automation skills for
Windows Server administration. Each one addresses a task I performed
manually while supporting enterprise server environments.

## Scripts

### `disk_space_check.py` / `disk_space_check.ps1`
Checks disk usage across drives and flags any drive falling below a
free-space threshold (default 15%).

**Why:** Low disk space particularly on the C: drive is a common
cause of failed patch installations and server issues. Checking this
proactively prevents failures during maintenance windows.

**Run:**
```
python disk_space_check.py
```
## PowerShell server checks
Four read-only checks for a Windows Server estate, written from the work I did at
Kyndryl supporting around 2,500 servers for two enterprise client accounts.

| Script | What it does |
| --- | --- |
| `Get-DiskSpaceReport.ps1` | Free space on every fixed disk across a server list, lowest first, with a configurable Low threshold. |
| `Test-ServiceHealth.ps1` | Checks a defined set of services is running. `-FailedOnly` returns just what needs acting on. |
| `Get-PatchStatus.ps1` | Last installed hotfix, days since, and whether a reboot is outstanding. For triaging a maintenance window. |
| `Get-SystemEventErrors.ps1` | Errors and critical events from System and Application logs. `-GroupByProvider` surfaces the one fault that fired two hundred times. |

Only `Test-ServiceHealth.ps1` can change anything, it needs an explicit `-Restart`
switch, and it confirms each service individually. Restarting a service on a
production server belongs in an approved change window, not a reporting script.

Every script catches per-machine failures and records the unreachable server in
its output rather than stopping the run, and each has full comment-based help:
`Get-Help .\Get-PatchStatus.ps1 -Full`.
