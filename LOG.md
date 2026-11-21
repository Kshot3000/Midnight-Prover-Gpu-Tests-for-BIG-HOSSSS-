# LOG — heartbeat per cycle

## 2026-11-21 11:45 CST — cycle 3
- **Item:** toolchain verification + stock baseline + gate launch (task 5, task 1 prerequisite).
- **Findings:**
  - WSL setup finished: CUDA Toolkit **13.0** installed, nvcc 13.0 at `/usr/local/cuda/bin`, gcc 13.2,
    Rust 1.90.0 (repo-pinned), native clone at PR head `6bcc6a56`.
  - **Stock build: PASS in 46 s** (no features, `cargo build --workspace`).
  - **Stock full test suite, first pass: 24 FAILED — all one root cause.** Every failure is
    `zk_stdlib` VK/cost tests + `tests/public_inputs.rs` + `tests/serialization.rs` + 2 doc tests,
    all panicking in `filecoin_srs()`: the Filecoin SRS file `zk_stdlib/examples/assets/bls_filecoin_2p19`
    was never downloaded on this fresh machine. **Not a PR regression** — `git diff 72a0512a..6bcc6a56`
    touches neither `zk_stdlib/` nor `zkvm/` (572 files, all gpu/proofs/bench/formal). Downloaded the
    97 MB SRS from Midnight's S3 (`SRS_DOWNLOAD_OK`) and re-running the full suite with `--no-fail-fast`.
  - **GPU state:** 22.3/24 GB in use, GPU util **87 %** (llama-server actively serving this agent's
    own inference). ~2.0 GB free. Measured GPU runs deferred per contention rule.
  - **Environment note:** WSL `octanode` idle-shuts between commands (VM restarts, drops `/tmp` +
    mounts). A `setsid sleep 604800` keep-alive is running; all long jobs now launch via setsid with
    logs to `~/bench/logs` (persistent ext4) and use absolute tool paths.
  - Bench harness read: `rc1-bench prepare` (SRS + pk, CPU, cached in `RC1_CACHE/rc1-chain-v1-k21/`),
    `rc1-bench run` with `RC1_K=21 RC1_WARM=1 RC1_REP=1`; CUDA build gets `rc1_device` cfg and emits
    `kernel_ms` + `device_peak_bytes` + device-verifier lines; stock binary re-verifies the GPU proof
    when `RC1_STOCK_BIN` is set. PR reference (5090-Laptop, k=21): CPU 17.917 s, GPU 4.374 s, 4.10×.
  - Device test suite inventory: `gpu/tests/prover.rs` has `seeded_proofs_equal_cpu` (task 1,
    byte-identity at k=11..15, 31-bit seeds + 64-bit seeds — 100 MB of GPU VRAM) and
    `quotient_check_mode_fuzz` (task 3). Gate = frozen v2 oracle vectors + `gpu-gate.sh` (canon form
    `2^47-2^11-2^9+2^7+1`).
- **Done:**
  - Wrote + tested `bench-run.sh` (check/prepare/cpu/gpu with GPU-busy gate; gpu branch preserves the
    device binary separately from the stock verifier). `check` reports GPU_BUSY_DEFER (1998/2013 MB
    free < 2560 needed).
  - Wrote `gate-run.sh` (stage 1 stock tests → stage 2 stub tests → stage 3 gpu+cuda build → stage 4
    gpu+cuda tests), launched via setsid, logging to `~/bench/logs/`.
- **GPU check:** busy (22.3 GB, 87 % util). No measured GPU runs this cycle.
- **Next:** read `~/bench/logs/stage.log` + `stock-summary.txt` when gate finishes; investigate the
  `check_vk_ethereum_sig` failure (environment vs regression); then task 1 byte-identity on device
  once VRAM frees; k=21 benchmarks when the 3090 is idle.

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
