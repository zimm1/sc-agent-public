# Universe data format

The `universe/` directory contains the celestial bodies + POI catalog for Star Citizen, derived from publicly-released game files. The full catalog is also published as a single bundled file via [Releases](https://github.com/zimm1/sc-agent-public/releases) (`dataset-v<patch>.json`) for the sc-agent app to consume.

## Files

```
universe/
├── README.md                            ← schema overview + lookup patterns
├── celestial-bodies-grid.csv            ← compact baseline: 95 bodies × {gridRadius, radius}
└── (per-system breakdowns, future)
```

The bundled JSON published in Releases is the single source of truth at runtime — the per-file CSV/JSON in this directory is a human-friendly view for browsing and contributions.

## Bundle (`dataset-v<patch>.json`)

Schema v=1. Top-level structure:

```json
{
  "schema_version": 1,
  "sc_patch": "4.7.2",
  "generated_utc": "2026-04-27T...",
  "systems": [
    {
      "code": "stanton",
      "containers": [
        {
          "code": "stanton1",
          "display_name": "Hurston",
          "locale_key": "@hurston_name",
          "system_pos_m": [12345.0, ...],
          "grid_radius_m": 2000000,
          "radius_m": 1200000,
          "rotation_axis": [0, 0, 1],
          "rotation_period_hours": 2.48,
          "rotation_phase_at_epoch_2020_deg": 19.39,
          "crc_soc": "abc123...",
          "pois": [
            {
              "code": "lorville",
              "display_name": "Lorville",
              "category": "landing_zone",
              "local_pos_m": [...],
              ...
            },
            ...
          ]
        },
        ...
      ]
    }
  ]
}
```

Full schema (`tools/dataset-builder/schemas/dataset-v1.json` in the private code repo) defines:
- 18 POI categories (landing_zone, mining_outpost, derelict, ugf, scramblerace, comm_array, etc.).
- POI nested in their parent container — no foreign-key linking.
- Container `system_pos_m` may be null for system-origin wrappers.
- `rotation_phase_at_epoch_2020_deg` may be null for bodies without a community measurement (Pyro/Nyx/Ellis bodies added post-2022).

## Provenance

All numeric values are derived from publicly-released CIG game files (`Data.p4k`) via the sc-agent build pipeline. The pipeline:

1. Unpacks `Data.p4k` and walks the system tree.
2. Reads container manifests (`<body>.xml`) for grid radius, sphere radius, rotation params (`planetRotationSpeed`, `planetAxis`, `planetRadius`).
3. Reads DataCore (`Game.dcb`) for QT params, landing zones, galactic positions, locale keys.
4. Resolves locale keys to display names via `global.ini`.
5. Merges seed POIs from entdata files + DataCore POI records.
6. Snapshots into `dataset-v<sc-patch>.json`.

Rotation phase at epoch 2020 (`rotation_phase_at_epoch_2020_deg`) is **not** in game files — it's bootstrapped from [Valalol/Star-Citizen-Navigation](https://github.com/Valalol/Star-Citizen-Navigation) (MIT, ultimate origin: Murphy Exploration Group community measurements). The app calibrates this value live via OCR observations and contributes back to `phase/` (see [`phase-data.md`](phase-data.md)).

## Lookup patterns

### Find a body by display name

Display name → container code:
```pwsh
$d = Get-Content dataset-v4.7.2.json -Raw | ConvertFrom-Json
$d.systems | ForEach-Object { $_.containers } | Where-Object { $_.display_name -eq "Hurston" }
```

### Find a POI by name

```pwsh
$d.systems |
  ForEach-Object { $_.containers } |
  ForEach-Object { $_.pois | Where-Object { $_.display_name -like "*Lorville*" } }
```

### List all rotating bodies

```pwsh
$d.systems |
  ForEach-Object { $_.containers } |
  Where-Object { $_.rotation_period_hours -ne $null } |
  Select-Object code, display_name, rotation_period_hours, rotation_phase_at_epoch_2020_deg
```

## License

- Schema + scripts: MIT (per the repo `LICENSE`).
- Numeric values + names sourced from Star Citizen game files: redistributed under the [CIG fan content policy](https://cloudimperiumgames.com/policies/fan-content-policy). Used non-commercially, with attribution.
