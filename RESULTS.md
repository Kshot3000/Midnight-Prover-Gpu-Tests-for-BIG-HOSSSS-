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

## 3090 numbers (will be filled as measured)

Headline — none yet. (No number goes here until it is measured on this machine in this run.)
