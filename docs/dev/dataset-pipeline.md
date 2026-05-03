# Dataset pipeline — coming soon

> **Status**: planned. The pipeline is shipped + battle-tested; the write-up is queued.

This page will cover:
- The two-stage extraction: **physics grids** (`Data.p4k → sc-extract → unpack-socpak.ps1 → <body>.xml`) and **DataCore records** (`Game.dcb → starbreaker dcb extract`).
- The **CryEngine-specific keyword set** that finds rotation params (`planetRotationSpeed`, `planetAxis`, `planetRadius`) — and the false start that searched for astronomical names like `RotationPeriod` instead.
- Why the original "rotation params not extractable" finding was wrong, and the cross-validation against [Valalol/Star-Citizen-Navigation](https://github.com/Valalol/Star-Citizen-Navigation)'s Database.json that confirmed our extracted values match.
- The **deep walk** of the system tree (88 → 3735 containers post-fix) and the schema iterations that followed.
- The **GUID-based + name-based cross-merge** strategy for resolving the same POI appearing in multiple sources (e.g., Klescher Rehabilitation Facility entry).
- The **`crc_soc` change-detection** technique for spotting CIG-modified bodies between patches.
- The schema published as `dataset-v<sc-patch>.json` and how external tools should consume it.

In the meantime, the consumer-facing schema is in [`docs/data-format.md`](../data-format.md), and the release flow lives in `docs/operations/public-repo-release.md` (private code repo).

Want this sooner? **[Open or upvote a Discussion](https://github.com/zimm1/sc-agent-public/discussions/categories/ideas)**.
