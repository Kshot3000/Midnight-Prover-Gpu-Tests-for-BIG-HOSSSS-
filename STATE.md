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
- **Build location (decision 2026-11-21):** WSL2 distro `octanode` (Ubuntu 24.04, root,
  16 cores, 120 GB RAM). Build tree: `~/midnight-zk` (native ext4, PR head 6bcc6a56).
  Windows-side Rust (stable 1.100.0, 1.90.0, nightly-2026-05-29) remains usable for reading
  and non-build work, but no Windows build is attempted — see blockers.

## Known facts (observed, not assumed)
- GPU: RTX 3090 24 GB, driver/KMD 610.60, CUDA UMD 13.3, WDDM. sm_86.
- GPU was BUSY at cycle 1: llama-server (this agent's own LLM backend) holding ~21.7 GB.
  Measured GPU runs deferred; CPU/build work proceeds.
- CPU i9-11900KF 8C/16T, 128 GiB RAM, Windows 11 Home build 26200.
- Network quirk: `static.rust-lang.org` resets connections on HTTP/2 (curl + rustup both fail);
  rustup works with `RUSTUP_DIST_SERVER=https://rsproxy.cn RUSTUP_UPDATE_ROOT=https://rsproxy.cn/rustup`,
  and a plain curl download worked with `--http1.1`.
- **Environment quirk (2026-11-21):** `/usr/bin/link` in git-bash is a PE32+ Windows exe (33 KB,
  2026-03-23) that shadows MSVC's `link.exe` for rustc; the stock workspace build failed at link
  with "link: extra operand ...rcgu.o". Must run cargo with MSVC's bin dir first on PATH (vcvars)
  OR move/rename the stray /usr/bin/link.
- **Privilege (2026-11-21):** the agent shell runs non-elevated (whoami kyleb_ypppor6, not admin).
  winget 1602 (BuildTools) and 0x800704c7 "canceled by the user" (CUDA — the UAC prompt was
  declined/missed) both need admin. Elevated retry of BuildTools launched 2026-11-21 ~10:47 CST
  via Start-Process -Verb RunAs; if the UAC prompt was missed it will fail again. CUDA 13.5
  toolkit install must be retried elevated too. **This is a Kyle-only-unblock if UAC keeps failing.**
- **build.rs portability finding (2026-11-21, code read, not yet reproduced at build time):**
  `gpu/build.rs` is Linux-shaped. It will not build the CUDA core on Windows/MSVC:
  (1) line 138 calls Unix `ar crs` to make libmidnight_gpu_cuda.a — MSVC has no `ar` (lib.exe);
  (2) line 154 emits `-Wl,-rpath,...` which link.exe rejects; (3) line 159 links `dylib=stdc++`
  (no such import lib on MSVC); (4) `cuda_target_lib()` returns `x86_64-linux`, never
  `x86_64-windows`. So `gpu + cuda` on Windows falls back to the declining stub even with nvcc
  present, until build.rs is made portable. The PR's CI note ("workflows have not yet run on a
  GitHub runner") plus the Linux-only device diagnostic paths suggest this was never built on
  Windows. This is candidate task-5 material: reproduce at build time, then fix (branch
  gpu-3090/windows-build) or document as an environment limit.

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
