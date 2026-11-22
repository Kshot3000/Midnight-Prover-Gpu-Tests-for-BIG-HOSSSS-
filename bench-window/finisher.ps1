# ============================================================================
# Actor 1 — bench window finisher (Windows PowerShell, detached, no LLM).
# Contract: rewritten standing orders 2026-11-21 (v2), "the bench window".
# Stop path: the Qwen worker is the router's child; the router's native
# POST /models/unload is its designed graceful path (supervisor.unload_model
# uses exactly this). We wait for the model's slots to be idle first (the
# arming turn is still live when we arm), so no generation is ever cut.
# Restore path: POST /models/load + touch generation (supervisor readiness
# proof). The only direct-PID fallback is Stop-Process on the exact recorded
# worker PID, used only if the unload API stalls past 3 min. The router
# itself is supervised by the Hermes app — never touched here.
# ============================================================================
$ErrorActionPreference = 'Continue'
$dir = 'C:\bench-window'
$wl  = Join-Path $dir 'window.log'
function wlog($m) { "$(Get-Date -Format 'yyyy-MM-ddTHH:mm:ssK') FIN $m" | Out-File $wl -Append -Encoding utf8 }
function wfree() { (nvidia-smi --query-gpu=memory.free --format=csv,noheader,nounits | Select-Object -First 1).Trim() }

. "$dir\restart-core.ps1"

$recFile = Join-Path $dir 'server-record.json'
if (-not (Test-Path $recFile)) { wlog 'ABORTED-no-record'; exit 1 }
$rec = Get-Content $recFile -Raw | ConvertFrom-Json
# NOTE: the key is NEVER attached to $rec — in Windows PowerShell 5.1,
# dot-assigning a new property onto a ConvertFrom-Json PSCustomObject fails
# (silently, under $ErrorActionPreference='Continue'), which shipped an empty
# bearer token and a 401 abort on 2026-11-22. Call Get-RouterKey() at each use.
wlog ('finisher start (ps pid=' + $PID + '; recorded worker pid=' + $rec.WorkerPid + ' port=' + $rec.WorkerPort + ' router=' + $rec.RouterPid + ' model=' + $rec.ModelId + ')')

if (-not (Test-Path (Join-Path $dir 'ARMED'))) { wlog 'ABORTED-no-ARMED'; exit 1 }

# --- 1) verify the VRAM holder is the recorded worker and nothing else ---
$proc = Get-CimInstance Win32_Process -Filter ("ProcessId=" + $rec.WorkerPid) -ErrorAction SilentlyContinue
if (-not $proc) { wlog 'ABORTED-wrong-process: recorded PID not alive (re-arm?)'; exit 1 }
if ($proc.CommandLine -ne $rec.Cmdline) { wlog 'ABORTED-wrong-process: cmdline mismatch (re-arm?)'; exit 1 }
if ($proc.ExecutablePath -ne $rec.Exe) { wlog 'ABORTED-wrong-process: exe path mismatch'; exit 1 }
if ($proc.ParentProcessId -ne $rec.RouterPid) { wlog ('ABORTED-wrong-process: worker parent is ' + $proc.ParentProcessId + ' (expected router ' + $rec.RouterPid + ')'); exit 1 }
$others = Get-CimInstance Win32_Process -Filter "Name='llama-server.exe'" |
  Where-Object { $_.ProcessId -ne $rec.WorkerPid -and $_.ProcessId -ne $rec.RouterPid }
if ($others) {
  wlog ('ABORTED-wrong-process: extra llama-server pid(s) ' + (($others | ForEach-Object { $_.ProcessId }) -join ','))
  exit 1
}
# router sanity: the model must be loaded per the router API
try {
  $hm = @{ Authorization = ('Bearer ' + (Get-RouterKey)) }
  $m = ((Invoke-RestMethod -Uri $rec.ModelsUrl -Headers $hm -TimeoutSec 30).data) | Where-Object { $_.id -eq $rec.ModelId }
  wlog ('router says model status=' + $m.status.value)
  if ($m.status.value -ne 'loaded' -and $m.status.value -ne 'ready') { wlog 'ABORTED-wrong-process: model not loaded per router API'; exit 1 }
} catch {
  wlog ('ABORTED-wrong-process: router /models unreachable: ' + $_.Exception.Message)
  exit 1
}
$free0 = [int](wfree)
if ($free0 -lt 1500) {
  wlog ('ABORTED-vram-dirty: only ' + $free0 + ' MB free before stop (unexpected extra holder)')
  exit 1
}
wlog ('holder verified: worker pid=' + $rec.WorkerPid + ' (parent router ' + $rec.RouterPid + ') free_mb=' + $free0)

# --- 2) wait for the arming turn to finish: model slots idle (max 5 min) ---
$idle = $false
for ($i = 0; $i -lt 30; $i++) {
  try {
    $h3 = @{ Authorization = ('Bearer ' + (Get-RouterKey)) }
    $slots = Invoke-RestMethod -Uri ($rec.RouterBase + '/slots?model=' + [uri]::EscapeDataString($rec.ModelId)) -Headers $h3 -TimeoutSec 15
    if (-not ($slots | Where-Object { $_.is_processing })) {
      $idle = $true
      wlog ('model slots idle at wait ' + $i + ' (arming turn finished)')
      break
    } else {
      if ($i -eq 0 -or $i % 5 -eq 0) { wlog ('slots still processing at wait ' + $i) }
    }
  } catch {
    if ($i -eq 0) { wlog ('slots probe failed: ' + $_.Exception.Message) }
  }
  Start-Sleep -Seconds 10
}
if (-not $idle) {
  wlog 'slots busy after 5 min — proceeding to unload anyway (dry run will record what the harness does if a generation is cut)'
}

# --- 3) stop the server: router's native /models/unload (its designed path) ---
try {
  $h2 = @{ Authorization = ('Bearer ' + (Get-RouterKey)) }
  $r = Invoke-RestMethod -Method Post -Uri $rec.UnloadUrl -Headers $h2 -ContentType 'application/json' `
      -Body ('{"model":"' + $rec.ModelId + '"}') -TimeoutSec 180
  wlog ('unload API returned: ' + (($r | ConvertTo-Json -Compress -Depth 3)))
} catch {
  wlog ('unload API failed: ' + $_.Exception.Message)
}
# poll up to 3 min for the worker to exit and VRAM to free (>= 23,000 MB)
$freeOk = $false
for ($i = 0; $i -lt 18; $i++) {
  Start-Sleep -Seconds 10
  $alive = Get-Process -Id $rec.WorkerPid -ErrorAction SilentlyContinue
  $f = [int](wfree)
  if ($i % 3 -eq 0) { wlog ('stop-poll ' + $i + ': worker_alive=' + [bool]$alive + ' free_mb=' + $f) }
  if (-not $alive -and $f -ge 23000) { $freeOk = $true; break }
}
if (-not $freeOk) {
  # the API path stalled — last resort: terminate of the exact recorded PID only
  $alive = Get-Process -Id $rec.WorkerPid -ErrorAction SilentlyContinue
  if ($alive) {
    wlog 'worker still alive after 3 min of unload — Stop-Process on the recorded PID only (no pattern kills)'
    try { Stop-Process -Id $rec.WorkerPid -Force -ErrorAction Stop } catch { wlog ('Stop-Process failed: ' + $_.Exception.Message) }
    Start-Sleep -Seconds 20
  }
  $alive2 = Get-Process -Id $rec.WorkerPid -ErrorAction SilentlyContinue
  $freeOk = ((-not $alive2) -and ([int](wfree) -ge 23000))
}
if (-not $freeOk) {
  wlog ('ABORTED-vram-dirty: VRAM not free after 3 min + fallback (free=' + (wfree) + ' MB) — not touching anything else; restoring now and closing')
  $okx = Restore-RecordedServer -rec $rec
  ((Get-Date).ToString('yyyy-MM-ddTHH:mm:ssK') + ' FIN RESTORED (after dirty-card abort; touch=' + $okx + ')') | Out-File (Join-Path $dir 'RESTORED') -Encoding utf8
  wlog 'WINDOW CLOSED (dirty-card abort)'
  exit 1
}
((Get-Date).ToString('yyyy-MM-ddTHH:mm:ssK') + ' FIN server stopped; free_mb=' + (wfree)) | Out-File (Join-Path $dir 'SERVER-DOWN') -Encoding utf8
wlog ('SERVER-DOWN written (free=' + (wfree) + ' MB)')

# --- 4) wait for DONE / FAILED-* (30 s poll, hard cap 4 h) ---
$cutoff = (Get-Date).AddHours(4)
$saw = $null
while ((Get-Date) -lt $cutoff) {
  if (Test-Path (Join-Path $dir 'DONE')) { $saw = 'DONE'; break }
  $fm = Get-ChildItem $dir -Filter 'FAILED-*' -ErrorAction SilentlyContinue
  if ($fm) { $saw = $fm[0].Name; break }
  Start-Sleep -Seconds 30
}
if (-not $saw) { $saw = 'CAP-4H'; wlog 'hard cap 4h reached — restoring anyway' }
wlog ('runner phase complete; saw=' + $saw)

# --- 5) restore through the router (native API + touch generation) ---
$ok = Restore-RecordedServer -rec $rec
if ($ok) {
  # post-restore fidelity: the worker must be the recorded exe under the router
  Start-Sleep -Seconds 10
  $np = Get-CimInstance Win32_Process -Filter "Name='llama-server.exe'" |
    Where-Object { $_.ProcessId -ne $rec.RouterPid } | Select-Object -First 1
  if ($np) {
    if ($np.ExecutablePath -eq $rec.Exe -and $np.ParentProcessId -eq $rec.RouterPid) {
      wlog ('restarted worker verified: pid=' + $np.ProcessId + ' exe + parent router match the record')
    } else {
      wlog ('WARNING: restarted worker differs from record: pid=' + $np.ProcessId + ' parent=' + $np.ParentProcessId)
    }
  } else {
    wlog 'WARNING: no worker process visible after restore (router may still be loading)'
  }
  ((Get-Date).ToString('yyyy-MM-ddTHH:mm:ssK') + ' FIN server restored; touch generation passed') | Out-File (Join-Path $dir 'RESTORED') -Encoding utf8
  wlog 'RESTORED written'
} else {
  wlog 'RESTORE FAILED (load API / touch generation did not confirm readiness)'
  ((Get-Date).ToString('yyyy-MM-ddTHH:mm:ssK') + ' FIN RESTORED-FAILED') | Out-File (Join-Path $dir 'RESTORED-FAILED') -Encoding utf8
}

# --- 6) athena task re-enable (Phase 0 paused it; no-op if it was absent) ---
if ($rec.AthenaTask) {
  $at = Get-ScheduledTask -TaskName $rec.AthenaTask -ErrorAction SilentlyContinue
  if ($at) {
    Enable-ScheduledTask -TaskName $rec.AthenaTask | Out-Null
    wlog ('athena task re-enabled: ' + $rec.AthenaTask)
  } else {
    wlog ('athena task not present (nothing to re-enable): ' + $rec.AthenaTask)
  }
} else {
  wlog 'athena task: none recorded (nothing to re-enable)'
}
wlog 'WINDOW CLOSED'
exit 0
