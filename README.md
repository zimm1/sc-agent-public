# sc-agent-dataset

Hermetic dataset companion for [sc-agent](https://github.com/zimm1/sc-agent) — a Windows navigation tool for Star Citizen pilots.

## What this repo contains

**Releases only.** No source code lives here. Each Star Citizen patch produces a tagged GitHub Release with the dataset built from that patch's `Data.p4k`.

Assets per release:

- `dataset.json` — single-file hermetic dataset (containers, rotation phase, seed POIs nested inside containers).
- `checksums.txt` — SHA-256 verification.

Release notes contain coverage stats and source attribution.

## Versioning

- Tag format: `dataset-v<sc-patch>` (es. `dataset-v4.7.2`).
- Pre-release: `dataset-v<sc-patch>-<suffix>` (es. `dataset-v4.7.2-rc1`).
- Rolling alias: `dataset-latest` always points at the most recent release.

## Consumer API

```
GET https://api.github.com/repos/zimm1/sc-agent-dataset/releases/latest
GET https://github.com/zimm1/sc-agent-dataset/releases/download/dataset-latest/dataset.json
```

## Schema

JSON Schema canonico: vedi [`tools/dataset-builder/schemas/dataset-v1.json`](https://github.com/zimm1/sc-agent/blob/main/tools/dataset-builder/schemas/dataset-v1.json) nel repo `sc-agent`.

## Attribution

- Source code (build pipeline, schema, scripts): [zimm1/sc-agent](https://github.com/zimm1/sc-agent) — private.
- Rotation phase data (community-measured): [Valalol/Star-Citizen-Navigation](https://github.com/Valalol/Star-Citizen-Navigation) (MIT) → ultimate origin Murphy Exploration Group community measurements.
- Game data (containers, body manifests, DataCore records): extracted from Star Citizen `Data.p4k` for personal navigation tooling under CIG fan content policy.

## Disclaimer

Star Citizen © Cloud Imperium Games. This project is a fan-made tool not affiliated with or endorsed by CIG.

See [CIG Fan Content Policy](https://cloudimperiumgames.com/policies/fan-content-policy).
