# Sync process — private code repo → public repo

How docs, scaffolding, and (eventually) source releases flow from the private `sc-agent` repo into this public one.

> **Status**: v0 is manual + PR-reviewed. Step toward automation when sync cadence picks up.

## What gets synced

Files that live under `docs/public-repo-scaffold/` in the **private** code repo. The scaffold is the source of truth — edits happen there, sync moves them here. This is the inverse of the usual "private mirrors public" pattern, but it's what makes sense when the public-facing copy needs to track the app version it describes.

Folders synced:
- README.md, CONTRIBUTING.md, CHANGELOG.md, LICENSE
- docs/ (all of it — getting-started, data-format, models-distribution, phase-data, privacy, release-process, dev/*)
- .github/ (issue templates, PR template, CODEOWNERS, labels.yml, workflows/)
- scripts/ (update-readme-stats.ps1, etc.)

Folders NOT synced:
- The actual data (`universe/`, `phase/`, `models/`) — those have their own publish flows (see [`release-process.md`](../release-process.md)).
- Anything under `docs/dev/` that points to private-repo content — those stays as outline + "ask in Discussions" pointer.

## Manual sync flow (current)

Done by the maintainer, periodically (typically once per release of the app):

```pwsh
# From the private repo root:
$publicRepo = "<path-to-local-clone-of-sc-agent-public>"
git -C $publicRepo checkout main
git -C $publicRepo pull

git -C $publicRepo checkout -b sync/$(Get-Date -Format 'yyyy-MM-dd')

# Mirror the scaffold (excluding files we generated, never the data folders):
robocopy docs/public-repo-scaffold/ $publicRepo/ /MIR /XD universe phase models /XF .git*

cd $publicRepo
git add -A
git status   # eyeball the diff
```

If the diff looks right:

```pwsh
git commit -m "Sync from sc-agent <app-version>"
git push -u origin sync/<date>
gh pr create --title "Sync from sc-agent <version>" --body "..."
```

The PR goes through the normal [release-process](../release-process.md) review — even though it's the maintainer-syncing-from-themselves, the PR ensures CI runs on the new docs/scaffolds and the stats workflow gets a chance to refresh.

## Conflict resolution

If the public repo has accumulated edits that would be overwritten by the sync (rare but possible — e.g., a community contributor fixed a typo directly on `main`):

1. **Don't blindly overwrite.** Inspect what changed.
2. **Pull the public-side change back into the private scaffold** first. Edit `docs/public-repo-scaffold/<path>` in the private repo to match.
3. **Then re-run the sync.** Now the diff is empty for that file.

The scaffold is the source of truth — but only because the maintainer maintains that property by pulling fixes back.

## Future: GitHub Action sync

When release cadence picks up, replace the manual `robocopy` with a workflow on the **private** repo, triggered on tagged releases:

```yaml
# .github/workflows/sync-public-docs.yml (in private repo)
on:
  push:
    tags: ['v*']
jobs:
  sync:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: |
          git clone https://github.com/zimm1/sc-agent-public public-repo
          rsync -av --delete \
            --exclude='/universe' --exclude='/phase' --exclude='/models' \
            docs/public-repo-scaffold/ public-repo/
          cd public-repo
          git config user.name "sc-agent sync bot"
          git config user.email "noreply@github.com"
          git checkout -b sync/${{ github.ref_name }}
          git add -A
          git commit -m "Sync from sc-agent ${{ github.ref_name }}"
          git push origin sync/${{ github.ref_name }}
          gh pr create --title "Sync from sc-agent ${{ github.ref_name }}" \
                       --body "Auto-generated. Review the diff before merging."
        env:
          GH_TOKEN: ${{ secrets.PUBLIC_REPO_PAT }}
```

Pre-condition: a fine-grained PAT (`PUBLIC_REPO_PAT`) with `Contents: write` on `sc-agent-public` only.

The PR is still human-reviewed — the bot just opens it. Auto-merge can be added later if the maintainer trusts the diff size threshold (e.g., auto-merge if <50 lines changed and no schema files touched).

Not implemented yet. v0 manual sync is fine for the current cadence.

## Why this exists

Without an explicit sync process:
- Docs in the public repo drift out of sync with the app version they describe.
- Edits made directly on the public repo get clobbered the next time someone copies from private.
- Single-source-of-truth breaks; users see inconsistent answers across the two repos.

The scaffold + manual-sync + PR-review pattern keeps it tractable for one developer.

## What about the app source code?

For now: the app source lives only in the private repo. There's no public source release.

Future possibilities (none committed):
- Publish a tagged source bundle per release (read-only `src/` mirror).
- Open the code repo entirely once the project is mature enough.
- Stay private indefinitely — the public artifacts (data, models, docs, signed manifests) are enough for the user-facing promise.

The decision will land in [`decisions-log.md`](decisions-log.md) when it lands. For now, source PRs from the community don't have a target — but data + docs PRs do, and they land here.
