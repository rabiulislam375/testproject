# D Drive Diagnostic Report - generated for recovery planning
# Run: powershell -File Inspect-D-Drive.ps1

Write-Host "=== D DRIVE STATUS REPORT ===" -ForegroundColor Cyan

Write-Host "`n[Current D: drive]"
$d = Get-Volume -DriveLetter D -EA SilentlyContinue
$part = Get-Partition -DriveLetter D -EA SilentlyContinue
$disk = if ($part) { Get-Disk -Number $part.DiskNumber } else { $null }

if ($d) {
    Write-Host "  Label:       $($d.FileSystemLabel)"
    Write-Host "  FileSystem:  $($d.FileSystem)"
    Write-Host "  Type:        $($d.DriveType)"
    Write-Host "  Size:        $([math]::Round($d.Size/1GB,2)) GB"
    Write-Host "  Free:        $([math]::Round($d.SizeRemaining/1GB,2)) GB"
}
if ($disk) {
    Write-Host "  Disk:        $($disk.FriendlyName) (Disk $($disk.Number))"
    $allocated = (Get-Partition -DiskNumber $disk.Number | Measure-Object Size -Sum).Sum
    $unalloc = $disk.Size - $allocated
    Write-Host "  Disk total:  $([math]::Round($disk.Size/1GB,2)) GB"
    Write-Host "  Unallocated: $([math]::Round($unalloc/1GB,2)) GB"
}

Write-Host "`n[Internal disk (Disk 0)]"
$disk0 = Get-Disk -Number 0
$parts0 = Get-Partition -DiskNumber 0 | Sort-Object PartitionNumber
Write-Host "  Name: $($disk0.FriendlyName)"
$parts0 | ForEach-Object {
    $letter = if ($_.DriveLetter) { $_.DriveLetter + ':' } else { '(none)' }
    Write-Host ("  Partition {0}: {1} - {2} GB - {3}" -f $_.PartitionNumber, $letter, [math]::Round($_.Size/1GB,2), $_.Type)
}
$alloc0 = ($parts0 | Measure-Object Size -Sum).Sum
$unalloc0 = $disk0.Size - $alloc0
Write-Host "  Unallocated on internal disk: $([math]::Round($unalloc0/1GB,2)) GB"

Write-Host "`n[What's on D: right now]"
Get-ChildItem D:\ -Force -EA SilentlyContinue | Select-Object Mode, Name, LastWriteTime | Format-Table -AutoSize

Write-Host @"

=== WHAT THIS MEANS ===

Your D: drive is currently a USB flash drive labeled 'ESD-USB'.
That is a Windows installation USB (created around June 6, 2026).
It is NOT a normal data drive right now.

Your internal hard drive only has C: (Windows). There is no D: partition
on the internal disk unless we create one by shrinking C:.

The USB drive shows ~218 GB unallocated space beyond the 32 GB ESD-USB
partition. That MAY be:
  - Space where your old files used to live (recoverable), OR
  - Fake capacity on a counterfeit USB drive (common with 'General UDisk')

=== RECOVERY OPTIONS ===

OPTION A - Recover deleted files from the USB (if D: was this USB):
  1. STOP using the USB immediately (don't copy files to it)
  2. Download Recuva (free): https://www.ccleaner.com/recuva
  3. Run Recuva -> choose D: -> Deep Scan
  4. For partition recovery, use TestDisk: https://www.cgsecurity.org/wiki/TestDisk

OPTION B - Create a new D: drive on your internal disk:
  1. Win + X -> Disk Management
  2. Right-click C: -> Shrink Volume (e.g. 100000 MB = 100 GB)
  3. Right-click unallocated space -> New Simple Volume -> assign D:
  WARNING: Back up important data first. Do not shrink C: if disk is nearly full.

OPTION C - Use the USB unallocated space (only if USB is genuine):
  1. Disk Management -> Disk 1 unallocated space
  2. New Simple Volume
  WARNING: If the USB is fake/counterfeit, this will fail or corrupt data.

=== IMPORTANT ===
Tell me which situation applies:
  1) I had personal files on D: and they disappeared
  2) I want a new D: partition for storage on my laptop
  3) Something else

"@ -ForegroundColor Yellow
