# models/

OCR neural-network artifacts (PP-OCRv4 detector + recognizer + dict) for the sc-agent app's tier ladder.

Distribution: as [GitHub Releases](https://github.com/zimm1/sc-agent-public/releases?q=models) under the `models-v<X.Y.Z>` tag pattern, with an Ed25519-signed manifest. The app downloads + verifies these automatically — power users only need to look here for diagnostic / verification purposes.

For schema + signature verification + how the app fetches them, see [`/docs/models-distribution.md`](../docs/models-distribution.md).

**Status**: no model release yet. The app currently runs an embedded baseline tier (CPU-only); models for higher tiers (T0 Realtime / T1 Quality / T-1 Extreme NVIDIA) ship with `models-v0.0.1`.
