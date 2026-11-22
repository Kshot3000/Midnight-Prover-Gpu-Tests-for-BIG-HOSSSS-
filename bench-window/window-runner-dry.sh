#!/usr/bin/env bash
# ============================================================================
# Actor 2 (DRY RUN) — 60-second no-op replacing the real runner. Waits for
# SERVER-DOWN, sleeps 60s, writes DONE. Contract: v2 standing orders, Phase 0
# step 4 (dry window).
# ============================================================================
set -uo pipefail
W=/mnt/c/bench-window
LOG=/root/bench/logs
mkdir -p "$LOG"
wlog(){ echo "$(date -u +%FT%TZ) WSL-DRY $*" >> "$W/window.log"; echo "=== $(date -u +%FT%TZ) $*"; }

for i in $(seq 1 180); do
  [ -f "$W/SERVER-DOWN" ] && break
  sleep 10
done
if [ ! -f "$W/SERVER-DOWN" ]; then
  wlog "FAILED-wait-server-down"
  echo "$(date -u +%FT%TZ) WSL-DRY FAILED-wait-server-down" > "$W/FAILED-wait-server-down"
  echo "$(date -u +%FT%TZ) WSL-DRY runner done (failed)" > "$W/DONE"
  exit 1
fi
wlog "dry runner: SERVER-DOWN seen; 60s no-op start"
sleep 60
wlog "dry runner: no-op complete"
echo "$(date -u +%FT%TZ) WSL-DRY runner done ok" > "$W/DONE"
exit 0
