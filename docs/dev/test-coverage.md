# Test coverage + reliability — coming soon

> **Status**: planned. The code repo is private but the **shape** of test coverage is fair to share — useful for tool authors evaluating whether sc-agent's data formats are ones they want to depend on.

This page will cover:
- **Test counts** by category (unit, integration, acceptance, bench) — currently 338 tests passing, broken down.
- **What's actually tested vs what's just typed**: real OCR roundtrips on captured frames, signed manifest end-to-end verification, named-pipe wire format contract tests.
- **What's not tested + why**: full WGC capture loop (requires a running game), live OCR inference (requires `r_DisplayInfo 3` rendered text + a real GPU adapter — kept as a manual smoke).
- **Regression gate** for OCR latency: the 1Hz inference budget is verified by an opt-in test that runs against the embedded baseline tier on every CI pipeline.
- **Signed-manifest tampering tests**: tampered byte → throw `ManifestSignatureException`; tampered base64 sig → same; wrong pubkey → same; HTTP URL → throw schema exception. All explicit, all cheap.
- **Cross-time same-grid bearing tests** as the canary for the [coordinate model](sc-coordinate-model.md) — if these break, the whole framework's mental model is wrong, not just one bug.

In the meantime, the test files live under `tests/SCAgent.Tests.{Unit,Integration}/` in the private code repo. Counts surface in PR descriptions on every commit.

Want this sooner? **[Open or upvote a Discussion](https://github.com/zimm1/sc-agent-public/discussions/categories/ideas)**.
