#!/usr/bin/env pwsh
<#
.SYNOPSIS
  Regenerates the AUTO:* sections in README.md from on-disk content + GH
  Releases metadata. Safe to run repeatedly — idempotent on unchanged content.

.DESCRIPTION
  Replaces content between markers `<!-- AUTO:section -->` and
  `<!-- /AUTO:section -->`. Sections produced:

  - AUTO:stats   — 3-column table: universe count, models count, phase count.
  - AUTO:status  — single-line latest-publish summary.

  Sources (best-effort, all optional):
  - GH Releases  — latest dataset / models tag (via gh CLI; works in CI with
                   GITHUB_TOKEN env, or locally if `gh auth` is set up).
  - universe/    — fallback CSV count if GH Release fetch fails.
  - phase/       — counts per-body JSON files calibrated vs awaiting.
  - models/      — counts manifest entries if a manifest is committed.

.PARAMETER ReadmePath
  Path to README.md. Default: ./README.md (run from repo root).

.PARAMETER DryRun
  Print the regenerated README to stdout instead of writing it back.
#>
param(
  [string]$ReadmePath = 'README.md',
  [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

if (-not (Test-Path $ReadmePath)) {
  Write-Error "README not found at: $ReadmePath"
  exit 1
}

# --- 1. Universe stats -----------------------------------------------------

function Get-UniverseStats {
  $stats = [ordered]@{
    Systems    = '?'
    Containers = '?'
    POIs       = '?'
    Patch      = 'unknown'
    Source     = 'no data'
  }

  if (Get-Command gh -ErrorAction SilentlyContinue) {
    try {
      $tmp = Join-Path ([IO.Path]::GetTempPath()) ("dataset-" + [Guid]::NewGuid() + ".json")
      gh release download dataset-latest --pattern 'dataset.json' --output $tmp 2>$null
      if (Test-Path $tmp) {
        $d = Get-Content $tmp -Raw | ConvertFrom-Json
        $containers = @($d.systems | ForEach-Object { $_.containers })
        $pois = @($containers | ForEach-Object { $_.pois })
        $stats.Systems    = @($d.systems).Count
        $stats.Containers = $containers.Count
        $stats.POIs       = $pois.Count
        $stats.Patch      = $d.sc_patch
        $stats.Source     = "Release dataset-v$($d.sc_patch)"
        Remove-Item $tmp -Force -ErrorAction SilentlyContinue
        return $stats
      }
    } catch {
      Write-Warning "Could not fetch dataset-latest: $_"
    }
  }

  if (Test-Path 'universe') {
    $csv = Join-Path 'universe' 'celestial-bodies-grid.csv'
    if (Test-Path $csv) {
      $lines = (Get-Content $csv | Where-Object { $_ -notmatch '^\s*#' -and $_.Trim() }).Count
      $stats.Containers = [Math]::Max(0, $lines - 1)
      $stats.Source     = 'committed CSV'
    }
  }
  return $stats
}

# --- 2. Models stats -------------------------------------------------------

function Get-ModelsStats {
  $stats = [ordered]@{
    Tiers      = '?'
    LatestTag  = 'pending'
    Source     = 'no data'
  }

  if (Get-Command gh -ErrorAction SilentlyContinue) {
    try {
      $releases = gh release list --json tagName,publishedAt --limit 50 |
        ConvertFrom-Json |
        Where-Object { $_.tagName -like 'models-v*' } |
        Sort-Object -Property publishedAt -Descending
      if ($releases) {
        $stats.LatestTag = $releases[0].tagName
        $stats.Source    = "Release $($releases[0].tagName)"
      }
    } catch {}
  }

  $manifest = Join-Path 'models' 'manifest.json'
  if (Test-Path $manifest) {
    try {
      $m = Get-Content $manifest -Raw | ConvertFrom-Json
      $stats.Tiers = @($m.tiers.PSObject.Properties.Name).Count
    } catch {}
  }
  return $stats
}

# --- 3. Phase stats --------------------------------------------------------

function Get-PhaseStats {
  $stats = [ordered]@{
    Calibrated = 0
    Awaiting   = 0
    Total      = 0
    Source     = 'no data'
  }
  if (-not (Test-Path 'phase')) { return $stats }

  $files = Get-ChildItem -Path 'phase' -Filter '*.json' -Recurse -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -ne 'manifest.json' }
  $stats.Total = $files.Count

  foreach ($f in $files) {
    try {
      $j = Get-Content $f.FullName -Raw | ConvertFrom-Json
      if ($null -ne $j.phase_at_epoch_deg -and $j.observation_count -gt 0) {
        $stats.Calibrated++
      } else {
        $stats.Awaiting++
      }
    } catch {
      $stats.Awaiting++
    }
  }
  if ($stats.Total -gt 0) { $stats.Source = "$($stats.Total) per-body files" }
  return $stats
}

# --- Render the AUTO sections ----------------------------------------------

$universe = Get-UniverseStats
$models   = Get-ModelsStats
$phase    = Get-PhaseStats
$now      = [DateTime]::UtcNow.ToString('yyyy-MM-dd')

$universeCell = if ($universe.Systems -ne '?') {
  "**$($universe.Containers)** bodies and stations<br>**$($universe.POIs)** points of interest<br>across **$($universe.Systems)** systems<br>_$($universe.Source)_"
} else {
  '_dataset not yet published_'
}

$modelsCell = if ($models.LatestTag -ne 'pending') {
  $tiersLine = if ($models.Tiers -ne '?') { "$($models.Tiers) tiers in manifest" } else { 'see release for details' }
  "**Latest:** $($models.LatestTag)<br>$tiersLine<br>_$($models.Source)_"
} else {
  '_no model release yet — app uses embedded baseline_'
}

$phaseCell = if ($phase.Total -gt 0) {
  "**$($phase.Calibrated)** bodies calibrated<br>**$($phase.Awaiting)** awaiting community data<br>($($phase.Total) bodies tracked)"
} else {
  '_no phase files committed yet — bootstrapped from dataset_'
}

$statsBlock = @"
<!-- AUTO:stats -->
<!-- Auto-generated $now UTC by .github/workflows/update-stats.yml.
     Edit scripts/update-readme-stats.ps1 to change what goes here. -->

| 📍 Universe data | 🤖 OCR models | 🪐 Rotation phase |
|---|---|---|
| $universeCell | $modelsCell | $phaseCell |

<!-- /AUTO:stats -->
"@

$statusLine = if ($universe.Patch -ne 'unknown') {
  "_Last data publish: dataset-v$($universe.Patch) — $now (auto-stamped)._"
} else {
  '_Last data publish: pending first release._'
}
$statusBlock = @"
<!-- AUTO:status -->
$statusLine
<!-- /AUTO:status -->
"@

# --- Replace markers in README ---------------------------------------------

function Replace-Section {
  param(
    [string]$Text,
    [string]$Marker,
    [string]$Replacement
  )
  $pattern = "(?s)<!--\s*AUTO:$Marker\s*-->.*?<!--\s*/AUTO:$Marker\s*-->"
  if ($Text -notmatch $pattern) {
    Write-Warning "AUTO:$Marker block not found in README — skipping."
    return $Text
  }
  # Use a MatchEvaluator so '$' in the replacement is treated as literal,
  # not as a backreference.
  $rx = [regex]::new($pattern, [System.Text.RegularExpressions.RegexOptions]::Singleline)
  return $rx.Replace($Text, [System.Text.RegularExpressions.MatchEvaluator]{
    param($match)
    return $Replacement
  })
}

$readme = Get-Content $ReadmePath -Raw
$readme = Replace-Section -Text $readme -Marker 'stats'  -Replacement $statsBlock
$readme = Replace-Section -Text $readme -Marker 'status' -Replacement $statusBlock

if ($DryRun) {
  Write-Output $readme
} else {
  [IO.File]::WriteAllText($ReadmePath, $readme, [System.Text.UTF8Encoding]::new($false))
  Write-Host "README stats refreshed at $now UTC."
  Write-Host "  Universe : $($universe.Containers) bodies, $($universe.POIs) POIs, $($universe.Systems) systems ($($universe.Source))"
  Write-Host "  Models   : $($models.LatestTag) ($($models.Source))"
  Write-Host "  Phase    : $($phase.Calibrated)/$($phase.Total) calibrated"
}
