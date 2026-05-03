# T-1 NVIDIA tier — the two-process design — coming soon

> **Status**: planned for v0.0.2. v0.0.1 ships without T-1; CudaProbe runtime detection is kept so the app can show "your hardware would support a faster engine, available in v0.0.2".

This page will cover:
- The **failure mode that drove the deferral**: `Microsoft.ML.OnnxRuntime.DirectML` doesn't export the CUDA + TensorRT EP entry points, even when the matching native libraries are loaded.
- What we tried that didn't work (Spike 5 evidence, RTX 3080 + driver 13.1 + CUDA 12.9 + TensorRT 10.16): shared-provider lazy load via `AddDllDirectory`.
- Why two ONNX Runtime builds **cannot coexist** in the same .NET process (issue [microsoft/onnxruntime#20563](https://github.com/microsoft/onnxruntime/issues/20563)).
- The **two-process architecture** that fixes it cleanly: a separate `sc-agent-trt.exe` loads the CUDA build, talks to the main app over a local pipe.
- The **TensorRT engine compile step** (~30s on first launch, cached per-GPU/driver/model SHA) and why it has to live in the .exe whose .dll dependencies match.
- Estimated effort + the trigger condition for actually shipping it.

In the meantime, see [decisions log D5](decisions-log.md#d5--t-1-nvidia-tier-deferred-to-v002-via-two-process-design-2026-05-03) and the original spike output (private repo — pinned in Discussions periodically; ask if you want a copy).

Want this sooner? **[Open or upvote a Discussion](https://github.com/zimm1/sc-agent-public/discussions/categories/ideas)**.
