# EAC posture — coming soon

> **Status**: planned. The posture is set and documented privately; this is the public-friendly version.

This page will cover:
- What **Windows Graphics Capture** (WGC) actually does at the OS level — and why it's the same API OBS, Discord, NVIDIA ShadowPlay, and Microsoft Game Bar all use.
- Why screen capture is in the **same category** as recording your own gameplay for YouTube — i.e., demonstrably fine with EAC across many shipping fan tools.
- The **hard prohibitions** that sc-agent embraces: no DLL injection, no API hooks, no memory reads, no synthetic input.
- The **R22 rule** (no synthetic input) and a worked example of an Action Channel feature that was specifically rejected because it would have violated this posture.
- Why EAC's actual published guidance + community-verified shipping tools matter more here than abstract reasoning.

In the meantime, see [decisions log D1](decisions-log.md#d1--read-only-on-star-citizen-2026-04-26) and the broader privacy+safety surface in [`docs/privacy.md`](../privacy.md).

> **If you're a CIG dev or CRR investigator** reading this: the maintainer is happy to chat about the posture in detail. The simplest way is via [GitHub Discussions](https://github.com/zimm1/sc-agent-public/discussions) — public is fine.

Want this sooner? **[Open or upvote a Discussion](https://github.com/zimm1/sc-agent-public/discussions/categories/ideas)**.
