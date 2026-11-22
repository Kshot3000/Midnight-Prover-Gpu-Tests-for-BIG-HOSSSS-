# ============================================================================
# arm-dry.ps1 — arm the DRY window (the agent's last action before stepping
# off). Verifies the holder against the record, writes ARMED, launches the
# WSL dry runner (60s no-op) and the finisher — both detached — then
# confirms the finisher is alive. Re-runnable: if a stale ARMED from a dead
# window is present, it is cleared first (verified against the record).
# ============================================================================
$ErrorActionPreference = 'Stop'
$dir = 'C:\bench-window'
$wl = Join-Path $dir 'window.log'
function wlog($m) { "$(Get-Date -Format 'yyyy-MM-ddTHH:mm:ssK') ARM $m" | Out-File $wl -Append -Encoding utf8 }

# clear stale window state (only ever ours; the real window re-arms after this)
Remove-Item (Join-Path $dir 'ARMED'), (Join-Path $dir 'DONE'), (Join-Path $dir 'RESTORED'), `
  (Join-Path $dir 'RESTORED-FAILED'), (Join-Path $dir 'SERVER-DOWN') -ErrorAction SilentlyContinue
Get-ChildItem $dir -Filter 'FAILED-*' -ErrorAction SilentlyContinue | Remove-Item -ErrorAction SilentlyContinue
wlog 'arm-dry: stale window state cleared'

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

# pre-flight: the router API must answer with the live key BEFORE ARMED is
# written. Dry-window attempt 1 (2026-11-22) failed on a 401 after the agent
# had stepped off — fail while the agent is still in the turn instead.
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

wlog ('ARM dry window armed; worker pid=' + $rec.WorkerPid + ' port=' + $rec.WorkerPort + ' router=' + $rec.RouterPid + ' model=' + $rec.ModelId + ' free_mb=' + $free)
((Get-Date).ToString('yyyy-MM-ddTHH:mm:ssK') + ' ARM dry window; worker pid=' + $rec.WorkerPid + ' port=' + $rec.WorkerPort + ' router=' + $rec.RouterPid) |
  Out-File (Join-Path $dir 'ARMED') -Encoding utf8
wlog 'ARMED written'

# launch the WSL dry runner (detached; survives this shell)
Start-Process -FilePath 'wsl.exe' -ArgumentList '-d','octanode','--exec','bash','-lc','setsid nohup /root/bench/window-runner-dry.sh > /root/bench/logs/window-runner-dry.out 2>&1 < /dev/null &'
wlog 'WSL dry runner launch issued'

# launch the finisher (detached; outlives this shell)
Start-Process -FilePath 'powershell.exe' -ArgumentList '-WindowStyle','Hidden','-NoProfile','-ExecutionPolicy','Bypass','-File',("$dir\finisher.ps1")
wlog 'finisher launch issued'

Start-Sleep -Seconds 20
$fin = Select-String -Path $wl -Pattern 'FIN finisher start' -ErrorAction SilentlyContinue | Select-Object -Last 1
if ($fin) {
  wlog 'finisher confirmed alive (log line seen)'
  Write-Output 'ARM-OK: finisher + dry runner running; stepping off'
} else {
  wlog 'ARM-WARN: no finisher log line after 20s'
  Write-Output 'ARM-WARN: finisher log line not seen; verify before stepping off'
}
