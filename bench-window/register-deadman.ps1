# ============================================================================
# register-deadman.ps1 — register the dead-man's switch ONCE (left forever).
# ============================================================================
$ErrorActionPreference = 'Stop'
$taskName = 'MidnightBenchWindowDeadman'
if (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue) {
  'already registered'
  exit 0
}
$action = New-ScheduledTaskAction -Execute 'powershell.exe' `
  -Argument '-WindowStyle Hidden -NoProfile -ExecutionPolicy Bypass -File C:\bench-window\deadman.ps1'
$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(1) `
  -RepetitionInterval (New-TimeSpan -Minutes 15) `
  -RepetitionDuration (New-TimeSpan -Days 3650)
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries `
  -DontStopIfGoingOnBatteries -StartWhenAvailable `
  -ExecutionTimeLimit (New-TimeSpan -Minutes 10)
Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger `
  -Settings $settings `
  -Description 'Midnight GPU prover bench window dead-man switch; no-op unless a window is armed (C:\bench-window)' | Out-String
