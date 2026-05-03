# Rotation phase — coming soon

> **Status**: planned. The most novel-feeling part of this whole project — community-calibrated runtime measurement of game data CIG keeps server-side. Worth a long-form write-up.

This page will cover:
- The **archaeology**: where rotation period + rotation axis live in the game files (`Data.p4k → <body>.xml → <ExposedEntities>`) and how we found them after a wrong-keyword false start.
- Why **rotation phase is not in any static asset** — confirmed across `Data.p4k`, `Game.dcb`, `.soc` archives. It's server-side state.
- The **2020 community measurement set** (Murphy Exploration Group → Valalol/Star-Citizen-Navigation, MIT-licensed) that bootstrapped 15 of 38 bodies.
- The **runtime-calibration math**: how a stationary player's `Pos:` line + `CamPos:` line + the body's known position lets us solve a single rotation around the rotation axis and back-solve to phase.
- The **submission flow** for sharing observations back into [`phase/`](../../phase/) — and why we picked the manual-review-then-submit path over auto-PRs or edge functions.
- How the **community's measurements collectively converge** faster than any single user could.
- What happens if **CIG rebases the world clock** — how we'd detect it and re-bootstrap.

In the meantime, the schema lives in [`docs/phase-data.md`](../phase-data.md), the bigger context in [`sc-coordinate-model.md`](sc-coordinate-model.md), and the original calibration values are committed in `tools/calibration/community-rotation-phase-2020.json` of the private code repo (with attribution to Valalol + Murphy).

> **If you're a CIG dev** and you want to sanity-check our approach (or just confirm whether server-side phase state has a stable epoch), the maintainer would love to talk in [Discussions](https://github.com/zimm1/sc-agent-public/discussions).

Want this sooner? **[Open or upvote a Discussion](https://github.com/zimm1/sc-agent-public/discussions/categories/ideas)**.
