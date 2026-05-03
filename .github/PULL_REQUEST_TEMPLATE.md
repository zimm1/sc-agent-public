<!--
  Thanks for opening a PR. Please fill in the sections below — the more
  context you give the maintainer, the faster this gets merged.
-->

## What does this PR do?

<!-- One paragraph. What changes, and why. -->

## Type of change

<!-- Pick one. Delete the rest. -->

- [ ] 🗺️ Universe data correction (POI name, coordinates, category, etc.)
- [ ] 🪐 Phase data contribution (manual; usually the app does this)
- [ ] 📚 Documentation fix (typo, broken link, unclear instruction)
- [ ] 🔄 Sync from the private code repo (maintainer only)
- [ ] 🤖 CI / workflow / scripts change

## Verification

<!-- How did you verify this is right? -->
<!-- For data corrections: in-game observation, screenshot, dataset cross-reference. -->
<!-- For docs: rendered preview, link check. -->
<!-- For CI: workflow_dispatch dry-run output. -->

## Reviewer checklist

<!-- The maintainer (or whoever reviews) ticks these before merge. -->

- [ ] Change is consistent with the [schema docs](../docs/) and existing data.
- [ ] No personal info, in-game usernames, or other PII in the diff.
- [ ] No breaking change to consumer URLs (`releases/download/dataset-latest/...`, etc.) — or breaking changes are called out + versioned.
- [ ] If the change touches `universe/`, `phase/`, or `models/`: the README stats workflow ran successfully on this branch (will trigger on push to `main`).

## Anything else worth knowing?

<!-- Optional: edge cases, follow-up TODOs, related discussion threads. -->
