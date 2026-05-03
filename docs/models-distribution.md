# Models distribution

The OCR tier ladder neural networks shipped with sc-agent are published here as **GitHub Releases** under the `models-v<version>` tag pattern, with an Ed25519-signed manifest for tamper resistance.

## What's published

Per release, under `https://github.com/zimm1/sc-agent-public/releases/tag/models-v<version>`:

| File | Purpose |
|---|---|
| `models-manifest.json` | Per-tier file list with sizes + SHA-256 hashes + asset URLs (HTTPS-only enforced) |
| `models-manifest.json.minisig` | Detached Ed25519 signature over the canonicalized JSON, base64-encoded |
| `Realtime/det.onnx`, `rec.onnx`, `ppocr_keys_v1.txt` | T0 tier — PP-OCRv4 mobile INT8 |
| `Quality/det.onnx`, `rec.onnx`, `ppocr_keys_v1.txt` | T1 tier — PP-OCRv4 server FP32 |
| `ExtremeNvidia/cuda-pack-v1.zip` | T-1 tier — INT8 + TensorRT calibration cache + CUDA EP DLLs (v0.0.2+) |

Sizes: ~10 MB (Realtime), ~150 MB (Quality), ~250 MB (ExtremeNvidia full pack).

The `Cpu` tier (T3) is not published here — it ships embedded inside the app installer (always-available baseline; ~10 MB).

## How sc-agent uses it

1. App startup: HEAD-pings `models-manifest.json` from the latest release. If unreachable → offline fallback to embedded T3.
2. App downloads `models-manifest.json` + `models-manifest.json.minisig` and verifies the signature against the embedded Ed25519 public key (`keys/v1.pub` in the private code repo).
3. If verified, the app reads the per-tier file list, downloads each file, verifies SHA-256 against the manifest, atomic-rename into `%LOCALAPPDATA%\sc-agent\models\<TierName>\`.
4. Subsequent boots: `CachedManifestReader` re-verifies the on-disk snapshot. If verified, instantiates the requested tier directly from the cache; if signature/schema invalid → fall through to a lower tier.

## Schema (v=2)

```json
{
  "schemaVersion": 2,
  "publishedUtc": "2026-05-XX...",
  "tiers": {
    "Realtime": {
      "notes": "PP-OCRv4 mobile INT8 quantized for sub-200ms inference on consumer GPUs",
      "files": [
        {
          "name": "det.onnx",
          "url": "https://github.com/zimm1/sc-agent-public/releases/download/models-v0.0.1/det-realtime.onnx",
          "sizeBytes": 4500000,
          "sha256": "<64 lowercase hex>"
        },
        ...
      ]
    },
    "Quality": { ... }
  }
}
```

Constraints (enforced by `ManifestVerifier`):
- All `url` fields must use `https://`.
- All `sha256` are 64 lowercase hex chars.
- `sizeBytes > 0` and ≤ 2⁵³−1 (JSON number safe range).
- `schemaVersion` exact match — older clients refuse newer manifests.

## Trust anchor

The Ed25519 public key (`v1`) is embedded in the sc-agent app at build time. The matching private key is held offline by the maintainer.

If the private key is compromised, the app version that trusts the compromised key is force-deprecated via the auto-update channel (it refuses to run after a hardcoded "key revoked" date, prompting the user to update). v0.0.1 trust model = single-key + forced version bump on rotation. Multi-key revocation is on the long-term roadmap.

See [`/docs/keys.md`](keys.md) for the public key fingerprint + verification procedure.

## Verifying a release manually

You don't need to do this — the app verifies automatically. But if you want to:

```pwsh
# Download manifest + signature
gh release download models-v0.0.1 --repo zimm1/sc-agent-public --pattern "models-manifest.json*"

# Get the public key from the sc-agent app's About dialog (or build-time constant)
# Verify with any Ed25519 verification tool that supports the minisign-style framing.
```

Currently the only first-class verifier is the sc-agent app itself; a standalone CLI is on the roadmap.

## Release cadence

Models are published when:
- A new PP-OCRv4 model variant is released upstream and benchmarks better than the current.
- The training set for fine-tuning grows enough to retrain (likely ~quarterly once the data accumulates).
- A signing key rotation requires republishing the manifest.

There is no SLA. Watch the repo for release notifications.
