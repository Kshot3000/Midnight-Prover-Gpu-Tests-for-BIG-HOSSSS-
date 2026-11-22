# ============================================================================
# arm-real.ps1 — arm the REAL window (the GPU leg: D1 -> D2 -> D3 -> D4).
# Identical to arm-dry.ps1 except it launches /root/bench/launch-real.sh,
# which starts the real runner (/root/bench/window-runner.sh). Only arm this
# after a dry window has completed end-to-end and been verified.
# The agent's last action before stepping off.
# ============================================================================
$ErrorActionPreference = 'Stop'
$dir = 'C:\bench-window'
$wl = Join-Path $dir 'window.log'
function wlog($m) { "$(Get-Date -Format 'yyyy-MM-ddTHH:mm:ssK') ARM $m" | Out-File $wl -Append -Encoding utf8 }

# clear stale window state
Remove-Item (Join-Path $dir 'ARMED'), (Join-Path $dir 'DONE'), (Join-Path $dir 'RESTORED'), `
  (Join-Path $dir 'RESTORED-FAILED'), (Join-Path $dir 'SERVER-DOWN') -ErrorAction SilentlyContinue
Get-ChildItem $dir -Filter 'FAILED-*' -ErrorAction SilentlyContinue | Remove-Item -ErrorAction SilentlyContinue
wlog 'arm-real: stale window state cleared'

$rec = Get-Content (Join-Path $dir 'server-record.json') -Raw | ConvertFrom-Json
$p = Get-CimInstance Win32_Process -Filter ("ProcessId=" + $rec.WorkerPid) -ErrorAction SilentlyContinue
if (-not $p) { wlog 'ARM-ABORT: recorded worker PID not alive'; Write-Output 'ARM-ABORT: recorded worker PID gone (re-arm?) — do not step off'; exit 1 }
if ($p.CommandLine -ne $rec.Cmdline) { wlog 'ARM-ABORT: cmdline mismatch (re-arm)'; Write-Output 'ARM-ABORT: cmdline mismatch — do not step off'; exit 1 }
if ($p.ExecutablePath -ne $rec.Exe) { wlog 'ARM-ABORT: exe path mismatch'; Write-Output 'ARM-ABORT: exe path mismatch'; exit 1 }
$others = Get-CimInstance Win32_Process -Filter "Name='llama-server.exe'" |
  Where-Object { $_.ProcessId -ne $rec.WorkerPid -and $_.ProcessId -ne $rec.RouterPid }
if ($others) { wlog 'ARM-ABORT: extra llama-server present'; Write-Output 'ARM-ABORT: extra llama-server present'; exit 1 }
$free = [int](nvidia-smi --query-gpu=memory.free --format=csv,noheader,nounits)
if ($free -lt 1500) { wlog ('ARM-ABORT: only ' + $free + ' MB free (unexpected holder)'); Write-Output 'ARM-ABORT: VRAM dirty'; exit 1 }

# pre-flight: the router API must answer with the live key BEFORE ARMED is written.
. "$dir\restart-core.ps1"
try {
  $h0 = @{ Authorization = ('Bearer ' + (Get-RouterKey)) }
  $null = Invoke-RestMethod -Uri $rec.ModelsUrl -Headers $h0 -TimeoutSec 30
  wlog 'router pre-flight OK: /models answered with the live key'
} catch {
  wlog ('ARM-ABORT: router pre-flight failed: ' + $_.Exception.Message)
  Write-Output 'ARM-ABORT: router API pre-flight failed — do not step off'
  exit 1
}

# launch the WSL REAL runner through the launcher script.
Start-Process -FilePath 'wsl.exe' -ArgumentList '-d','octanode','--exec','bash','/root/bench/launch-real.sh'
wlog 'WSL real runner launch issued (via /root/bench/launch-real.sh)'

# verify the runner actually started.
Start-Sleep -Seconds 25
$rc = (Start-Process -FilePath 'wsl.exe' -ArgumentList '-d','octanode','--exec','test','-f','/root/bench/logs/window-runner.out' -Wait -PassThru -NoNewWindow).ExitCode
if ($rc -ne 0) {
  wlog 'ARM-ABORT: runner out file not created 25s after launch (runner did not start)'
  Write-Output 'ARM-ABORT: WSL runner did not start (no out file) — nothing armed; do not step off'
  exit 1
}
wlog 'WSL real runner verified started (out file created)'

wlog ('ARM REAL window armed; worker pid=' + $rec.WorkerPid + ' port=' + $rec.WorkerPort + ' router=' + $rec.RouterPid + ' model=' + $rec.ModelId + ' free_mb=' + $free)
((Get-Date).ToString('yyyy-MM-ddTHH:mm:ssK') + ' ARM REAL window; worker pid=' + $rec.WorkerPid + ' port=' + $rec.WorkerPort + ' router=' + $rec.RouterPid) |
  Out-File (Join-Path $dir 'ARMED') -Encoding utf8
wlog 'ARMED written'

# launch the finisher (detached; outlives this shell)
Start-Process -FilePath 'powershell.exe' -ArgumentList '-WindowStyle','Hidden','-NoProfile','-ExecutionPolicy','Bypass','-File',("$dir\finisher.ps1")
wlog 'finisher launch issued'

Start-Sleep -Seconds 20
$fin = Select-String -Path $wl -Pattern 'FIN finisher start' -ErrorAction SilentlyContinue | Select-Object -Last 1
if ($fin) {
  wlog 'finisher confirmed alive (log line seen)'
  Write-Output 'ARM-OK: finisher + real runner running; stepping off'
} else {
  wlog 'ARM-WARN: no finisher log line after 20s'
  Write-Output 'ARM-WARN: finisher log line not seen; verify before stepping off'
}
