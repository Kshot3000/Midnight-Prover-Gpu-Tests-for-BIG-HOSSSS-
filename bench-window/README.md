# BENCH WINDOW — RTX 3090 GPU leg (rebuilt 2026-11-22 per v2 standing orders)

Contract: the rewritten standing orders PDF ("Hermes — Midnight GPU Prover on the
RTX 3090: complete standing orders (rewritten 2026-11-21)"). This directory is the
single source of truth for the three machines that run the GPU leg without the
agent in the loop. The agent arms, steps off, and reads results when it wakes.

## Signal folder (both sides can see it)

- Windows: `C:\bench-window\`
- WSL: `/mnt/c/bench-window/`

Markers:

| Marker | Writer | Meaning |
|---|---|---|
| `ARMED` | arm script (agent, before stepping off) | window is live |
| `SERVER-DOWN` | finisher (Actor 1) | server stopped, VRAM free (≥ 23,000 MB) |
| `DONE` | WSL runner (Actor 2) | all stages finished |
| `FAILED-<stage>` | WSL runner (Actor 2) | that stage failed; later measured stages skipped |
| `RESTORED` | finisher / dead-man | server back, touch generation passed |
| `RESTORED-FAILED` | finisher / dead-man | restore did not confirm readiness (retried on next dead-man tick) |
| `window.log` | everyone | append-only, timestamped |
| `raw/` | WSL runner | raw tsv outputs, unedited |

## The three actors

1. **Finisher** (`finisher.ps1`, Windows PowerShell, detached): verifies ARMED +
   holder identity against `server-record.json` (exact PID, exact command line,
   exact exe path, parent = router, no other llama-server processes, VRAM sanity);
   stops the Qwen worker through the router's native `POST /models/unload` (the
   worker is the router's child — that endpoint is its designed graceful path);
   polls `nvidia-smi` until free VRAM ≥ 23,000 MB (3 min, then one
   `Stop-Process` on the exact recorded worker PID only); writes `SERVER-DOWN`;
   waits for `DONE`/`FAILED-*` (30 s poll, 4 h hard cap); restores via
   `POST /models/load` + touch generation (the Hermes supervisor's own readiness
   proof); writes `RESTORED`; logs `WINDOW CLOSED`. Never spawns llama-server
   processes; never pattern-kills; the router is supervised by the Hermes app and
   is never touched.
2. **WSL runner** (`window-runner.sh`, real; `window-runner-dry.sh`, 60 s no-op
   rehearsal): waits for `SERVER-DOWN`, then runs D1 → D2 → D3 → D4 with
   free-VRAM gates (D1/D2 ≥ 2,560 MB; D3 ≥ 23,000 MB — a measured run on a
   contended card is not a measurement), `nvidia-smi` snapshots at every stage
   boundary, and the D2 byte-identity verdict read from the gate's real verdict
   lines (`GPU gate: FAILED` / `GPU gate: passed`).
3. **Dead-man's switch** (`deadman.ps1`, Windows Scheduled Task
   `MidnightBenchWindowDeadman`, every 15 min, registered once, left forever):
   if `ARMED` exists, `RESTORED` doesn't, and > 4 h 15 min since `SERVER-DOWN` →
   restore via the router API and log `DEADMAN RESTORE`. No-op when nothing is
   armed. There is no state of this system in which the server stays off.

## Identity record (Phase 0 step 1)

`server-record.json` — captured AT ARMING TIME by `rebuild-record.ps1` (run it as
the first step of arming; the router/worker pair restarts on the hour with
changing ports, so identity is never reused from a previous window). Contents:
worker PID + port + verbatim command line + exe path, router PID, model id,
router URLs, recorded timestamp. The router API key is deliberately NOT in this
file; the actors read it live from
`AppData\Local\hermes\runtimes\llamacpp\.api_key`.

## The llama-server architecture (why the API, not a re-spawn)

This agent's LLM backend is a Hermes-managed llama-server in router mode:

- **router**: `llama-server.exe` PID (varies), port 18434, child of the Hermes
  app process; `--models-autoload --models-max 4`; state in
  `AppData\Local\hermes\runtimes\llamacpp/server.json`.
- **worker**: the router spawns a **child** `llama-server.exe` per loaded model
  (alias `Qwen3.8-27B-UD-Q4_K_M`), holding ~21.7 GB VRAM.

The supervisor (`hermes-agent/hermes_cli/local_runtime/supervisor.py`) manages
models through `POST /models/load`, `POST /models/unload`, and a touch
generation (temp-0, expected token). Stopping the worker by PID is therefore
never the first path — the router's unload endpoint is the designed graceful
path — and restarting by replaying the worker command line is wrong, because the
router is the parent of record. The finisher and dead-man both go through the
API.

## Operating procedure

**Phase 0 (done 2026-11-22):**
1. Identity recorded (above). ✔
2. Finisher + dead-man written, `parse-check.ps1` all green; `device-phase.sh`
   re-read end-to-end; D2 verdict grep fixed to the gate's real verdict lines. ✔
3. Athena Dev Cycle pause: **no such scheduled task exists on this machine**
   (187 Windows tasks, none matching; all four Hermes profiles' cron stores
   empty). Athena runs via the Hermes app/CLI, not a scheduled task. Nothing to
   pause; recorded in `server-record.json` as `AthenaTask: null` and re-checked
   at each arming.
4. **Dry window** (once): `arm-dry.ps1` — verifies the holder, clears stale
   markers, writes `ARMED`, launches the 60 s no-op runner (WSL, detached) and
   the finisher (detached), confirms the finisher is alive. The agent then ends
   its turn (steps off). On waking: verify (a) a normal agent turn completes,
   (b) `window.log` shows the full sequence, (c) `RESTORED` exists; note what
   the harness did while the endpoint was down; commit the outcome.
5. If the dry window fails anywhere → do NOT attempt the real one; open a
   `HELP:` issue with `window.log` in the body; work non-GPU items.

**Real window:** identical, with `window-runner.sh` instead of the dry runner
(launched the same way). Budget 2 h expected, 4 h hard cap. On waking: read
`window.log` + every stage log; verify markers against logs (never trust a
marker alone); write RESULTS.md with only what was measured (correctness
verdict first; then GPU warm median vs the 26.27 s CPU baseline, ratio,
hardware line, head SHA, commands); update STATE/TASKS/LOG; commit; push;
delete `ARMED` once `RESTORED` is confirmed.

## Files

| File | Where | Role |
|---|---|---|
| `server-record.json` | `C:\bench-window\` | live identity record (rebuilt each arming) |
| `rebuild-record.ps1` | `C:\bench-window\` + this repo | capture identity at arming |
| `restart-core.ps1` | `C:\bench-window\` + this repo | restore via router API + touch (dot-sourced) |
| `finisher.ps1` | `C:\bench-window\` + this repo | Actor 1 |
| `deadman.ps1` | `C:\bench-window\` + this repo | Actor 3 body |
| `register-deadman.ps1` | `C:\bench-window\` + this repo | register Actor 3 once |
| `arm-dry.ps1` | `C:\bench-window\` + this repo | arm the dry window (last agent action) |
| `parse-check.ps1` | `C:\bench-window\` + this repo | PS parse gate for all .ps1 |
| `window-runner.sh` | `/root/bench/` (installed) + this repo | Actor 2 (real) |
| `window-runner-dry.sh` | `/root/bench/` (installed) + this repo | Actor 2 (rehearsal) |
| `install-wsl.sh` | this repo | install runner scripts into WSL with LF endings + keep-alive |

WSL-side bench infrastructure (unchanged): `/root/bench/bench-run.sh`
(`cpu`/`gpu`/`check`/`prepare`), `/root/bench/device-phase.sh` (the original
staged phase; the window runner extends its gates and stage ordering),
`/root/bench/logs/` (ext4, survives WSL idle-shutdown), keep-alive
`setsid sleep 604800`.
