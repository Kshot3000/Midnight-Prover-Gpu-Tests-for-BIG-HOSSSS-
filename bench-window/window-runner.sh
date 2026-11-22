#!/usr/bin/env bash
# ============================================================================
# Actor 2 — bench window WSL runner (REAL). Contract: rewritten standing
# orders 2026-11-21 (v2). Waits for SERVER-DOWN, then runs the staged
# device-phase stages in order D1 -> D2 -> D3 -> D4 (correctness before
# speed), with free-VRAM gates (D1/D2 >= 2560 MB; D3 measured >= 23000 MB),
# nvidia-smi snapshots into C:\bench-window\window.log at every stage
# boundary, and stage markers. Any stage failure: FAILED-<stage>, skip later
# measured stages, write DONE, exit.
# ============================================================================
set -uo pipefail
export PATH=/root/.cargo/bin:/root/.elan/bin:/usr/local/cuda/bin:/usr/bin:/bin
W=/mnt/c/bench-window
LOG=/root/bench/logs
mkdir -p "$LOG"
RLOG="$LOG/window-runner.log"
ROOT=/mnt/c/Users/kyleb_ypppor6/midnight-gpu-work

wlog(){ echo "$(date -u +%FT%TZ) WSL $*" >> "$W/window.log"; echo "=== $(date -u +%FT%TZ) $*"; }
snap(){
  local line
  line=$(nvidia-smi --query-gpu=timestamp,utilization.gpu,memory.used,memory.free --format=csv,noheader,nounits)
  echo "$line" >> "$RLOG"
  echo "$(date -u +%FT%TZ) WSL snap: $line" >> "$W/window.log"
}
free_mb(){ nvidia-smi --query-gpu=memory.used,memory.total --format=csv,noheader,nounits | awk -F', ' '{print $2-$1}'; }

fail(){ # $1 = stage label, $2 = exit code, $3 = one-line reason
  wlog "FAILED-$1 exit=$2 reason=$3"
  echo "$(date -u +%FT%TZ) WSL FAILED-$1 exit=$2" > "$W/FAILED-$1"
  echo "$(date -u +%FT%TZ) WSL runner done (failed at $1)" > "$W/DONE"
  wlog "runner exiting (failed at $1)"
  exit 1
}

# --- wait for SERVER-DOWN (finisher wrote it; max 30 min) ---
for i in $(seq 1 180); do
  [ -f "$W/SERVER-DOWN" ] && break
  sleep 10
done
[ -f "$W/SERVER-DOWN" ] || fail wait-server-down 1 "SERVER-DOWN marker never appeared"
wlog "runner start; SERVER-DOWN seen; free_mb=$(free_mb)"
snap
cd /root/midnight-zk || { wlog "cd /root/midnight-zk failed"; exit 3; }

# --- D1: device tests (byte-identity seeded_proofs_equal_cpu + fuzz + conformance; gate >= 2560) ---
F=$(free_mb)
if [ "$F" -lt 2560 ]; then fail d1 0 "gate: free_mb=$F < 2560"; fi
wlog "D1 start (device tests, free_mb=$F)"
MIDNIGHT_GPU_REQUIRE_CUDA=1 cargo test -p midnight-gpu --features cuda > "$LOG/win-d1.log" 2>&1
rc=$?
snap
grep -E "test result:" "$LOG/win-d1.log" | sed 's/^/D1: /' >> "$W/window.log"
if [ $rc -ne 0 ]; then fail d1 $rc "cargo test exit=$rc"; fi
wlog "D1 pass (exit=0)"

# --- D2: canonical formal gate; the byte-identity verdict lives here (gate >= 2560) ---
F=$(free_mb)
if [ "$F" -lt 2560 ]; then fail d2 0 "gate: free_mb=$F < 2560"; fi
wlog "D2 start (gpu-gate: frozen v2 vectors + ITF replay, free_mb=$F)"
bash gpu/scripts/gpu-gate.sh > "$LOG/win-d2.log" 2>&1
rc=$?
snap
tail -15 "$LOG/win-d2.log" | sed 's/^/D2: /' >> "$W/window.log"
if [ $rc -ne 0 ]; then fail d2 $rc "gpu-gate exit=$rc"; fi
if grep -q 'GPU gate: FAILED' "$LOG/win-d2.log"; then
  fail d2 0 "byte-identity verdict FAILED (gpu-gate verdict line: GPU gate: FAILED)"
fi
if ! grep -q 'GPU gate: passed' "$LOG/win-d2.log"; then
  fail d2 0 "no passing verdict line in win-d2.log"
fi
wlog "D2 pass (byte-identity verdict: 'GPU gate: passed' present in win-d2.log)"

# --- D3: rc1 bench k=21, CPU then GPU (MEASURED; gate >= 23000) ---
F=$(free_mb)
if [ "$F" -lt 23000 ]; then fail d3 0 "gate: free_mb=$F < 23000 (measured run needs an empty card)"; fi
wlog "D3 start (rc1 bench k=21 CPU+GPU, free_mb=$F)"
export RC1_K=21 RC1_WARM=1 RC1_REP=1
bash /root/bench/bench-run.sh cpu > "$LOG/win-d3-cpu.log" 2>&1
rc=$?
if [ $rc -ne 0 ]; then tail -10 "$LOG/win-d3-cpu.log" | sed 's/^/D3-cpu: /' >> "$W/window.log"; fail d3 $rc "cpu bench exit=$rc"; fi
grep -E "kernel_ms|verified|ok" "$LOG/win-d3-cpu.log" | tail -5 | sed 's/^/D3-cpu: /' >> "$W/window.log"
F=$(free_mb)
if [ "$F" -lt 23000 ]; then fail d3 0 "gate re-check before gpu stage: free_mb=$F < 23000"; fi
bash /root/bench/bench-run.sh gpu > "$LOG/win-d3-gpu.log" 2>&1
rc=$?
snap
if [ $rc -ne 0 ]; then tail -10 "$LOG/win-d3-gpu.log" | sed 's/^/D3-gpu: /' >> "$W/window.log"; fail d3 $rc "gpu bench exit=$rc"; fi
grep -E "kernel_ms|device_peak_bytes|verified|ok" "$LOG/win-d3-gpu.log" | tail -10 | sed 's/^/D3-gpu: /' >> "$W/window.log"
mkdir -p "$W/raw"
cp -f /root/bench/out/cpu-k21.tsv /root/bench/out/gpu-k21.tsv "$W/raw/" 2>/dev/null || true
wlog "D3 pass (raw tsv copied to C:\\bench-window\\raw)"

# --- D4: prover-par on/off (soft stage) ---
if [[ -x "$ROOT/prover-par-bench.sh" ]]; then
  wlog "D4 start (prover-par on/off)"
  bash "$ROOT/prover-par-bench.sh" > "$LOG/win-d4.log" 2>&1
  rc=$?
  snap
  if [ $rc -ne 0 ]; then
    tail -5 "$LOG/win-d4.log" | sed 's/^/D4: /' >> "$W/window.log"
    wlog "D4 soft-fail exit=$rc (recorded, not a window failure)"
  else
    tail -5 "$LOG/win-d4.log" | sed 's/^/D4: /' >> "$W/window.log"
    wlog "D4 pass"
  fi
else
  wlog "D4 SKIPPED: no off-arm prover-par binary (soft stage)"
fi

echo "$(date -u +%FT%TZ) WSL runner done ok" > "$W/DONE"
wlog "runner complete OK"
exit 0
