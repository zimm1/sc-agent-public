# Signed model manifest — coming soon

> **Status**: planned. Implementation is shipped + verified end-to-end; this is the design write-up.

This page will cover:
- Why **Ed25519** (RFC 8032) and not RSA — modern, small keys, fast verify.
- Why **JCS** (RFC 8785) for canonical JSON — reproducible byte-stream regardless of how the JSON was originally serialized, so the signed bytes survive round-trips.
- The **single-key trust anchor** for v0.0.1 + the rotation policy (force version bump on revocation).
- Why we did **not** chain to a Web PKI cert (the trust anchor is the app version itself, no CA dependency).
- Why **HTTPS-only URLs** are enforced even though the signature already covers integrity (defense in depth).
- The **per-file SHA-256 verification** that catches Release-asset-CDN tampering even after manifest signature passes.
- How the **maintainer signing flow** (offline private key, three-line PowerShell script) avoids the most common operational mistakes.

In the meantime, see [decisions log D4](decisions-log.md#d4--signed-model-manifest-with-ed25519--jcs-canonical-json-2026-05-02) and the operational format in [`docs/models-distribution.md`](../models-distribution.md).

Want this sooner? **[Open or upvote a Discussion](https://github.com/zimm1/sc-agent-public/discussions/categories/ideas)**.
