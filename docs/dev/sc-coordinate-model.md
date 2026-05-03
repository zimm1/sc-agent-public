# Star Citizen's coordinate model

The mental model every navigation tool author should have. Mostly accurate as of Star Citizen 4.x (the model is unlikely to change, but specifics like body lists do).

> **TL;DR**: Star Citizen organizes the universe as **physics grids** (Object Containers in CIG terminology). Every player at every moment is either inside a grid or in deep space. Coordinates inside a rotating grid are in the **body-fixed-rotating** frame — they don't change while you stand still, even though the body is rotating. This is the single fact that makes navigation math simple in the common case.

## Two kinds of grids

A "grid" is CIG's term for a chunk of physics simulation around an Object Container — typically a celestial body, a station, a jump point, or a vehicle.

| Grid kind | Examples | Rotates? | What happens to coords if you stand still |
|---|---|---|---|
| **Rotating** | Hurston, ArcCorp, microTech, Daymar, Yela, Aberdeen, ... | Yes (around its own axis) | Local coords **stay constant**; global coords **change** because the grid is moving relative to the universe |
| **Non-rotating** | CRU-L1, HUR-L1..L5, ARC-L1..L5, MIC-L1..L5 stations, jump points, asteroid bases | No (relatively) | Local coords stay constant; global coords drift slowly (the Lagrange point itself orbits) |
| **Vehicle** | Your ship | Yes (with the ship) | Player's local coords ≈ pilot seat position |
| **Deep space** (no grid) | Between bodies, far from any L-station | n/a | Only global coords exist |

## The four cases for "where am I?"

| Case | Local coords | Global coords | Rotation correction needed? |
|---|---|---|---|
| **A.** Stationary, inside a rotating grid (parked at Lorville) | Yes (body-fixed-rotating frame) | Yes (universe-root frame) | **No** for same-grid bearing; yes for cross-grid |
| **B.** Stationary, inside a non-rotating grid (docked at HUR-L1) | Yes (grid-fixed) | Yes | No (ignore L-point orbit on short timescales) |
| **C.** Stationary, deep space | None | Yes | No (no grid to rotate) |
| **D.** Moving | Whichever applies + delta | Always changes | Trivial — math just follows position |

## The debug overlay maps to this directly

When you turn on `r_DisplayInfo 3`, the four lines you see correspond to four different reference frames:

```
Riga 2: Zone: AEGIS Sabre 6734515176839    Pos: -0.06 m  11.03 m  0.04 m
        └────────────────────────────────  └─────────────────────────
        Vehicle is itself a grid.          Local pos (player ↔ vehicle)

Riga 3: Zone: OOC Stanton 1 Hurston       Pos: -505.04158 km  -563.32894 km  493.1173 km
        └───────────────────────────────  └─────────────────────────────────────────
        Hurston physics grid (rotating).  Local pos in body-fixed-rotating frame.

Riga 4: Zone: SolarSystem 6441594527612   Pos: 12851318.5381 km  -573.5604 km  493.1173 km
        └─────────────────────────────    └────────────────────────────────────────
        Stanton system frame.             Player position in system-center frame.

Riga 5: Zone: Root                        Pos: 12851318.5381 km  -573.5604 km  493.1173 km
        └────────────────                 └────────────────────────────────────────────
        Universe-root global frame.       Player position in absolute global frame.
```

When you're in deep space, Riga 3 disappears (no body grid). Riga 4 and 5 stay.

In v0.0.1 of Star Citizen, all bodies are in the Stanton system, so Riga 4 ≈ Riga 5. Once Pyro coexists, Riga 4 becomes meaningfully distinct.

## The "stand still on Hurston for 6 hours" thought experiment

Park your ship on Hurston's surface, alt-tab out, come back six hours later (Hurston rotates fully every ~2.48 hours). The body has done about 2.4 full rotations under you. What happens to the four overlay lines?

- **Riga 2** (vehicle): unchanged, you didn't move relative to your ship.
- **Riga 3** (Hurston-local): **unchanged** — same `(-505 km, -563 km, 493 km)` you saw 6 hours ago. The local frame rotates with the body.
- **Riga 4** (system frame): **changed dramatically** — Hurston has moved ~2.4 rotations through Stanton's reference frame.
- **Riga 5** (universe root): same as Riga 4 in v0.0.1 (Stanton-only).

This is the single most important property for sc-agent. **Saving a POI on Hurston's surface and returning later "just works"** in body-local coordinates. No rotation-correction math is needed for the common case.

## When does rotation matter?

Only for **cross-grid bearings** — the player is in grid X, the POI is in grid Y, and you need a vector pointing from one to the other.

Examples:
- POI on Hurston's surface, player in deep space → "where's my saved cave from over here?"
- POI in CRU-L1 station, player on microTech → "bearing to that station I marked"
- POI in deep space, player on Hurston → "bearing back to that floating wreck"

For all of these, both POI and player need to be brought to a common reference frame **at the current moment in time**. That's where rotation period + rotation axis + rotation phase enter the math.

## The math (single rule)

```
bearing(player, target):
    if player.grid == target.grid:
        Δ = target.local - player.local            # body-local frame
        project Δ to camera frame using player.cam_dir
        → yaw_delta, pitch_delta, distance, screen_xy
    else:
        target.global_at_T = grid_transform(target.grid, target.local, T_now)
        player.global = player.universe_root_pos   # already global, from Riga 5
        Δ = target.global_at_T - player.global
        project Δ to camera frame
```

`grid_transform(grid, local_pos, T)`:
- For **non-rotating grids**: `grid.universe_root_pos + local_pos` (just an offset).
- For **rotating grids**: `grid.universe_root_pos + R(rotation_axis, θ_at_T) · local_pos` where `θ_at_T = (rotation_rate · (T − T_epoch) + phase_at_epoch) mod 360°`.

`grid.universe_root_pos` is **constant** in CIG's model — bodies are static in the system frame (`stantonsystem.xml` sets every body's parent rotation to identity, and every body's `Orbital Speed=0` in DataCore). The body's orbital position doesn't drift; what drifts is its rotational angle.

`rotation_rate` and `rotation_axis` come from the game files (`<body>.xml → <ExposedEntities>`). `phase_at_epoch` doesn't — see [`rotation-phase-story.md`](rotation-phase-story.md) for that one.

## What this implies for tool authors

If you're writing your own tool that consumes the sc-agent dataset (or wants to interoperate):

1. **Store POIs in body-local coordinates plus a grid identifier.** Don't normalize to universe-root at save time — you'll lose the convenient "POI follows the body" property.
2. **Same-grid bearings need no rotation math.** Just subtract local positions; project to camera frame; done.
3. **Cross-grid bearings need rotation, but body positions are static** — you don't need a Keplerian orbital simulator. You need rotation period + axis + phase + the timestamp the player is asking the question at.
4. **Capture timestamps must come from the OCR sample time**, not the wall clock at the moment your code computes the answer. (sc-agent learned this the hard way — see decision D-stamp in the decisions log.)
5. **Deep space is its own pseudo-container.** Don't treat "no grid" as "uninitialized state" — players save POIs in deep space all the time (derelicts, chase encounters).

## What's not in the model (what we still don't know)

- **Rotation phase at epoch** is server-side state. CIG ships rate + axis but not phase. See [`rotation-phase-story.md`](rotation-phase-story.md).
- **Lagrange station orbital model** — empirically the L-stations co-orbit their host body's L-point with the body's orbital period (textbook three-body problem). We assume textbook holds; not yet stress-tested cross-time.
- **Cross-system jump-point math** — Stanton ↔ Pyro coexistence is on the horizon. The current model assumes one system; once we have two, "universe-root" becomes meaningfully distinct from "system-frame" and bearings across systems need a galactic-frame transform.
- **Dynamic-grid attaching** (when you board a player ship that's in flight) — multi-level grid composition isn't currently handled by sc-agent. Player on a moving ship inside Hurston's grid is two layers of rotation. Out of scope for v0.0.1.

---

## Validation checklist if you're writing similar code

- [ ] Are you treating Riga 3 as body-fixed-rotating? *(correct)*
- [ ] Are you treating Riga 5 as universe-root global? *(correct)*
- [ ] Did you assume local coords "rotate out from under" a stationary player? *(WRONG — they don't)*
- [ ] Did you write rotation correction for cross-time same-grid scenarios? *(UNNECESSARY — remove)*
- [ ] Did you handle Riga 3 disappearing in deep space? *(must)*
- [ ] Did you treat non-rotating grids (Lagrange) as "rotation period 0"? *(works, but easier to special-case in your code)*
- [ ] Are you using the OCR capture timestamp, not wall clock, for any time-sensitive math? *(must)*

## Where to read more

- [`rotation-phase-story.md`](rotation-phase-story.md) — the phase-at-epoch story.
- [`dataset-pipeline.md`](dataset-pipeline.md) — how rotation period + axis + grid hierarchy get extracted into the dataset.
- The original (private) reference doc this is adapted from — pinned in [Discussions](https://github.com/zimm1/sc-agent-public/discussions) periodically; ask in the channel if you want a copy.
