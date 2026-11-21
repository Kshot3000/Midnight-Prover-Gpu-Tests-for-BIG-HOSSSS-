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
- **NOT installed** as of 2026-11-21. No `nvcc` on PATH, no toolkit under
  `C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\`. The CUDA UMD 13.3 above is
  driver-only. A CUDA 12.x (hosting sm_86) or 13.x toolkit must be installed before
  the `gpu + cuda` build can compile. Flagged for the build step.

## CPU / RAM
- **CPU:** 11th Gen Intel Core i9-11900KF @ 3.50 GHz (8 cores / 16 threads)
- **RAM:** 127.68 GiB (130,744 MB)

## OS
- **OS:** Microsoft Windows 11 Home
- **Version / Build:** 10.0.26200 (26200)
- **BIOS (SMBIOS):** 1.1.24
- **Hostname note:** machine is a desktop ("Alien" form factor), user `kyleb_ypppor6`.

## Rust toolchains
- Rust was **NOT installed** at start; installed during setup on 2026-11-21 via
  `rustup-init.exe` (downloaded over HTTP/1.1; the default HTTP/2 path to
  static.rust-lang.org reset connections).
- Pinned nightly-2026-05-29 (repo's rustfmt pin): **status pending** — install
  after stable lands.

## GitHub
- `gh` authenticated as **Kshot3000** (keyring), scopes: gist, read:org, repo, workflow.
- Git identity: `KShot <kshot9000@gmail.com>`.

## GPU contention note
This PC runs Kyle's Athena dev cycles AND this agent's own LLM backend (llama.cpp on
the 3090). `nvidia-smi` must be checked before any measured run; if another workload
holds the GPU, defer benches and work a non-GPU item. Observed at setup time: the
3090 was serving an LLM process (llama-server), so the first cycles are CPU/build
work only.
