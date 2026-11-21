# RESULTS — Midnight GPU Prover on RTX 3090

Baseline state — 2026-11-21 (cycle 1). No numbers yet; setup in progress.

| Date | midnight-zk head | Feature set | Hardware | Result | Command |
|---|---|---|---|---|---|
| 2026-11-21 | (none — pre-build) | — | RTX 3090 24 GB, driver 610.60, CUDA UMD 13.3, i9-11900KF, Win11 26200 | Environment inventoried; Rust installed; CUDA toolkit + MSVC install in progress | nvidia-smi / rustup / winget |

## PR reference numbers (from PR #667, RTX 5090 Laptop — NOT measured on this machine)

Single proofs, CPU vs GPU (seconds), k = 21:

| k | CPU warm median | GPU warm median | Speed-up | CPU cold | GPU cold | GPU device peak |
|---|---:|---:|---:|---:|---:|---:|
| 21 | 17.917 (17.740-17.920) | 4.374 (4.354-4.459) | 4.10x | 17.576 | 4.714 | 1975.2 MB |

Session: 2026-11-18, RTX 5090 Laptop 24 GB driver 615.78.08, Core Ultra 9 275HX 24 prover
threads, tree 9070a373 on base 4bea43d4, chain circuit of bench/gpu-prover/rc1, 1 cold + 3 warm
proofs per mode, every proof checked by the stock CPU verifier, all runs exited 0. These numbers
predate the rebase onto 72a0512a and have not been re-measured. They are shown here as the
comparison baseline only.

prover-par (k = 21, 5 interleaved pairs): 1.022x (1.011-1.031).

## 3090 numbers (measured on this machine)

| Date | midnight-zk head | Feature set | Hardware | Result | Command |
|---|---|---|---|---|---|
| 2026-11-21 | 6bcc6a56 | rc1 bench, cpu | CPU only (i9-11900KF, 8 prover threads, WSL2 16 cores); GPU busy (llama-server) but CPU leg needs no GPU; k=21 | **CPU warm prove: 26.27 s median** (mean 25.25, range 21.22–27.22, stdev 1.91; 15 warm runs, 3 repeats × 5); cold 26.79 s median (21.12–27.47); **all 18 proofs verified=true**, verify ~1.8 ms | `rc1-cpu` (bench/gpu-prover/rc1, canonical 3-rep × warm=5) |

Headline (measured 2026-11-21, head 6bcc6a56, WSL2 octanode, k=21, 8 prover threads):
- **CPU warm prove: 26.27 s median** (21.22–27.22 s across 15 warm runs; tightest repeat 22.74 s).
  Cold 26.79 s median. Every proof verified=true by the stock CPU verifier; verify ~1.6–3.3 ms.
  Raw: `raw/rc1-cpu-3090-2026-11-21.tsv`.
- GPU warm: not yet measured — 3090 VRAM held ~21.7 GB by llama-server; GPU leg deferred per
  contention rule (device phase staged, fires on free-VRAM).
- vs PR reference (5090-Laptop, 24 prover threads, 17.917 s CPU / 4.374 s GPU / 4.10×): our CPU
  number is on a different CPU (i9-11900KF, 8 prover threads here) and a tree that predates the
  rebase re-measure — not directly comparable; the 3090 GPU number is the one that matters.
