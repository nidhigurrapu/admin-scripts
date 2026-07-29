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

**Why:** Low disk space — particularly on the C: drive — is a common
cause of failed patch installations and server issues. Checking this
proactively prevents failures during maintenance windows.

**Run:**
```
python disk_space_check.py
```
