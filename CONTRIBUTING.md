# Contributing to sc-agent-public

Thanks for thinking about helping! This repo accepts a few specific kinds of contributions.

## What you can contribute directly

### POI corrections (universe data)

Found a wrong POI name, a missing landing zone, or an outdated coordinate? You have two options:

**Option 1 — Open an issue (easiest):**
1. Go to [Issues](https://github.com/zimm1/sc-agent-public/issues/new).
2. Pick the **Universe data correction** template.
3. Fill in: which body / POI, what's wrong, what should it be, where you got the info.

**Option 2 — Open a pull request (faster if you're comfortable with GitHub):**
1. Find the file under `universe/` that has the wrong data.
2. Click the pencil icon (top-right of the file viewer) — GitHub creates a fork for you.
3. Edit the JSON. Keep the existing structure.
4. Click **Propose changes** at the bottom; click **Create pull request**.
5. Describe what you changed and why.

### Rotation phase observations

The app contributes phase data automatically when you opt in (Settings → Privacy → Contribute phase data). This is the preferred path — it's calibrated from real in-game readings, the app handles all the math for you, and the maintainer aggregates contributions periodically.

If you want to manually submit a measurement (for a body the app hasn't covered, or to cross-check), see [`docs/phase-data.md`](docs/phase-data.md) for the JSON schema and how to compute the angle.

### Documentation fixes

Typos, broken links, unclear instructions in any `docs/*.md`: PR welcome. No template needed for small docs fixes.

## What we don't accept here

- **Application source code** — the app code lives in a private repo. Feature ideas + bug reports go to issues here, but PRs containing C# / .NET code don't have a target.
- **Cracked / leaked CIG content** — anything from a private CIG build, leaked datacore, or pre-release patch is out of bounds. We work strictly from publicly-released game files.
- **Synthetic input automation** — anything that programmatically presses keys / clicks for the player. sc-agent is read-only by design and EAC-safe; we won't accept tools that change that posture.

## Reporting bugs in the app

Inside sc-agent: **Settings → Report a problem**. The app prefills a redacted issue form (no usernames, no machine names, no install paths) and opens it in your browser for you to review + submit.

If the app won't start at all: open an issue here manually with:
- Windows version (`winver`)
- App version (it's in the `.msix` filename you downloaded)
- What you expected vs what happened
- Any error message exactly as shown

## Ground rules

- Be civil. The maintainer is one person.
- Keep PRs small and focused — one POI correction at a time, not 50 unrelated changes in one PR.
- Don't include your real-world identity if you don't want to — a GitHub username is enough.
