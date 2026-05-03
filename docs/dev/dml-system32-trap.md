# The 5-year-old DirectML.dll trap

A debugging story about a Windows infrastructure detail that ate two days, in case it saves somebody else.

> **TL;DR**: Windows 10 22H2 ships a DirectML.dll from **July 2020** in System32. ONNX Runtime 1.20+ requires DirectML feature levels introduced in late 2023. The OS-shipped DLL is the loader's silent fallback when the app doesn't ship its own. Result: `HRESULT 887A0004 DXGI_ERROR_UNSUPPORTED` from `DMLCreateDevice` on every adapter. The fix is to bundle a current `Microsoft.AI.DirectML` 1.15.4 next to the .exe.

## The symptom

Building sc-agent's OCR tier ladder, the very first DirectML inference attempt failed:

```
OnnxRuntimeException [ErrorCode:RuntimeException]
   from dml_provider_factory.cc(549/520)
   HRESULT 887A0004 = DXGI_ERROR_UNSUPPORTED
   "The specified device interface or feature level is not supported on this system."
```

This was on a Windows 10 22H2 machine with an RTX 3080 + AMD Radeon iGPU + recent NVIDIA driver. Every adapter, every graph optimization level, every ORT version (tested 1.20.1 + 1.24.4) — the same failure on the same source line in `dml_provider_factory.cc`.

## The hypothesis tree

When an exception fires from the same line of ORT internals across **every** permutation of test inputs, the issue is below ORT — it's in something ORT depends on, that's the same in all those permutations. We tested:

- ❌ **ORT version specific?** No — both 1.20.1 and 1.24.4 fail identically.
- ❌ **Graph optimization level specific?** No — DISABLED, BASIC, EXTENDED, ALL all fail.
- ❌ **NVIDIA-specific?** No — the AMD Radeon adapter fails too. Cross-vendor.
- ❌ **Driver version specific?** Driver 13.1 was fresh; rollback to 12.7 didn't help.
- ❌ **Multi-adapter confusion?** DXGI enumeration showed 6 adapters (NVIDIA Optimus quirk listing the RTX 3080 four times + AMD APU + duplicates) — but explicitly picking adapter index 0, 1, or 5 didn't matter, all failed identically.

That left **the DirectML runtime DLL itself**.

## The "wait, which DLL is loading?" moment

```pwsh
PS> Get-Item C:\Windows\System32\DirectML.dll | Select-Object VersionInfo
FileVersion=1.0.200713-1013.1.vb.07142e1
ProductVersion=1.0.200713-1013.1.vb.07142e1
```

That's not a recent build. `200713` is a date — **July 13, 2020**. Five and a half years old at the time of this writing.

ONNX Runtime 1.20+ requires DirectML feature level 5.x or 6.x, both of which were introduced in DirectML 1.10+ (mid-2023). The 2020-vintage System32 DLL doesn't expose those levels, so when ORT calls `DMLCreateDevice` asking for them, the device creation rejects with `DXGI_ERROR_UNSUPPORTED`.

## The "but the NuGet package ships a current DirectML.dll" plot twist

`Microsoft.ML.OnnxRuntime.DirectML` declares a transitive dependency on `Microsoft.AI.DirectML`, and that NuGet package **does** ship a current DirectML.dll (1.15.4 at the time, October 2024). It's there in the `microsoft.ai.directml/<version>/bin/x64-win/` directory inside the NuGet cache.

But the standard MSBuild copy targets that move native assets to the build output only handle the modern `runtimes/<rid>/native/` layout. `Microsoft.AI.DirectML` uses the **legacy** `bin/<arch>-<os>/` layout. The targets don't know about it. The bundled 1.15.4 DLL never reaches the output directory.

When the .exe runs and tries to load `DirectML.dll`, the loader walks the search path. There's no `DirectML.dll` next to the .exe (because nobody copied it there). The loader continues to PATH, finds System32 first (always), and loads the 2020 fallback. From the app's perspective, the load succeeded — there's no error, the function symbols all resolve, the device creation runs and only THEN fails with the cryptic 887A0004.

## The fix

Add an explicit `<Content Include="...">` in the .csproj that consumes DirectML, pointing at the NuGet cache path of the bundled DLL:

```xml
<ItemGroup>
  <PackageReference Include="Microsoft.AI.DirectML" />
</ItemGroup>

<ItemGroup>
  <Content Include="$(NuGetPackageRoot)microsoft.ai.directml\1.15.4\bin\x64-win\DirectML.dll">
    <Link>DirectML.dll</Link>
    <CopyToOutputDirectory>PreserveNewest</CopyToOutputDirectory>
    <CopyToPublishDirectory>PreserveNewest</CopyToPublishDirectory>
    <Visible>false</Visible>
  </Content>
</ItemGroup>
```

After that, the loader finds `DirectML.dll` (1.15.4) next to the .exe, doesn't fall back to System32, and the device creation succeeds.

## Numbers, post-fix

Tested permutations on the same RTX 3080 + AMD Radeon iGPU:

| Adapter | Graph optimization | Session create | First inference |
|---|---|---:|---:|
| NVIDIA RTX 3080 | DISABLED | 639 ms | 2274 ms |
| NVIDIA RTX 3080 | ALL | 358 ms | **498 ms** |
| AMD Radeon iGPU | DISABLED | 371 ms | 2460 ms |
| AMD Radeon iGPU | ALL | 357 ms | **81 ms** |

Surprising: the AMD APU + ALL-optimization combo finishes the first inference faster than the RTX 3080 (81 ms vs 498 ms) on a 64×64 dummy input. Almost certainly because shared system memory beats PCIe transfer for tiny tensors — for production-size ROI (~720×1280) the discrete GPU likely pulls ahead. We'll quantify in [`bench-numbers.md`](bench-numbers.md) once the bench harness has a real run.

## Lessons

1. **Native-package `bin/<arch>-<os>/` layout is silently incompatible with modern MSBuild copy.** The standard pattern is `runtimes/win-x64/native/`. When a dependency uses the legacy layout, you MUST add explicit Content directives or the file never makes it to the output.

2. **System32 is always on PATH and always loads as a silent fallback.** When the loader can't find a native lib next to the .exe, it falls through. A stale OS-shipped version becomes the de-facto runtime. Always verify what's loaded:

   ```pwsh
   Get-Process <your-exe> |
     Select-Object -ExpandProperty Modules |
     Where-Object { $_.ModuleName -like '*DirectML*' } |
     Select-Object FileName, FileVersion
   ```

3. **Windows 10 22H2 ships a 5-year-old DirectML.dll.** Any app using DirectML on Win 10 needs to bundle a current version — never trust the OS-shipped one. Win 11 may be better but assume it's the same.

4. **When the same exception fires from the same source line across all permutations, the issue is below the framework.** Don't waste time mutating model parameters or session options — go look at native dependency versions.

## What this story shows

- Modern .NET native-asset wiring still has rough edges around legacy package layouts.
- DirectML is a great abstraction for cross-vendor GPU support, but it ships in System32 way out of date.
- A tiny `<Content Include>` at the bottom of a csproj can turn "this whole architecture doesn't work" into "this works perfectly" — sometimes the bug is two lines from the fix, but the lines aren't in the code you were looking at.

If you hit the same symptom, the fix above unblocks you. If you're a CIG dev or a tool author shipping ONNX-DirectML on Windows, this is worth knowing exists.
