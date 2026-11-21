# Midnight-Prover-Gpu-Tests-for-BIG-HOSSSS-

Records for testing, fixing and benchmarking the optional CUDA prover in
midnightntwrk/midnight-zk PR #667 ("Add an optional CUDA prover behind the gpu
feature") on a desktop **NVIDIA RTX 3090 (24 GB, sm_86)**.

- `SETUP.md` — machine inventory (GPU, CUDA, CPU, RAM, OS, toolchains).
- `RESULTS.md` — the numbers table (kept current; quotable).
- `TASKS.md` — priority board.
- `STATE.md` — resume point, blockers, standing reminders.
- `LOG.md` — one heartbeat per cycle.
- `bench-results/` — raw benchmark rows (tsv/json), unedited.

Every commit records what was observed in that run: exact commands, exact
outputs, exact numbers. A number that was not measured on this machine in that
run does not appear here.
