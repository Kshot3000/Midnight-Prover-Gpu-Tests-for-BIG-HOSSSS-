# Rebuild C:\bench-window\server-record.json from the LIVE processes and
# the router's server.json. Identity is captured at arming time because the
# router/worker pair restarts on the hour with changing ports.
$ErrorActionPreference = 'Stop'
$dir = 'C:\bench-window'
$recFile = Join-Path $dir 'server-record.json'
$w = Get-CimInstance Win32_Process -Filter "Name='llama-server.exe'" |
  Where-Object { $_.CommandLine -match '--alias Qwen3\.8' } | Select-Object -First 1
if (-not $w) { throw 'no Qwen worker found' }
$sj = Get-Content 'C:\Users\kyleb_ypppor6\AppData\Local\hermes\runtimes\llamacpp\server.json' -Raw | ConvertFrom-Json
if ($w.ParentProcessId -ne $sj.pid) { throw ('worker parent ' + $w.ParentProcessId + ' != router ' + $sj.pid) }
$port = ([regex]::Match($w.CommandLine, '--port (\d+)')).Groups[1].Value
$obj = [ordered]@{
  RecordedAt = (Get-Date).ToString('yyyy-MM-ddTHH:mm:ssK')
  WorkerPid  = [int]$w.ProcessId
  WorkerPort = [int]$port
  WorkerPpid = [int]$w.ParentProcessId
  RouterPid  = [int]$sj.pid
  ModelId    = 'Qwen3.8-27B-UD-Q4_K_M'
  RouterBase = 'http://127.0.0.1:18434'
  ModelsUrl  = 'http://127.0.0.1:18434/models'
  LoadUrl    = 'http://127.0.0.1:18434/models/load'
  UnloadUrl  = 'http://127.0.0.1:18434/models/unload'
  ChatUrl    = 'http://127.0.0.1:18434/v1/chat/completions'
  # NOTE: the router API key is deliberately NOT recorded here; the actors
  # read it live from AppData\Local\hermes\runtimes\llamacpp\.api_key.
  Exe        = $w.ExecutablePath
  Cmdline    = $w.CommandLine
  AthenaTask = $null
}
$obj | ConvertTo-Json -Depth 5 | Out-File $recFile -Encoding utf8
'OK worker=' + $w.ProcessId + ' port=' + $port + ' router=' + $sj.pid + ' exe=' + $w.ExecutablePath
