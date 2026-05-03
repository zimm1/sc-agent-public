# Decisions log

This is the plain-English version of the engineering decisions that shaped sc-agent. Each entry is a real choice with a real trade-off — the rationale is given so anyone can disagree, propose alternatives, or just understand *why* something is the way it is.

> **Format**: each decision has a date, a status, what was chosen, why, and what was rejected. New entries go at the bottom; superseded ones stay visible with a pointer to whatever replaced them.

> **Open to challenge.** Spot a decision that aged poorly, or a rationale that doesn't hold up? [Open a Discussion](https://github.com/zimm1/sc-agent-public/discussions) and let's talk. The point of having this log is so the reasoning is auditable.

## Decisions in force

### D1 — Read-only on Star Citizen (2026-04-26)

**Status**: in force.

**Decision**: sc-agent will only ever **read** from Star Citizen. No DLL injection, no API hooks, no memory reads, no synthetic key/mouse input. The single read mechanism is Windows Graphics Capture (the same OS-level API that screen recorders and Discord screen-share use).

**Rationale**: every "active" modification of the game would put the app in adversarial conversation with Easy Anti-Cheat. EAC is fine with screen capture (community-verified, multiple shipping tools confirm). Read-only is also the simplest contract to defend if a CIG dev or community lawyer ever asks "what does this do?". The cost is some features become impossible (e.g., auto-typing a destination into the chat input — out of scope, by design).

**What was rejected**: any plan that involved injecting a DLL into the SC process, hooking DirectX presents, reading game memory for player position, or programmatically pressing keys for the player.

### D2 — DirectML over CUDA for OCR (2026-05-02)

**Status**: in force, with a future T-1 NVIDIA tier deferred to v0.0.2 (see [`t-1-two-process.md`](t-1-two-process.md)).

**Decision**: the OCR neural network runs on **DirectML** as the default GPU path. NVIDIA-specific CUDA + TensorRT support is a separate optional tier (T-1 "Extreme NVIDIA"), not the default.

**Rationale**: DirectML works on **any** modern AMD, Intel, or NVIDIA card on Windows 10/11 with no extra install — the runtime ships in the box. CUDA + TensorRT would have required users to install a multi-gigabyte CUDA toolkit + TensorRT package per app, and would have been NVIDIA-only. For a fan tool downloaded by people who just want to play their game, that's the wrong default. Power users with recent NVIDIA cards still get the option of T-1, just opt-in.

**What was rejected**: ONNX Runtime CUDA EP as the primary path; NVIDIA-only as the only GPU option.

**See**: [`why-directml.md`](why-directml.md) for the full latency comparison and trade-offs.

### D3 — Single public companion repo (2026-05-03, supersedes earlier two-repo split)

**Status**: in force. Supersedes the original split between `sc-agent-models` (planned) and `sc-agent-dataset`.

**Decision**: there's one public repo, `sc-agent-public`, that hosts everything end-users see — dataset, OCR models, rotation phase data, downloads, issues, discussions. The code repo (`sc-agent`) stays private.

**Rationale**: the originally-planned split into two public repos (one for models, one for dataset) was administrative overhead with no user-facing benefit. End users would have ended up with bookmarks to two different repos for "the sc-agent stuff". One unified public repo is friendlier and easier to keep in sync. The trust anchor (Ed25519 public key) for the model manifest is still embedded in the app, so the security boundary doesn't change.

**What was rejected**: two parallel public repos; making the code repo public (single-developer hobby project, source release is on the long-term roadmap, not a v0.0.1 priority).

### D4 — Signed model manifest with Ed25519 + JCS canonical JSON (2026-05-02)

**Status**: in force. Single-key trust anchor for v0.0.1; multi-key revocation deferred to a future version.

**Decision**: the OCR model manifest published in Releases is signed with **Ed25519** (RFC 8032), with the canonical JSON form produced by **JCS** (RFC 8785). The app embeds the corresponding public key at build time as the trust anchor. Any tampering with the manifest, the signature, or any individual model file (each is SHA-256-verified against the manifest) causes the app to refuse the load and fall through to the embedded baseline tier.

**Rationale**: model files are downloaded over HTTPS from GitHub Releases, but TLS only authenticates the *transport*. We want **integrity** end-to-end — even if GitHub themselves served a modified file, the app should refuse it. Ed25519 is the modern, fast, small-key signature scheme; JCS gives us a deterministic JSON canonicalization so the signed bytes are reproducible. Both are well-implemented across languages, so a third party could verify the signature with any standard library.

**What was rejected**: TLS-only trust (insufficient — doesn't cover server compromise); RSA signatures (larger keys, slower); custom JSON formatting (non-reproducible).

**See**: [`signed-manifest-design.md`](signed-manifest-design.md) for the full rationale + key rotation policy.

### D5 — T-1 NVIDIA tier deferred to v0.0.2 via two-process design (2026-05-03)

**Status**: in force. Replaces the earlier plan to ship T-1 in v0.0.1 alongside DirectML.

**Decision**: the "Extreme NVIDIA" T-1 tier (CUDA + TensorRT INT8) is not in the v0.0.1 release. The CudaProbe runtime detection is kept (so v0.0.1 can show "your hardware would support a faster engine, available in v0.0.2"). v0.0.2 will implement T-1 via a separate process that loads the CUDA build of ONNX Runtime, talking to the main app over a local pipe.

**Rationale**: empirical investigation (Spike 5, see plan amendment A18) found that the DirectML build of ONNX Runtime does not export the CUDA + TensorRT execution provider entry points, even when the matching native libraries are loaded. A "shared provider lazy load" pattern was attempted with NVIDIA driver 13.1 + CUDA 12.9 + TensorRT 10.16 on an RTX 3080 — it failed with the missing export symbols. The clean fix is a two-process architecture, but that's a meaningful refactor and we'd rather ship v0.0.1 than block on it.

**What was rejected**: shipping a partially-working T-1 with a workaround that might break on driver updates; blocking v0.0.1 on the architectural rework.

**See**: [`t-1-two-process.md`](t-1-two-process.md) for the v0.0.2 design.

### D6 — Rotation phase community-calibrated (2026-04-26)

**Status**: in force.

**Decision**: rotation period and rotation axis come from the game files (`Data.p4k → <body>.xml → <ExposedEntities>`). Rotation **phase at epoch** does not — it's not in any static asset, neither `.p4k` nor `Game.dcb` nor `.soc` archives. It's bootstrapped from a 2020 community measurement set (Murphy Exploration Group → Valalol/Star-Citizen-Navigation, MIT-licensed, 15/38 bodies covered) and progressively calibrated live from sc-agent's own OCR observations.

**Rationale**: phase is server-side state. The maintainer spent two days searching for it in static assets — confirmed it's not there. Community measurement (or live calibration) is the only path. Live calibration via OCR is novel and crowdsourced — every player who sits still on a planet for 5+ seconds contributes a sample.

**What was rejected**: scraping a third-party CSV at runtime (privacy concern + dependency on external infra); manually measuring all 38 bodies (impractical, doesn't survive CIG world-clock rebases).

**See**: [`rotation-phase-story.md`](rotation-phase-story.md) for the math + the "what we tried that didn't work" story.

### D7 — Save POI elevated single-read default (2026-05-02)

**Status**: in force. The faster-tier elevation only fires once per F7 press, after the multi-frame averaging has converged.

**Decision**: when the player presses F7 to save a POI, the main OCR loop continues at its normal tier (T0 / T1 / T3 — whatever was selected). Once the position has converged across multiple frames, sc-agent does **one** elevated read using the highest available tier and uses that single high-quality reading as the saved coordinate.

**Rationale**: continuous T-1 / T1 OCR all the time is wasted GPU and battery for no gain — the player isn't constantly saving POIs. But at the moment of saving, the extra ~150ms for one max-quality read is worth it for the long-term accuracy of the stored position.

**What was rejected**: always-on max-quality OCR; averaging across multiple max-quality reads (not justified by latency budget for a single F7 action).

### D8 — SSL.com OV certificate over Microsoft Trusted Signing (2026-04-26)

**Status**: in force. v0.0.1 ships unsigned (portable .zip is fine for fan-project status); the upgrade path is SSL.com OV.

**Decision**: when the project does adopt code signing for the MSIX build, it'll use an **SSL.com OV certificate** (or [SignPath Foundation](https://signpath.org/foundation/) for free OSS signing) — not Microsoft Trusted Signing.

**Rationale**: Microsoft Trusted Signing's "Individual" enrollment flow is restricted to USA/Canada residents only at the time of writing (2026-04). The maintainer is an Italian individual, so that path is closed. SSL.com OV is ~250 USD/year, mainstream, and the SmartScreen warmup is the same.

**What was rejected**: Microsoft Trusted Signing (geographically blocked); EV cert (~700 USD/year, not justified for v0.0.1).

### D9 — Game.log demoted to enrichment-only (2026-04-26)

**Status**: in force.

**Decision**: the in-game `Game.log` file is **not** the primary source of any feature. It can enrich OCR output (e.g., system events, kill notifications) but the app must function without it.

**Rationale**: empirical investigation (Phase A finding F2) showed that (a) the launcher manifest path is encrypted (AES-256-CBC) — non-trivial to read robustly, (b) Quantum Travel events that early specs assumed would be in `Game.log` are absent on LIVE 4.x post-CIG-lockdown. OCR of the debug overlay (`r_DisplayInfo 3`) is the actually-reliable signal.

**What was rejected**: making `Game.log` the primary signal; building features that depend on QT-event log lines.

## Superseded decisions (kept for archaeology)

### D1.1 — Two-repo public split (2026-04-26)

**Status**: superseded by D3 on 2026-05-03.

**Original decision**: two public repos — `sc-agent-models` (signed OCR artifacts) + `sc-agent-dataset` (universe data).

**Why superseded**: collapsed into a single `sc-agent-public` for end-user simplicity (see D3).

---

> 🔄 This log is updated as part of the [`compound docs sempre`](https://github.com/zimm1/sc-agent-public/discussions) working agreement — every significant architectural change adds (or amends) an entry here. If you spot a decision that's been made implicitly without an entry, that's a doc bug — please flag it.
