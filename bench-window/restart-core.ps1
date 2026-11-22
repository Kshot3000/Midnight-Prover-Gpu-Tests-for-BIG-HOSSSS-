# ============================================================================
# restart-core.ps1 — restore the Qwen worker through the ROUTER's native
# model API (POST /models/load), then prove readiness the way the supervisor
# does (touch generation: temp-0, expected token). The router and its worker
# are supervised by the Hermes app; this core never spawns or kills
# llama-server processes — it only asks the router for its designed behavior.
# The router API key is read live from Hermes' canonical store (never kept
# in the record file).
# Contract: rewritten standing orders 2026-11-21 (v2), Phase 0 step 1.
# ============================================================================
$ROUTER_KEY_PATH = 'C:\Users\kyleb_ypppor6\AppData\Local\hermes\runtimes\llamacpp\.api_key'
function Get-RouterKey {
    (Get-Content $ROUTER_KEY_PATH -Raw).Trim()
}

function Invoke-RouterTouch {
    param($rec)
    # Same readiness proof the Hermes supervisor uses (supervisor.py touch_generate).
    $body = '{"model":"' + $rec.ModelId + '","messages":[{"role":"user","content":"Reply with exactly one word: the capital of France."}],"max_tokens":512,"temperature":0}'
    try {
        $resp = Invoke-RestMethod -Method Post -Uri $rec.ChatUrl -Headers @{ Authorization = ('Bearer ' + (Get-RouterKey)) } `
            -ContentType 'application/json' -Body $body -TimeoutSec 300
        $msg = $resp.choices[0].message
        $blob = (([string]$msg.content) + ' ' + ([string]$msg.reasoning_content)).ToLower()
        return ($blob -like '*paris*')
    } catch {
        Write-Host ('Invoke-RouterTouch failed: ' + $_.Exception.Message)
        return $false
    }
}

function Restore-RecordedServer {
    param($rec)
    # 1) reload the model through the router (synchronous; a 27B load is slow)
    $h = @{ Authorization = ('Bearer ' + (Get-RouterKey)) }
    $status = 'unknown'
    try {
        $models = (Invoke-RestMethod -Uri $rec.ModelsUrl -Headers $h -TimeoutSec 30).data
        $m = $models | Where-Object { $_.id -eq $rec.ModelId }
        if ($m) { $status = $m.status.value }
        Write-Host ('Restore-RecordedServer: pre-load status=' + $status)
        if ($status -ne 'loaded' -and $status -ne 'ready' -and $status -ne 'loading') {
            $null = Invoke-RestMethod -Method Post -Uri $rec.LoadUrl -Headers $h `
                -ContentType 'application/json' -Body ('{"model":"' + $rec.ModelId + '"}') -TimeoutSec 900
            Write-Host 'Restore-RecordedServer: /models/load call returned'
        }
    } catch {
        Write-Host ('Restore-RecordedServer: load path failed: ' + $_.Exception.Message)
    }
    # 2) prove readiness with a touch generation
    $ok = Invoke-RouterTouch -rec $rec
    Write-Host ('Restore-RecordedServer: touch generation ok=' + $ok)
    return [bool]$ok
}
