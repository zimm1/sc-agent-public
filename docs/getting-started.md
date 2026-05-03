# Getting started

This is the friendly tour for users who have never installed a Windows app from outside the Microsoft Store before. If you're an experienced user, jump to the [README](../README.md#getting-started).

## What you'll need

- **Star Citizen installed and working** — sc-agent reads from the in-game debug overlay; the game itself does the heavy lifting.
- **Windows 10 (build 19041 / 20H1) or newer** — Windows 11 also fine.
- **A few minutes** — first install, downloads, and the in-game enable step.
- **No account / no signup** — the app does not require login anywhere.

## Step 1 — Download

1. Open the [latest release page](https://github.com/zimm1/sc-agent-public/releases/latest).
2. Scroll to **Assets**.
3. Click `sc-agent-setup-vX.Y.Z.msix` (or `.exe` if `.msix` doesn't work for you).
4. Save the file. Don't open it from inside your browser's download bar — go to your Downloads folder.

> ❓ **What's MSIX?** It's the modern Windows app installer format. Same idea as `.exe` setup but cleaner — Windows treats it like any other Store app for install + uninstall + sandboxing.

## Step 2 — Install

1. Double-click the file you downloaded.
2. Windows will likely show a blue **Microsoft Defender SmartScreen** warning saying *"Windows protected your PC"*.
   - This warning shows for any new app from a developer the SmartScreen system hasn't seen many users of yet. It's not a virus alarm.
   - Click **More info** → **Run anyway**.
3. The Windows app installer opens. Click **Install**.
4. After install, the app is in your Start Menu — search "sc-agent" to find it.

> ❓ **Will I get a UAC prompt?** No. MSIX runs in a per-user sandbox; no admin rights needed.

## Step 3 — First launch

When you launch sc-agent for the first time:

1. The app shows a welcome splash explaining what it does.
2. It asks if you want to enable **automatic updates** (recommended) and whether to use a higher-quality OCR engine if you have a recent NVIDIA/AMD GPU.
3. The app sets up its tray icon (the small icon next to your clock) and minimizes — there's no main window.

> 🎮 **Where's the main window?** sc-agent is a tray app. Right-click the tray icon to access **Settings**, **Library** (saved POIs), and **Quit**. The actual UI shows up *over* Star Citizen as an overlay while the game is running.

## Step 4 — Enable the debug overlay in Star Citizen

sc-agent reads your position from a built-in CIG debug overlay. You need to enable it once per session:

1. Launch Star Citizen.
2. Once you're in your hangar / cockpit, press <kbd>~</kbd> (the tilde key, top-left of your keyboard).
3. The console appears. Type:
   ```
   r_DisplayInfo 3
   ```
4. Press <kbd>Enter</kbd>. The debug overlay appears in the top-left of the screen — lots of numbers about FPS, position, etc. **This is normal.** sc-agent reads this overlay.
5. Press <kbd>~</kbd> again to close the console. Continue playing as usual; the overlay stays on for the session.

> 🔁 **Do I have to do this every time I launch SC?** Yes — Star Citizen resets it every session. The app will remind you with a tray notification if it detects the overlay is missing.

## Step 5 — Save your first POI

1. Fly anywhere. Hover over an interesting spot (a derelict ship, a cave entrance, a nice viewpoint).
2. Press <kbd>F7</kbd>. sc-agent calibrates for ~1 second (the app reads multiple OCR samples to get a stable position) then shows a brief toast: *"Saved POI at hurston/lorville-...".
3. Open the **Library** from the tray menu to see your saved POIs.

## Step 6 — Navigate to a POI

1. In the tray menu, open **Library**.
2. Click a POI to select it as your current target.
3. In game, the bracket overlay (a square with the POI name + distance) appears, pointing at the target.
4. <kbd>F8</kbd> cycles through your saved POIs while in-flight (no need to alt-tab).

## Common issues

### "I don't see the bracket overlay in game"

- Check the tray icon is green (not red/yellow). Hover for status detail.
- Make sure Star Citizen is running and not minimized.
- The overlay only appears when you have a target selected. Open Library and click one.

### "OCR isn't picking up my position"

- Verify the debug overlay is on (`r_DisplayInfo 3`).
- Check the overlay is not partially covered by other UI (mobiglass, mission menu).
- Try a different OCR tier in Settings → OCR Engine. Some hardware does better on **Quality** than **Realtime**.

### "The hotkey conflicts with something"

- Settings → Hotkeys → pick a different combination.

## What's next

- **Explore the Library** — sort, search, organize your POIs into custom collections.
- **Read [Privacy](privacy.md)** if you want to understand exactly what the app sends to GitHub vs. doesn't.
- **Found a bug? Have an idea?** [Open an issue](https://github.com/zimm1/sc-agent-public/issues/new). Maintainer is one person and reads everything.
