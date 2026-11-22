#!/usr/bin/env bash
# Install the bench-window WSL runner scripts into /root/bench with LF endings.
set -u
B=/mnt/c/Users/kyleb_ypppor6/midnight-gpu-work/bw
for f in window-runner.sh window-runner-dry.sh launch-dry.sh launch-real.sh; do
  if [ ! -f "$B/$f" ]; then echo "MISSING $f"; continue; fi
  cp "$B/$f" /root/bench/"$f"
  sed -i 's/\r$//' /root/bench/"$f"
  if bash -n /root/bench/"$f"; then echo "SYNTAX-OK $f"; else echo "SYNTAX-FAIL $f"; fi
done
# keep-alive: ensure exactly one sleep 604800 (WSL idle-shut guard)
N=$(ps -eo args | grep -c "[s]leep 604800")
if [ "$N" -eq 0 ]; then
  setsid nohup sleep 604800 >/dev/null 2>&1 < /dev/null &
  sleep 1
  N=$(ps -eo args | grep -c "[s]leep 604800")
  echo "keepalive started: $N"
else
  echo "keepalive present: $N"
fi
echo "WSL-INSTALL-DONE"
