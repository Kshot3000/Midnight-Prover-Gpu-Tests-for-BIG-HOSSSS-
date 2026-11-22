# STATE — Midnight GPU Prover, RTX 3090

Resume point. Last updated: 2026-11-22 08:25 CST (cycle 6).

## Current position
- **Task 7 (formal toolchain + conformance): COMPLETE.** Full chain built and proven in WSL
  `octanode`: node 20.20.2 → `@informalsystems/quint@0.32.0` → elan 4.4.0 → Lean 4.35.0 (matches
  `lean-toolchain`) → oracle exe (119 MB, `.lake/build/bin/oracle`). `scripts/quint_check.sh`
  conformance replay: **PASS, exact match to upstream** — 20/20 instances `quint check` ok
  (10,000 samples each), 34 replay sections = **1,078 traces / 40,473 transitions / 0 disagree /
  0 excused**, 3 refusals + 2 negative controls behave, initial states 1,078/0 differ.
  Log: `raw/conformance-2026-11-21.log`.
- **Task 5 (build verification): COMPLETE** (cycle 3c/3d). Stock build PASS 46 s; stock full
  suite GREEN 126/126 after SRS fix; stub build + tests pass; `gpu + cuda` device build PASS
  1 m 59 s; bench prepare (k=21) done (577 MB at `/root/bench/rc1-cache/rc1-chain-v1-k21/`).
- **rc1 bench toolchain (cycle 3e): COMPLETE.** Canonical `build.sh` (repo root) → `rc1-cpu`
  3.4 MB + `rc1-gpu` (sm_86) 5.8 MB at `/root/rc1-results/bin/`; `cargo fetch` done (offline
  builds work).
- **CPU baseline (k=21, this 3090 box): COMPLETE.** Warm median **26.27 s** (range
  21.22–27.22, stdev 1.91, 15 warm runs), cold 26.79 s, 18/18 proofs verified. In RESULTS.md;
  raw `raw/rc1-cpu-3090-2026-11-21.tsv`. (This box is slower than the PR's 5090-Laptop
  reference of 17.917 s — different machine; the GPU leg is measured on this box and quoted
  against this box's baseline.)
- **Dry window (v3 mandate): attempts 1-2 closed, attempt 3 armed at end of cycle 6.**
  Attempt 1 (03:03): 401 at the finisher's first router check (PS 5.1 dot-assign bug → empty
  bearer) — fixed (key read inline + authenticated pre-flight). Attempt 2 (06:35): the STOP
  path worked end-to-end (unload API → worker gone → 23,513 MB free → SERVER-DOWN) but the WSL
  dry runner never started (launcher argv bug — below); the agent wrote DONE after the fact
  and the finisher completed restore → RESTORED → WINDOW CLOSED (08:19:59). Harness behavior
  during the ~70-min outage: router stayed up; the first post-outage request triggered router
  autoload which reloaded the model (new worker pid, same exe + parent router) — no crash, no
  user-visible error, zero surprises. arm-dry/arm-real fixed: runner launched via
  `/root/bench/launch-*.sh` (no shell metacharacters in the wsl.exe argv) and the runner out
  file is verified before ARMED is written.
- **midnight-zk head:** `6bcc6a56` (PR #667 head), merge-base `72a0512a`. Native clone
  `~/midnight-zk`, branch `pr667`.
- **Toolchains:** WSL `octanode` CUDA 13.0 (`/usr/local/cuda/bin/nvcc`, sm_86 in DEFAULT_ARCHS),
  gcc 13.2, Rust 1.90.0 (repo-pinned). Windows Rust (1.100.0/1.90.0/nightly) parked for read-only.
- **Fork:** Kshot3000/midnight-zk; fix branches `gpu-3090/<short-topic>`.
- **Device phase staged:** `~/bench/device-phase.sh` (gated `free_mb >= 2560`): D1 device tests →
  D2 canonical `gpu-gate.sh` → D3 rc1 bench GPU + stock re-verify → D4 prover-par on/off
  (soft-gated; needs a second tree without the `prover-par` feature — ABAB staged next cycle).
  Fires the moment VRAM frees.

## Known facts (observed, not assumed)
- GPU: RTX 3090 24 GB, driver 610.60, CUDA UMD 13.3, WDDM, sm_86.
- **PR reference (5090-Laptop, k=21, from repo RESULTS.md):** GPU warm **4.374 s** (615.2 MB
  proof, 12,800 KB, 4.18 MB/s), CPU **17.917 s**, ratio **4.10×**; 32 KB input. Our CPU baseline
  should land near ~17–18 s (16 cores, warm).
- **Upstream conformance (formal/gpu-prover/RESULTS.md):** 1,078 traces / 40,473 transitions,
  20 instances (10,000 samples), 14 directed tests, 0 violations, 0 excused — our local replay
  matches it exactly.
- WSL idle-shut: VM restarts between short commands. Keep-alive `setsid sleep 604800` running;
  long jobs via setsid, logs in `~/bench/logs/` (ext4), absolute tool paths in every script.
- Network quirk: `static.rust-lang.org` resets HTTP/2; use rsproxy.cn / `curl --http1.1`.
- **build.rs on Windows:** Linux-shaped (`ar crs`, `-Wl,-rpath`, `dylib=stdc++`, `x86_64-linux`
  only) → `gpu + cuda` falls back to the declining stub on Windows/MSVC. Reproduced infeasible
  cycle 3; documented as environment limit (WSL2 is the path the PR was written for).
- CPU: i9-11900KF 8C/16T, 128 GiB RAM, Windows 11 Home build 26200 (agent shell non-elevated).
- Windows-side quirk: stray `/usr/bin/link` (PE32+ exe) shadowed MSVC `link.exe` for rustc; moved
  aside to `~/midnight-gpu-work/stray-usr-bin-link.bak`. Windows build abandoned in favor of WSL2.

## Blockers (one line each)
- ~~CUDA toolkit + MSVC install via winget (needs admin)~~ SUPERSEDED 2026-11-21: UAC prompts were
  cancelled on both attempts (1602 / 0x800704c7). Pivoted to WSL2: distro `octanode` (Ubuntu
  24.04, root, 16 cores, 120 GB RAM, 825 GB free, GPU passthrough confirmed: nvidia-smi via
  /usr/lib/wsl/lib shows the 3090 at driver 610.60) gets CUDA toolkit + rust 1.90.0 installed by
  a non-elevated apt script (running since 2026-11-21 ~11:0x CST, `wsl-setup.sh`). The build is
  the Linux path the PR was written for — no build.rs portability issues, no UAC. Windows-side
  toolchain work is parked, not cancelled.
- Measured benchmarks (task 4) deferred: 3090 holds ~21.7 GB for llama-server (this agent's own
  LLM backend), ~2.8 GB free. Per contention rule: check `nvidia-smi` before each measured run;
  when busy, log "GPU busy, deferring" and work non-GPU items. **SUPERSEDED by the bench window**
  (v2 standing orders 2026-11-21, Kyle-approved): the three-actor window runs the GPU leg with
  the server briefly stopped and restored. See `bench-window/README.md`. Phase 0 complete
  2026-11-22: identity recorded, finisher/dead-man built + parse-checked, dead-man registered
  (`MidnightBenchWindowDeadman`, 15-min cadence), D2 verdict grep fixed to the gate's real
  verdict lines. Athena Dev Cycle: no such Windows scheduled task exists (verified 187 tasks;
  all Hermes cron stores empty, Athena executions.db 0 rows) — nothing to pause; recorded as
  `AthenaTask: null`. Dry window: attempt 1 (03:03) failed on a 401 → fixed (key read inline
  at every use site + authenticated pre-flight); attempt 2 (06:35) proved the stop path
  end-to-end but exposed the runner launch bug — Start-Process -ArgumentList does not quote
  shell metacharacters, so `wsl.exe --exec bash -lc "setsid nohup ..."` split into argv and
  bash ran only `setsid` (the runner never ran in either attempt; nothing would have noticed
  until the 4h cap) → arm-dry/arm-real now launch via `/root/bench/launch-*.sh` and verify the
  runner out file before ARMED. Attempt 3 armed 2026-11-22 ~08:25 CST.

## Bench window (GPU leg machinery)
- Signal folder `C:\bench-window\` (WSL `/mnt/c/bench-window/`): ARMED / SERVER-DOWN / DONE /
  FAILED-<stage> / RESTORED / RESTORED-FAILED / window.log / raw/.
- Actor 1 finisher (Windows, detached): verify holder vs record → stop via router's native
  `POST /models/unload` (worker is the router's child; that's its designed graceful path) →
  VRAM ≥ 23,000 MB free → SERVER-DOWN → wait DONE/FAILED (4 h cap) → restore via
  `POST /models/load` + touch generation → RESTORED → WINDOW CLOSED.
- Actor 2 WSL runner: waits SERVER-DOWN; D1 → D2 (byte-identity verdict) → D3 (rc1 k=21,
  gate ≥ 23,000 MB) → D4 (soft); nvidia-smi snapshots at stage boundaries. Launched through
  the launcher scripts `/root/bench/launch-dry.sh` / `launch-real.sh` (the `wsl.exe --exec`
  argv must carry no shell metacharacters; the launcher does the setsid/nohup/&); the armer
  verifies the runner's out file exists before writing ARMED (2026-11-22, attempts 1-2
  postmortem).
- Actor 3 dead-man (Windows Scheduled Task, 15 min, registered forever): > 4 h 15 min since
  SERVER-DOWN → restore via router API, DEADMAN RESTORE.
- Architecture note: my LLM backend is a Hermes-managed llama-server in router mode (port
  18434, child of the Hermes app); the Qwen worker is the router's child process. The
  supervisor (`hermes_cli/local_runtime/supervisor.py`) manages models via /models/load,
  /models/unload + touch generation — the window uses exactly those paths and never spawns
  or pattern-kills processes. The router API key is NOT stored in the record file; actors
  read it live from the hermes runtimes llamacpp `.api_key` store (see bench-window/README.md).
- Identity is recorded AT ARMING TIME (`rebuild-record.ps1`): the router/worker pair
  restarts on the hour with changing ports, so a stale record is a hard abort, not a guess.

## Standing reminders
- Commit + push after EVERY step. The repo is the record.
- `scripts/check-generic.sh` before every push to upstream (no machine-specific paths/names in
  upstream contributions; the project repo may name this machine).
- git commit -s (DCO) under Kyle's identity. Never force-push. Never touch upstream branches.
  Never merge own PRs. One fix per upstream PR.
- Surface to Kyle immediately: correctness failure (GPU proof != CPU proof), security-relevant
  finding, or a blocker only Kyle can clear (driver install, reboot, upstream judgment call).
- Buffer wipe / zeroization is a security property — never weaken it; flag for Kyle.
