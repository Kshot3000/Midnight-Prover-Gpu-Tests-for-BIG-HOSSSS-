# STATE — Midnight GPU Prover, RTX 3090

Resume point. Last updated: 2026-11-21 10:35 CST (cycle 1).

## Current position
- **midnight-zk head checked out:** `6bcc6a56` (PR #667, head branch `gpu-prover-draft` in
  CharlesHoskinson/midnight-zk), merge-base `72a0512a`. Clone at
  `~/midnight-gpu-work/midnight-zk`, branch `pr667`.
- **Project repo:** initialized; SETUP.md, TASKS.md, STATE.md, RESULTS.md, LOG.md pushed (first push 2026-11-21).
- **Toolchains installed this cycle:**
  - rustup (stable 1.100.0 default, nightly-2026-05-29 for rustfmt — repo pins
    channel 1.90.0 in rust-toolchain.toml, so the pinned 1.90.0 must also be installed before
    building; verify `rustup toolchain list` each session).
  - **In progress (background 2026-11-21):** MSVC Build Tools 2022 (C++ workload, for nvcc host
    compile and blst) and CUDA Toolkit 13.5 (winget `Nvidia.CUDA`, `/s /toolkit` only — no driver).
- **Fork:** Kshot3000/midnight-zk exists (created 2026-11-21). Fix branches will be
  `gpu-3090/<short-topic>` in the fork.

## Known facts (observed, not assumed)
- GPU: RTX 3090 24 GB, driver/KMD 610.60, CUDA UMD 13.3, WDDM. sm_86.
- GPU was BUSY at cycle 1: llama-server (this agent's own LLM backend) holding ~21.7 GB.
  Measured GPU runs deferred; CPU/build work proceeds.
- CPU i9-11900KF 8C/16T, 128 GiB RAM, Windows 11 Home build 26200.
- Network quirk: `static.rust-lang.org` resets connections on HTTP/2 (curl + rustup both fail);
  rustup works with `RUSTUP_DIST_SERVER=https://rsproxy.cn RUSTUP_UPDATE_ROOT=https://rsproxy.cn/rustup`,
  and a plain curl download worked with `--http1.1`.

## Blockers (one line each)
- CUDA toolkit install running (2026-11-21 ~10:35 CST); until nvcc exists, task 5's CUDA build
  cannot start. No action needed from Kyle.
- Measured benchmarks (task 4) deferred: GPU held by another workload (llama-server / Athena).
  Per contention rule: log "GPU busy, deferring benches", work non-GPU items.

## Standing reminders
- Commit + push after EVERY step. The repo is the record.
- `scripts/check-generic.sh` before every push to upstream (no machine-specific paths/names in
  upstream contributions; the project repo may name this machine).
- git commit -s (DCO) under Kyle's identity. Never force-push. Never touch upstream branches.
  Never merge own PRs. One fix per upstream PR.
- Surface to Kyle immediately: correctness failure (GPU proof != CPU proof), security-relevant
  finding, or a blocker only Kyle can clear (driver install, reboot, upstream judgment call).
- Buffer wipe / zeroization is a security property — never weaken it; flag for Kyle.
