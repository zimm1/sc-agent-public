# Bench numbers — coming after first real run

> **Status**: pending. The bench harness is built (Unit 7 of the GPU OCR tier ladder plan), but a full reference run requires the maintainer to close Star Citizen, set the env flag, and run for ~10 minutes uninterrupted. Numbers go here as soon as that lands.

This page will cover:
- **Cold-start latency** (session create + first inference) per tier on reference hardware (RTX 3080, AMD Radeon iGPU, CPU-only).
- **Warm-path latency** distributions: p50, p95, p99 across 1000 inference samples per tier.
- **End-to-end OCR latency** (capture → detector → recognizer → parsed fields) under realistic ROI sizes (~720×1280 pixels).
- **Power + thermal context** for laptops on battery (when running an OCR tier higher than your hardware needs is a worse experience than the lower tier).
- A **reproducibility recipe**: env flag + filter + expected output, so anyone with the private code repo can verify on their own hardware.

The bench harness lives at `tests/SCAgent.Tests.Integration/Acceptance/TierLadderBenchHarness.cs` (private repo), opt-in via `$env:SCAGENT_BENCH=1`, output in JSON form so this page can be auto-generated from it.

> **Preview**: the [DirectML.dll trap war story](dml-system32-trap.md) shows a few numbers from the post-fix sanity check (RTX 3080 first inference: 498 ms ALL-optimization; AMD APU: 81 ms — yes really). Those are 64×64 dummy ROI numbers, not real OCR. The real numbers will be on this page.

Want this sooner? **[Open or upvote a Discussion](https://github.com/zimm1/sc-agent-public/discussions/categories/ideas)** — and remember the maintainer needs to be willing to close Star Citizen for ~10 min, which is the actual schedule constraint.
