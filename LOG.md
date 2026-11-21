# LOG — heartbeat per cycle

## 2026-11-21 11:10 CST — cycle 2
- **Item:** build environment (task 5 prerequisites).
- **Findings:**
  - Windows-side installs hit a wall: UAC prompts cancelled twice (winget 1602 BuildTools;
    0x800704c7 CUDA). Agent shell is non-elevated; no C compiler anywhere on Windows; no MSVC.
  - Discovered **WSL2 distro `octanode`** (Ubuntu 24.04, root, 16 cores, 120 GB RAM, 825 GB
    free) with working **GPU passthrough** (nvidia-smi sees the 3090, driver 610.60) and clean
    HTTP/2 to rust-lang.org. The PR's Linux-shaped build.rs builds unmodified there.
  - Moved stray `/usr/bin/link` (PE32+ exe shadowing MSVC's link.exe) aside to
    `~/midnight-gpu-work/stray-usr-bin-link.bak` (reversible).
- **Done:** launched `wsl-setup.sh` in octanode: build-essential + CUDA apt repo +
  cuda-toolkit (13.0, fallback 12.8) + rustup (1.90.0 default, nightly-2026-05-29) + native
  clone of midnight-zk at PR head 6bcc6a56.
- **GPU check:** still busy (21.7 GB llama-server). No measured runs this cycle.
- **Next:** when setup finishes — stock build + full test suite (known-good floor), then
  `gpu + cuda` build on the 3090, then task 1 correctness.

## 2026-11-21 10:40 CST — cycle 1
- **Item:** setup + baseline (tasks 5 build prerequisites).
- **Done:**
  - Read PR #667 in full (head 6bcc6a56, base 72a0512a; head branch gpu-prover-draft).
  - Inventoried machine into SETUP.md: RTX 3090 24 GB (driver 610.60, CUDA UMD 13.3), i9-11900KF, 128 GiB RAM, Win11 Home build 26200.
  - Installed Rust: stable 1.100.0 + nightly-2026-05-29 (via rsproxy.cn mirror; static.rust-lang.org resets HTTP/2 connections from this machine — recorded in STATE.md).
  - Cloned midnight-zk, checked out PR head 6bcc6a56.
  - Forked to Kshot3000/midnight-zk.
  - Started background installs: MSVC Build Tools 2022 (C++ workload) + CUDA Toolkit 13.5 (toolkit only).
- **GPU check:** busy (~21.7 GB held by llama-server = this agent's own LLM backend). Measured GPU runs deferred this cycle.
- **Outcome:** no measured numbers yet; environment is coming up.
- **Next:** confirm CUDA + MSVC installs; install pinned Rust 1.90.0; run stock build + full test suite (known-good floor); then gpu-without-cuda stub build.
