# Fix app audio when system test sounds work (Dell + Cirrus + Waves)
# RIGHT-CLICK -> Run with PowerShell as Administrator

$ErrorActionPreference = 'Continue'
Write-Host "=== Dell/Waves App Audio Fix ===" -ForegroundColor Cyan

function Test-Admin {
    ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}
if (-not (Test-Admin)) {
    Write-Host "ERROR: Run this script as Administrator." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# 1. Stop Waves (often blocks app audio while legacy sounds still work)
Write-Host "`n[1] Stopping Waves services..."
foreach ($s in @('WavesAudioService', 'WavesSysSvc')) {
    Stop-Service $s -Force -ErrorAction SilentlyContinue
    Set-Service $s -StartupType Disabled -ErrorAction SilentlyContinue
    Write-Host "  Stopped and disabled startup: $s"
}

# 2. Disable Waves APO processing component
Write-Host "`n[2] Disabling Waves Audio Effects Component..."
$waves = Get-PnpDevice | Where-Object { $_.InstanceId -match 'WAVESAPO' }
if ($waves) {
    Disable-PnpDevice -InstanceId $waves.InstanceId -Confirm:$false -ErrorAction SilentlyContinue
    Write-Host "  Disabled: $($waves.FriendlyName)"
} else {
    Write-Host "  Waves APO not found (may already be disabled)"
}

# 3. Restart audio stack
Write-Host "`n[3] Restarting Windows Audio..."
foreach ($s in @('Audiosrv', 'AudioEndpointBuilder')) {
    Restart-Service $s -Force -ErrorAction SilentlyContinue
}
Start-Sleep -Seconds 3

# 4. Reset speakers device
Write-Host "`n[4] Resetting Speakers endpoint..."
$spk = Get-PnpDevice -Class AudioEndpoint | Where-Object { $_.FriendlyName -like 'Speakers*' } | Select-Object -First 1
if ($spk) {
    Disable-PnpDevice -InstanceId $spk.InstanceId -Confirm:$false -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
    Enable-PnpDevice -InstanceId $spk.InstanceId -Confirm:$false -ErrorAction SilentlyContinue
    Write-Host "  Reset: $($spk.FriendlyName)"
}

# 5. Communications ducking off
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Multimedia\Audio" -Name "UserDuckingPreference" -Value 3 -Type DWord -Force -EA SilentlyContinue
Write-Host "`n[5] Disabled Windows communications volume ducking"

# 6. Open panels for manual steps (required on Dell)
Write-Host "`n[6] Opening Sound control panels..."
Start-Process "mmsys.cpl"
Start-Sleep -Seconds 1
Start-Process "sndvol.exe"
Start-Process "ms-settings:sound"

Write-Host @"

=== DO THESE IN THE WINDOWS THAT OPENED ===

A) mmsys.cpl (classic Sound):
   - Playback tab -> double-click 'Speakers (Cirrus Logic...)'
   - Levels: 100%, not muted
   - Advanced: Default Format = '16 bit, 48000 Hz' -> Apply
   - Advanced: UNCHECK both 'Exclusive Mode' boxes -> Apply
   - Enhancements tab: CHECK 'Disable all enhancements' -> Apply
   - Set Speakers as Default Device

B) Volume mixer (sndvol):
   - Device: Speakers
   - Every app slider at 100%, none muted

C) Settings > Sound:
   - Output = Speakers (Cirrus Logic...)
   - Turn OFF Spatial sound (Off)

=== THEN TEST ===
Open YouTube in browser and play a video.

If audio works now, Waves was the cause. You can re-enable Waves later from:
  Services.msc -> Waves Audio Services -> Manual
  Device Manager -> Software components -> Waves Audio Effects -> Enable

"@ -ForegroundColor Yellow

Write-Host "Playing test sound..."
$wav = "$env:SystemRoot\Media\Windows Notify System Generic.wav"
(New-Object System.Media.SoundPlayer $wav).PlaySync()
Read-Host "`nPress Enter to exit"
