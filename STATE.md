# STATE — Midnight GPU Prover, RTX 3090

Resume point. Last updated: 2026-11-21 15:55 CST (cycle 3e).

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
  builds work). **CPU baseline (3 repeats, warm=5) RUNNING** — CPU leg does not use the GPU, so it
  proceeds while llama-server holds VRAM (contention rule permits CPU work). Log
  `~/bench/logs/rc1-cpu-phase.log`.
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
  when busy, log "GPU busy, deferring" and work non-GPU items.

## Standing reminders
- Commit + push after EVERY step. The repo is the record.
- `scripts/check-generic.sh` before every push to upstream (no machine-specific paths/names in
  upstream contributions; the project repo may name this machine).
- git commit -s (DCO) under Kyle's identity. Never force-push. Never touch upstream branches.
  Never merge own PRs. One fix per upstream PR.
- Surface to Kyle immediately: correctness failure (GPU proof != CPU proof), security-relevant
  finding, or a blocker only Kyle can clear (driver install, reboot, upstream judgment call).
- Buffer wipe / zeroization is a security property — never weaken it; flag for Kyle.
