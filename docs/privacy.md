# Privacy disclosure

sc-agent is a local Windows tool. It does not phone home with your activity, and it does not require an account. The only network traffic the app generates is documented below, all from public GitHub URLs.

## Network traffic the app does

### 1. Dataset + models download (always)

On first run and periodically thereafter, the app fetches:
- `https://github.com/zimm1/sc-agent-public/releases/latest/download/dataset.json`
- `https://github.com/zimm1/sc-agent-public/releases/latest/download/models-manifest.json`
- Per-tier model artifacts as listed in the manifest

GitHub's public Release CDN sees your IP address as part of standard infrastructure logging. **No sc-agent server sees this**; this is between you and GitHub.

You can disable auto-fetch in Settings → Updates → "Check for dataset/models updates automatically", but you'll lose access to newer SC patch data + improved OCR.

### 2. App update check (default on, opt-out)

The app periodically checks `https://api.github.com/repos/zimm1/sc-agent-public/releases/latest` to see if a newer app version is published. Same GitHub-CDN-only traffic.

Disable: Settings → Updates → "Check for app updates automatically".

### 3. Phase data contribution (opt-in, off by default)

When enabled, the app accumulates rotation phase observations locally and shows a periodic banner: *"Submit phase data?"* On click:
- Opens a GitHub issue with a prefilled JSON snippet.
- Nothing is sent until you click **Submit** in your browser.

What the JSON contains: body code, phase angle, uncertainty, observation count, app version, day-precision timestamp.

What it does **not** contain: username, machine name, install path, game session details.

Preview before opting in: Settings → Privacy → "Preview phase contribution".

### 4. Crash reports (opt-in per submission)

When the app crashes, you get a dialog asking whether to report it. On click:
- The app builds a redacted log tail (PII-scrubbed by `PiiAnonymizer` — usernames, paths, IPs, MAC addresses removed).
- Opens a prefilled GitHub issue in your browser.
- You review it, edit if needed, click **Submit**.

Nothing is sent automatically — you're always in the loop.

## Network traffic the app does **not** do

- ❌ No telemetry / usage analytics.
- ❌ No third-party services (no Sentry, no Datadog, no PostHog, no Google Analytics, etc.).
- ❌ No phone-home with player position, game state, save POI data.
- ❌ No real-time syncing of any kind.

If you're on a metered connection or strict firewall, the app degrades gracefully: it falls back to the embedded baseline OCR model + the dataset bundled in the installer. You miss out on updates but the app keeps working.

## Local data the app stores

Under `%LOCALAPPDATA%\sc-agent\`:
- `settings.json` — your preferences (hotkeys, display options).
- `pois.db` (SQLite) — your saved POIs.
- `models\` — downloaded OCR models + manifest snapshot.
- `logs\*.log` — daily rolling log files (7-day retention by default).
- `crashes\*.dmp` — minidumps if the app crashes (auto-cleaned > 30 days).

You can wipe everything by deleting `%LOCALAPPDATA%\sc-agent\`. The app will reinitialize on next start.

## Game-side compliance

sc-agent is read-only with respect to Star Citizen:
- ✅ Window screen capture (Windows Graphics Capture API) — same APIs as OBS, screen recorders, accessibility tools. CIG's anti-cheat (Easy Anti-Cheat) is fine with this.
- ✅ Reading text from the rendered debug overlay via OCR.
- ❌ No DLL injection, no API hooking, no memory reading, no file-system tampering of game state.
- ❌ No synthetic input (no programmatic key presses or mouse clicks).

This posture is documented in [`docs/eac-posture.md`](eac-posture.md) (private repo).

## Questions / corrections

If you spot a privacy claim that's not accurate, or if you want to ask about something specific, [open an issue](https://github.com/zimm1/sc-agent-public/issues/new) — the maintainer reads every one.
