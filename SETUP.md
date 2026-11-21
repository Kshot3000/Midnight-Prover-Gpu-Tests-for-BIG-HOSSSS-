# SETUP — machine inventory

Recorded 2026-11-21 by the Hermes local agent on Kyle Cox's PC.

## GPU
- **Model:** NVIDIA GeForce RTX 3090 (Ampere, sm_86)
- **VRAM:** 24576 MiB (24 GB)
- **Driver / KMD:** 610.60
- **CUDA UMD (driver-side):** 13.3
- **Display mode:** WDDM (Windows)
- `nvidia-smi` observed at 2026-11-21 10:22 CST: 285 W / 350 W, temp 67 C, ~21.7 GB VRAM in use by other workloads (see GPU contention note).

## CUDA toolkit
- **Windows:** NOT installed as of 2026-11-21. Only the NVIDIA driver (610.60 / UMD 13.3) is
  present. winget installs failed on UAC (agent shell is non-elevated).
- **WSL2 (octanode):** toolkit being installed 2026-11-21 via the official CUDA apt repo
  (cuda-toolkit-13.0, fallback 12.8). GPU is passed through from the Windows driver;
  `nvidia-smi` inside the distro reports driver 610.60 and the full 24 GB.

## Rust toolchains
- **Windows:** rustup 1.100.0 stable (default), 1.90.0 (repo pin), nightly-2026-05-29 (rustfmt
  pin). Installed 2026-11-21 via the rsproxy.cn mirror (static.rust-lang.org resets HTTP/2
  connections from Windows here).
- **WSL (octanode):** rustup default 1.90.0 + nightly-2026-05-29 installed by `wsl-setup.sh`.

## CPU / RAM
- **CPU:** 11th Gen Intel Core i9-11900KF @ 3.50 GHz (8 cores / 16 threads)
- **RAM:** 127.68 GiB (130,744 MB)

## OS
- **OS:** Microsoft Windows 11 Home
- **Version / Build:** 10.0.26200 (26200)
- **BIOS (SMBIOS):** 1.1.24
- **WSL2:** distro `octanode` (Ubuntu 24.04 LTS, runs as root) — the build environment.
  16 vCPU, 120 GB RAM, 825 GB free, GPU passthrough, native ext4 build tree.
  (Second distro `salarad-enterprise-linux` is registered but does not start — not used.)
- **Hostname note:** machine is a desktop ("Alien" form factor), user `kyleb_ypppor6`.

## GitHub
- `gh` authenticated as **Kshot3000** (keyring), scopes: gist, read:org, repo, workflow.
- Git identity: `KShot <kshot9000@gmail.com>`.

## GPU contention note
This PC runs Kyle's Athena dev cycles AND this agent's own LLM backend (llama.cpp on
the 3090). `nvidia-smi` must be checked before any measured run; if another workload
holds the GPU, defer benches and work a non-GPU item. Observed at setup time: the
3090 was serving an LLM process (llama-server), so the first cycles are CPU/build
work only.
