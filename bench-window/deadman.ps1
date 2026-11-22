# ============================================================================
# Actor 3 — dead-man's switch (Windows Scheduled Task, every 15 min).
# One check only: if ARMED exists, RESTORED doesn't, and > 4h15m since
# SERVER-DOWN -> restore the server via the router's native API, log
# DEADMAN RESTORE. If the router itself is gone, log DEADMAN-ROUTER-DEAD
# (the Hermes app supervises the router; this actor never spawns servers).
# Registered once, left forever; no-op when no window is armed.
# Contract: rewritten standing orders 2026-11-21 (v2).
# ============================================================================
$ErrorActionPreference = 'Continue'
$dir = 'C:\bench-window'
$wl  = Join-Path $dir 'window.log'
function wlog($m) { "$(Get-Date -Format 'yyyy-MM-ddTHH:mm:ssK') DM  $m" | Out-File $wl -Append -Encoding utf8 }

if (-not (Test-Path (Join-Path $dir 'ARMED'))) { exit 0 }
if (Test-Path (Join-Path $dir 'RESTORED')) { exit 0 }
$sd = Join-Path $dir 'SERVER-DOWN'
$need = $false
if (Test-Path $sd) {
  $age = (Get-Date) - (Get-Item $sd).LastWriteTime
  if ($age -gt ([TimeSpan]::FromHours(4) + [TimeSpan]::FromMinutes(15))) { $need = $true }
}
if (-not $need) { exit 0 }

. "$dir\restart-core.ps1"
$rec = Get-Content (Join-Path $dir 'server-record.json') -Raw | ConvertFrom-Json
$rec.RouterKey = (Get-RouterKey)
if (-not (Get-Process -Id $rec.RouterPid -ErrorAction SilentlyContinue)) {
  wlog 'DEADMAN-ROUTER-DEAD: router pid missing; the Hermes app supervises the router - not spawning anything'
  exit 0
}
wlog 'DEADMAN RESTORE: window down > 4h15m - restoring through the router API'
$ok = Restore-RecordedServer -rec $rec
if ($ok) {
  wlog 'DEADMAN RESTORE: touch generation passed'
  ((Get-Date).ToString('yyyy-MM-ddTHH:mm:ssK') + ' DM RESTORED (dead-man)') | Out-File (Join-Path $dir 'RESTORED') -Encoding utf8
} else {
  wlog 'DEADMAN RESTORE FAILED: load API / touch generation did not confirm readiness; retrying next tick'
}
exit 0
