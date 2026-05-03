# Changelog — sc-agent-public

All notable changes to data published in this repo. App-side changelog lives in the app itself (Settings → About → What's new).

This file uses [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and roughly tracks Star Citizen patches for dataset releases + sc-agent app versions for model releases.

## Unreleased

- Adding `phase/` directory for community-calibrated rotation phase data per body. Schema + first dataset coming with sc-agent v0.0.2.
- Adding `models/` directory for OCR tier ladder neural-network artifacts (signed manifest, multi-tier). Coming with sc-agent v0.0.1.

## [dataset-v4.7.2] — 2026-04-27

First public dataset release. 88 containers across 4 systems (Stanton, Pyro, Nyx, Ellis). 11136 POIs, 38 rotating bodies (15 with community phase, 23 awaiting calibration). Schema v=1. Sourced from CIG patch 4.7.2 game files via the sc-agent build pipeline.

[Unreleased]: https://github.com/zimm1/sc-agent-public/compare/dataset-latest...HEAD
[dataset-v4.7.2]: https://github.com/zimm1/sc-agent-public/releases/tag/dataset-v4.7.2
