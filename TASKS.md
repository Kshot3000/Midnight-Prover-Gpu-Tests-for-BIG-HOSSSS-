# TASKS — Midnight GPU Prover, RTX 3090

Board seeded 2026-11-21. Highest-priority open item is worked first each cycle.
Statuses: OPEN / DOING / BLOCKED / DONE.

## 1. Correctness on CUDA (3090) — OPEN
- [ ] Full test suites on `gpu + cuda`: midnight-proofs, midnight-gpu, gpu-conformance, midnight-gpu-prover.
- [ ] Golden-digest / byte-identity tests: GPU proof must be byte-identical to CPU proof with same randomness.
- [ ] Add direct differential check (same circuit, same randomness, CPU vs GPU proof bytes) if coverage is thin.
- Note: needs CUDA build (see #5 for the build step).

## 2. Decline-path behavior — OPEN
- [ ] Stub mode (gpu without cuda): all calls decline, stock path takes over.
- [ ] Oversized requests vs FIFO memory budget on 24 GB.
- [ ] Daemon absent / busy / failing → client CPU fallback.
- [ ] Declines counted; reasons sane.

## 3. Batch proving — OPEN
- [ ] prove_batch in waves sized by device memory on 24 GB.
- [ ] Compare wave sizing vs the 5090-Laptop numbers from the PR.
- [ ] Batch proofs byte-identical to solo proofs.

## 4. Benchmarks (headline deliverable) — OPEN
- [ ] rc1 bench harness, k = 21 path, cold + warm proofs, every proof checked by the stock CPU verifier.
- [ ] GPU vs CPU on THIS machine (3090 + i9-11900KF).
- [ ] Place 3090 numbers next to the PR's 5090-Laptop numbers with the hardware difference stated.
- [ ] Bench prover-par on/off.
- [ ] Raw rows (tsv/json) into bench-results/, unedited.
- BLOCKER NOTE: GPU is currently serving an LLM workload (llama-server) — measured runs deferred until the GPU is free. Check `nvidia-smi` first; never kill another process.

## 5. Ampere-specific breakage / build on sm_86 — OPEN (current focus)
- [ ] Build in WSL2 `octanode` (GPU passthrough confirmed; Linux path = what the PR's
      build.rs targets). CUDA toolkit + rust 1.90.0 install running via `wsl-setup.sh`.
- [ ] Stock build, no features — full test suite (known-good floor).
- [ ] gpu feature WITHOUT cuda (stub declines everything) — tests pass, proofs byte-identical to stock.
- [ ] gpu + cuda on the 3090 — the real build. Likely friction: sppark patches, sm_86 codegen,
      CUDA version.
- [x] Windows-native build path: REPRODUCED AS INFEASIBLE this cycle — `gpu/build.rs` is
      Linux-shaped (ar/-rpath/stdc++/x86_64-linux), and Windows lacks MSVC/CUDA (UAC blocks
      install). Documented in STATE.md; a portable build.rs is a separate candidate PR if the
      3090 work surfaces Windows-specific breakage worth fixing upstream.

## 6. Daemon endurance — OPEN
- [ ] Leave midnight-gpu-prover running across cycles.
- [ ] Log restart-cap behavior, lease behavior, any hang/leak over long uptimes.
- Needs the CUDA build first.

## 7. Spec conformance — OPEN
- [ ] Quint-trace / Lean-oracle conformance replay (gpu-conformance).
- [ ] Pass/fail vs pinned trace count: 1,078 traces, 40,473 transitions.
- [ ] Map any failure to its GPU-0xx requirement ID.
