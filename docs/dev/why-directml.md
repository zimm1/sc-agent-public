# Why DirectML and not CUDA — coming soon

> **Status**: planned. The decision is documented; this is the long version with numbers.

This page will cover:
- The three options that were on the table: **CUDA + TensorRT** (NVIDIA-only), **DirectML** (cross-vendor on Windows), **CPU EP** (universal fallback).
- The **install-friction trade-off**: CUDA's multi-gigabyte toolkit vs DirectML shipping with the OS.
- Latency numbers across the three engines on identical hardware (RTX 3080) to show what cross-vendor support actually costs.
- The **vendor-lock-in argument**: why a fan tool defaulting to NVIDIA-only would alienate ~40% of Star Citizen players.
- Why T-1 Extreme NVIDIA is **kept as opt-in** for power users who want max throughput on max hardware.

In the meantime, see [decisions log D2](decisions-log.md#d2--directml-over-cuda-for-ocr-2026-05-02) and the war story in [`dml-system32-trap.md`](dml-system32-trap.md) about what DirectML cost us in *infrastructure* (separate from latency).

Want this sooner? **[Open or upvote a Discussion](https://github.com/zimm1/sc-agent-public/discussions/categories/ideas)**.
