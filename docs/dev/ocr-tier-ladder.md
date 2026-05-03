# OCR tier ladder — coming soon

> **Status**: planned. Stable design exists in the code; this write-up is queued.

This page will cover:
- The four tiers (**T-1 Extreme NVIDIA** / **T0 Realtime** / **T1 Quality** / **T3 CPU baseline**) and how the app picks one based on probed hardware.
- How the auto-fallback chain handles missing model artifacts, missing GPU adapters, and signature failures — without ever crashing the UI.
- The cache layout under `%LOCALAPPDATA%\sc-agent\models\` and how on-disk integrity reverify works at every boot.
- Why the **CPU baseline always ships embedded** (the hard rule: the app must do something useful even with no internet, ever).

In the meantime, the architecture is documented in the [decisions log](decisions-log.md) (decisions D2 + D5) and the manifest format in [`docs/models-distribution.md`](../models-distribution.md).

Want this sooner? **[Open or upvote a Discussion](https://github.com/zimm1/sc-agent-public/discussions/categories/ideas)**.
