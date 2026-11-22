# RESULTS — Midnight GPU Prover on RTX 3090

## Summary for Charles (reply-ready)

On an RTX 3090 (24 GB, sm_86, driver 610.60, CUDA UMD 13.3, i9-11900KF, Windows 11 + WSL2),
PR #667 head `6bcc6a56`:

1. **Byte-identity: PASSED on the real 3090.** Full GPU gate on an empty card: frozen v2
   service vectors + the complete Quint ITF replayed through the daemon adapter — 1,078 files,
   40,473 transitions, 0 mismatching steps, 0 differing field observations. All 78 gate tests
   pass (device suite, batch isolation, sanitizer, kernel skew within the 1.5 limit).
2. **k=21 performance on an empty card (16 threads):** GPU warm prove **4.370 s** (cold
   5.352 s) vs CPU warm prove **16.38 s** (cold 16.16 s) → **3.75× speed-up** (3.02× cold).
   GPU device peak **1,975.2 MB** — the same peak the 5090-Laptop reference measured, and the
   3090's GPU warm time is within 0.1% of it (4.374 s).
3. Every proof checked by the stock CPU verifier (verified=true; 0 device errors, 0
   fallbacks).

Full evidence: this file, `raw/win-d2-3090-2026-11-22.log`, and the raw rows in
`bench-results/`.

## 3090 numbers (measured on this machine)

### Bench window 2026-11-22 08:40–09:45 CST — k=21, EMPTY card (server unloaded, 23,478 MB
free at arm), head `6bcc6a56`, 16 prover threads

| mode | threads | cold prove (s) | warm prove (s) | verify (s) | verified | device errors | fallbacks | peak device |
|---|---:|---:|---:|---:|---|---:|---:|---:|
| GPU (RTX 3090) | 16 | 5.352 | **4.370** | 0.0018 | true | 0 | 0 | 1,975.2 MB |
| CPU (i9-11900KF) | 16 | 16.161 | **16.383** | 0.0020 | true | — | — | — |

Speed-up GPU vs CPU, same card, same day, same threads: **warm 3.75×** (16.383 / 4.370);
cold 3.02×. One cold + one warm proof per mode, measured in the same window (stage D3);
proving key cached from the 2026-11-21 prep (577 MB). Raw, unedited:
`bench-results/rc1-gpu-3090-k21-2026-11-22-window.tsv`,
`bench-results/rc1-cpu-3090-k21-2026-11-22-window.tsv`.

### CPU-only baseline 2026-11-21 (8 prover threads; GPU held by the LLM workload at the time)

| Date | head | Feature set | Hardware | Result | Command |
|---|---|---|---|---|---|
| 2026-11-21 | 6bcc6a56 | rc1 bench, cpu | CPU only (i9-11900KF, 8 prover threads, WSL2 16 cores); k=21 | **CPU warm prove: 26.27 s median** (mean 25.25, range 21.22–27.22, stdev 1.91; 15 warm runs, 3 repeats × 5); cold 26.79 s median (21.12–27.47); **all 18 proofs verified=true**, verify ~1.8 ms | `rc1-cpu` (bench/gpu-prover/rc1, canonical 3-rep × warm=5) |

Raw: `raw/rc1-cpu-3090-2026-11-21.tsv`. (8 threads — kept for context; the window pair above
is the like-for-like comparison.)

## Byte-identity verdict — 3090, 2026-11-22 (stage D2 of the bench window)

**Verdict: `GPU gate: passed`** (the gate's own verdict line). Evidence:
`raw/win-d2-3090-2026-11-22.log` (unedited, 12.9 KB).

- Frozen v2 service vectors + full Quint ITF through the daemon adapter: **1,078 files,
  40,473 transitions, 0 mismatching steps, 0 differing field observations** (matches the
  upstream conformance totals exactly).
- Device test suite (stage D1): all pass, exit 0.
- Batch suite (7 tests, incl. `cpu_batch_matches_alone_and_isolates_panics` and the
  cleanup-on-unwind tests): all pass. The `panicked at ...` lines in the log are the expected
  output of the panic-isolation tests — each is immediately followed by `test result: ok`.
- Sanitizer: pass. Kernel MSM skew: max 1.000 (uniform) / 1.040 (repeated), limit 1.5.
- Stage D4 (prover-par on/off A/B): SKIPPED — soft stage; the off-arm prover-par binary was
  not staged (documented in the runner log, `window.log`).

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

## Cross-machine observations (2026-11-22)

- 3090 GPU warm **4.370 s** vs 5090-Laptop GPU warm **4.374 s** — within 0.1% across a
  three-year GPU generation gap at k=21.
- Device peak is byte-identical in shape: **1,975.2 MB** on both machines (the k=21 working
  set is the same; the kernels do not reallocate).
- Speed-up differs (3.75× on the 3090 box vs 4.10× on the 5090-Laptop box) because the CPU
  sides differ (i9-11900KF 16t vs Core Ultra 9 275HX 24t) — the GPU side is the stable
  quantity.
