"""
disk_space_check.py
Checks disk usage on the system and flags any drive
running low on free space (below a set threshold).
Inspired by real Windows server admin work — low C-drive
space was a common cause of failed patches.
"""

import shutil

# Alert if free space drops below this percentage
THRESHOLD_PERCENT = 15

def check_disk_space(path="/"):
    total, used, free = shutil.disk_usage(path)
    free_percent = (free / total) * 100

    print(f"Drive: {path}")
    print(f"Total: {total // (2**30)} GB")
    print(f"Used:  {used // (2**30)} GB")
    print(f"Free:  {free // (2**30)} GB ({free_percent:.1f}%)")

    if free_percent < THRESHOLD_PERCENT:
        print(f"WARNING: Low disk space! Below {THRESHOLD_PERCENT}% free.")
    else:
        print("Disk space OK.")

if __name__ == "__main__":
    check_disk_space("/")
