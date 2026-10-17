# Run as Administrator: Right-click -> Run with PowerShell (Admin)
# Fixes common Dell/Cirrus/Waves audio issues on Windows

$ErrorActionPreference = 'Continue'
Write-Host "=== Audio Fix Script ===" -ForegroundColor Cyan

# 1. Restart Windows Audio stack
Write-Host "`n[1/6] Restarting Windows Audio services..."
$audioServices = @('Audiosrv', 'AudioEndpointBuilder')
foreach ($svc in $audioServices) {
    Restart-Service $svc -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 1
    $s = Get-Service $svc
    Write-Host "  $svc : $($s.Status)"
}

# 2. Restart Dell/Waves/Intel audio services
Write-Host "`n[2/6] Restarting Waves and Intel audio services..."
$extra = @('WavesAudioService', 'WavesSysSvc', 'IntelAudioService')
foreach ($svc in $extra) {
    Restart-Service $svc -Force -ErrorAction SilentlyContinue
    Write-Host "  $svc restarted"
}

# 3. Reset speakers PnP device
Write-Host "`n[3/6] Resetting Speakers device..."
$speaker = Get-PnpDevice -Class AudioEndpoint -ErrorAction SilentlyContinue |
    Where-Object { $_.FriendlyName -like 'Speakers*' } | Select-Object -First 1
if ($speaker) {
    Disable-PnpDevice -InstanceId $speaker.InstanceId -Confirm:$false -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
    Enable-PnpDevice -InstanceId $speaker.InstanceId -Confirm:$false -ErrorAction SilentlyContinue
    Write-Host "  Reset: $($speaker.FriendlyName)"
} else {
    Write-Host "  Speakers device not found - skip"
}

# 4. Set master volume to 100% (waveOut)
Write-Host "`n[4/6] Setting master volume to 100%..."
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class WinMM {
    [DllImport("winmm.dll")]
    public static extern int waveOutSetVolume(IntPtr hwo, uint dwVolume);
}
"@
$max = [uint32]0xFFFF
$newVol = ($max -shl 16) -bor $max
[void][WinMM]::waveOutSetVolume([IntPtr]::Zero, $newVol)
Write-Host "  Master volume set to 100%"

# 5. Play test sound
Write-Host "`n[5/6] Playing test sound..."
$wav = "$env:SystemRoot\Media\Windows Notify System Generic.wav"
if (Test-Path $wav) {
    $player = New-Object System.Media.SoundPlayer $wav
    $player.PlaySync()
    Write-Host "  If you heard a chime, audio is working."
} else {
    [console]::beep(880, 400)
    Write-Host "  Beep sent (may not use speakers on all systems)."
}

# 6. Open Sound settings for manual checks
Write-Host "`n[6/6] Opening Sound settings..."
Start-Process "ms-settings:sound"
Start-Process "sndvol.exe"

Write-Host "`n=== Manual checks in the windows that opened ===" -ForegroundColor Yellow
Write-Host "  - Output device: choose 'Speakers (Cirrus Logic High Definition Audio)'"
Write-Host "  - Volume: not 0, speaker icon not muted"
Write-Host "  - Volume mixer: no app muted at 0%"
Write-Host "  - If using headphones/Bluetooth: plug in or connect, or switch back to Speakers"
Write-Host "`nIf still no sound, run Windows troubleshooter:"
Write-Host "  Settings > System > Sound > Troubleshoot"
Write-Host "Or run: msdt.exe /id AudioPlaybackDiagnostic"
Write-Host "`nDone. Press Enter to exit."
Read-Host
