"""
service_health_check.py
Checks a list of important services and reports whether
each one is running or stopped.
Based on post-patch validation work — confirming services
are healthy after a server reboot.
"""

# List of important services we want to check
services_to_check = ["Database", "WebServer", "BackupAgent"]

# Simulated current status of each service
service_status = {
    "Database": "running",
    "WebServer": "stopped",
    "BackupAgent": "running"
}

# Check each service and report its status
for service in services_to_check:
    status = service_status[service]
    if status == "running":
        print(f"{service}: OK - running")
    else:
        print(f"{service}: WARNING - {status}!")
