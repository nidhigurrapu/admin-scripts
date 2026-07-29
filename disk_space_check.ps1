# disk_space_check.ps1
# Checks free disk space on all filesystem drives and warns
# if any drive falls below the threshold.
# Based on real Windows admin work — low C-drive space was a
# common cause of failed patch installations.

$thresholdPercent = 15
$drives = Get-PSDrive -PSProvider FileSystem

foreach ($drive in $drives) {
    $free = $drive.Free
    $used = $drive.Used
    $total = $free + $used

    if ($total -gt 0) {
        $freePercent = ($free / $total) * 100
        $freeGB = [math]::Round($free / 1GB, 2)

        if ($freePercent -lt $thresholdPercent) {
            Write-Output "$($drive.Name): WARNING - Low space! $([math]::Round($freePercent,1))% free ($freeGB GB)"
        } else {
            Write-Output "$($drive.Name): OK - $([math]::Round($freePercent,1))% free ($freeGB GB)"
        }
    }
}
