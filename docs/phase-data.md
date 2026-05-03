# Rotation phase data

**Phase data** = the rotational angle of each celestial body in Star Citizen at a known reference time (the "epoch"). Combined with the rotation period and rotation axis (both extractable from game files), it lets sc-agent compute the body's current orientation in the system frame, which is what's needed to translate body-local coordinates to system-level coordinates and back.

## Why it's here

CIG ships rotation period + axis in `<body>.xml` `<ExposedEntities>` for all rotating bodies. **Rotation phase at any reference epoch is not in any game file** — neither in `Data.p4k`, `Game.dcb`, nor any `.soc` archive. It's server-side state that only manifests at runtime.

For `sc-agent v0.0.1`, phase was bootstrapped from a 2020 community measurement set (Murphy Exploration Group → Valalol/Star-Citizen-Navigation). Coverage: 15/38 rotating bodies.

For `v0.0.2+`, the sc-agent app **measures phase live** via the OCR pipeline whenever the player is stationary on a rotating body's grid (see [Calibration mechanism](#calibration-mechanism) below). Measurements accumulate over time, the maintainer aggregates them into periodic phase data updates, and they're republished here for everyone.

## Layout

```
phase/
├── README.md                      ← schema + how the data is updated
├── manifest.json                  ← list of all bodies + last update timestamp
├── stanton/
│   ├── stanton1.json              ← Hurston
│   ├── stanton1a.json             ← Arial (Hurston moon)
│   └── ...
├── pyro/
│   ├── pyro1.json
│   └── ...
└── ...
```

One JSON per body; system-level subdirectory for navigability. The full set is also bundled into the `dataset-v<patch>.json` Release artifact under each container's `rotation_phase_at_epoch_<year>_deg` field, so the app does not need to fetch `phase/*` separately at startup. This directory is the **canonical, human-browsable** view.

## Per-body schema

```json
{
  "system_code": "stanton",
  "body_code": "stanton1",
  "display_name": "Hurston",

  "rotation_period_hours": 2.48,
  "rotation_axis": [0, 0, 1],

  "epoch_utc": "2020-01-01T00:00:00Z",
  "phase_at_epoch_deg": 19.39,
  "phase_uncertainty_deg": 0.45,

  "last_calibrated_utc": "2026-05-03T14:23:00Z",
  "observation_count": 47,
  "calibration_method": "ocr-stationary",
  "calibration_source": "community-aggregate-v0.0.2",
  "schema_version": 1
}
```

Field-by-field:

| Field | Meaning |
|---|---|
| `system_code` / `body_code` | Stable identifiers matching the universe dataset's container codes. |
| `display_name` | Human-readable name (matches the dataset). |
| `rotation_period_hours` | Sidereal rotation period, copied verbatim from the dataset for convenience. |
| `rotation_axis` | Unit vector in system-frame coordinates, copied verbatim. Always `[0, 0, 1]` for known SC bodies (uniform Z-up). |
| `epoch_utc` | Reference time the phase angle is measured at. Originally 2020-01-01T00:00:00Z (community baseline); periodically rebased on CIG world-clock corrections. |
| `phase_at_epoch_deg` | Rotational angle at `epoch_utc`, in degrees, around the rotation axis. Convention: positive = counterclockwise viewed from `+axis`. |
| `phase_uncertainty_deg` | 1σ standard deviation across contributing observations. Lower = better-converged. |
| `last_calibrated_utc` | When the published value was last updated (maintainer aggregation timestamp, not individual observation time). |
| `observation_count` | How many independent observations contributed to the published value. |
| `calibration_method` | One of `community-2020-baseline`, `ocr-stationary`, `ocr-multiframe-converged`, `maintainer-measurement`. |
| `calibration_source` | Free-form provenance string (e.g., `community-aggregate-v0.0.2`, `valalol-2020`, `maintainer-2026-05-03`). |
| `schema_version` | This file's schema version (currently `1`). |

## Calibration mechanism (sc-agent v0.0.2+)

When the player is stationary on a rotating body's grid for ≥ N seconds (so OCR readings are stable), the app:

1. Captures the player's local-frame position (`Pos:` line of the debug overlay).
2. Captures the player's system-frame position (root container, debug overlay).
3. Reads the body's known `system_pos_m`, `rotation_period_hours`, `rotation_axis` from the dataset.
4. Solves for the rotational offset that aligns the body-local frame to the observed system-frame coordinates at the OCR sample time.
5. Back-solves to phase-at-epoch using the rotation period.

The math is a single rotation around `rotation_axis`, so a few stationary samples converge fast. Outliers (player drift, OCR noise) are rejected; uncertainty is reported.

## Submission flow (proposed — the maintainer decides finalization)

The app needs a way to send its observations to this repo. **Three candidate flows**, ordered from simplest to most automated:

### Option A — Manual submission (v0.0.2 default, recommended start)

When the app has accumulated ≥ M observations or a body's uncertainty drops below a threshold, it shows a banner: *"Phase data ready to share — review and submit?"*

User clicks → sc-agent:
- Builds a JSON snippet (one entry per body).
- Copies it to clipboard.
- Opens a prefilled GitHub issue on `sc-agent-public/issues/new?template=phase-contribution` with the JSON in the body.
- User clicks **Submit**.

Maintainer reviews + merges into `phase/` periodically. **Zero auth, zero infra, zero hidden network traffic.**

### Option B — Direct PR via user's GitHub account

User logs in to GitHub once via a fine-grained PAT (scoped to their fork only). App opens a PR against `sc-agent-public/` with the new phase data committed to a fork.

Trade-off: lower friction per submission, but requires user to understand PATs.

### Option C — Edge function aggregator

A tiny Cloudflare Worker (or equivalent) accepts HTTPS POSTs from the app, deduplicates + sanity-checks, commits to `sc-agent-public/contributions/raw/` via a GitHub App credential.

Trade-off: zero friction for users, requires maintainer to operate infrastructure.

**v0.0.2 ships with Option A.** Option B is opt-in for power users. Option C is on the long-term roadmap.

## Privacy

What the app sends per submission:
- Body code (e.g., `stanton1`)
- Phase angle in degrees + uncertainty
- Number of OCR samples that contributed
- App version that took the measurement
- Coarse timestamp (rounded to the day)

What the app **does not** send:
- Username, machine name, install path
- Game session details (where the player flew, what they did)
- IP-identifying info beyond what GitHub itself logs on the click-through

User can preview the exact JSON the app would send before opting in (Settings → Privacy → Preview submission).

## Contribution license

By submitting phase data via any of the flows above, the contributor agrees to release the measurement under MIT, joining the rest of the dataset corpus. Phase angles are facts about the simulated universe, not creative works — there's no copyright concern. Attribution to contributors is captured in `manifest.json` (opt-in, default off).
