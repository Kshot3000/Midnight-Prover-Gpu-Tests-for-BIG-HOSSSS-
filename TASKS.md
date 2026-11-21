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

## 5. Build verification on sm_86 (WSL2 `octanode`) — DOING (nearly done)
- [x] WSL build tree at PR head `6bcc6a56`; CUDA 13.0 + Rust 1.90.0 (repo-pinned) verified.
- [x] Stock build (no features): PASS 46 s.
- [x] Stock full test suite: **green, exit 0** (126 binaries) after downloading the missing
      Filecoin SRS asset (`zk_stdlib/examples/assets/bls_filecoin_2p19`, git-ignored; the first
      pass's 24 failures were all this one environment gap — PR touches neither zk_stdlib nor zkvm).
- [x] Stub build (gpu without cuda): tests pass — `midnight-gpu` default build = stub;
      conformance test passes (42 filtered = device-only).
- [x] gpu + cuda build on the 3090: **PASS in 1 m 59 s** (MIDNIGHT_GPU_REQUIRE_CUDA=1; no
      friction at build time — sppark/sm_86 issues would surface at runtime).
- [x] Windows-native build path: REPRODUCED AS INFEASIBLE — `gpu/build.rs` is Linux-shaped
      (ar/-rpath/stdc++/x86_64-linux); documented in STATE.md. Portable build.rs = separate
      candidate PR if 3090 work surfaces Windows breakage worth fixing upstream.
- [ ] Device runtime (byte-identity, conformance, bench): WAITING on GPU (llama-server 22 GB).

## 6. Daemon endurance — OPEN
- [ ] Leave midnight-gpu-prover running across cycles.
- [ ] Log restart-cap behavior, lease behavior, any hang/leak over long uptimes.
- Needs the CUDA build first.

## 7. Spec conformance — DOING (toolchain 80% ready)
- [x] node v20.20.2 (NodeSource) in WSL octanode.
- [x] Quint: package is `@informalsystems/quint` (NOT @qntm/quint — 404; `quint` 1.2.0 on npm is
      an unrelated JS-helper package). Installed @informalsystems/quint@0.32.0 (version matches the
      pinned 0.32.0 in the repo's docs); `quint typecheck quint/gpu_service.qnt` → exit 0.
- [x] Lean v4.35.0 installed via elan 4.4.0 (`elan toolchain install leanprover/lean4:v4.35.0`;
      the repo's lean-toolchain pins exactly this). elan quirk: the release tarball is the
      elan-init binary itself, and `elan toolchain install` (no args) does nothing in v4.4.0.
- [x] Lean oracle exe: `lake build --wfail` → **Build completed successfully (34 jobs)**, exit 0;
      `.lake/build/bin/oracle` 119 MB. (First attempt was a broken heredoc that emptied `$LOG`;
      re-ran cleanly. Log `~/bench/logs/oracle-build.log`.)
- [x] Quint-trace / Lean-oracle conformance replay: `scripts/quint_check.sh` → **PASS, exact
      match to upstream reference** (`formal/gpu-prover/RESULTS.md`). 20/20 instances
      `quint check` `[ok] No violation found` (10,000 fresh samples each); 34 replay sections =
      20×10,000-sample instances + 14 directed; **1,078 traces replayed, 40,473 transitions
      agreed, 0 excused, 0 violations**; 3 refusal tests + 2 negative controls
      (perturbed traces DISAGREE, perturbed start state differs — both expected);
      **initial states: 1,078 traces checked, 0 differ**. Full log:
      `project-repo/raw/conformance-2026-11-21.log` (1,092 lines).
- [x] Pass/fail vs pinned trace count: 1,078 traces, 40,473 transitions — **EXACT MATCH**.
- [x] Toolchain proven end-to-end: node 20.20.2 → Quint 0.32.0 → elan 4.4.0 → Lean 4.35.0 →
      oracle exe → conformance replay. **Task 7 complete.**
- [ ] Map any failure to its GPU-0xx requirement ID.
- [x] Frozen v2 vectors digest re-verified in WSL: `de054ca4...bffb` == hardcoded in gpu-gate.sh.
