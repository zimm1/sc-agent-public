# phase/

Per-body rotation phase angles for Star Citizen celestial bodies — community-calibrated over time by sc-agent users (opt-in submissions).

Why this exists: rotation period and rotation axis come from the game files (and live in the dataset bundle). Rotation **phase at epoch** does not — it is server-side state that only manifests at runtime. The 2020 community baseline (Murphy / Valalol) covers 15/38 bodies; the rest accumulate as sc-agent users contribute observations.

For the schema + calibration mechanism + submission flows, see [`/docs/phase-data.md`](../docs/phase-data.md).

**Status**: no per-body phase JSONs committed yet. The 2020 baseline ships inside `dataset-v<patch>.json`; per-body files start landing once the v0.0.2 app version's calibration feature ships and contributors submit observations.
