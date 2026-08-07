# Coverage reports

Org-wide line/branch coverage for `novolis-*` test hosts, collected in parallel and merged into one HTML report.

## Quick start

```powershell
# List which repos would run (after excludes)
pwsh -File d:\novolis\novolis-governance\scripts\get-coverage-report.ps1 -ListRepos

# Full parallel run → artifacts/coverage/ (NuGet mode: published packages)
pwsh -File d:\novolis\novolis-governance\scripts\get-coverage-report.ps1 -OpenReport

# Subset
pwsh -File d:\novolis\novolis-governance\scripts\get-coverage-report.ps1 -Include novolis-astro,novolis-io,novolis-math

# Extra excludes + throttle
pwsh -File d:\novolis\novolis-governance\scripts\get-coverage-report.ps1 -Exclude novolis-raylib,novolis-audio -ThrottleLimit 6
```

### Platform gate (ProjectReference mode)

Org coverage gate evaluates **local source** via regenerated `Novolis.Platform.slnx` and `NovolisUseProjectReferences=true`. Default `-FailBelow` is **95** in this mode.

```powershell
# Regenerate map + slnx, then collect coverage from test hosts listed in the platform solution
pwsh -File d:\novolis\novolis-governance\scripts\get-coverage-report.ps1 -PlatformSlnx -RegenerateSlnx

# Already regenerated
pwsh -File d:\novolis\novolis-governance\scripts\get-coverage-report.ps1 -PlatformSlnx -FailBelow 95

# List hosts that would run from the platform slnx (respects coverage-excludes.txt)
pwsh -File d:\novolis\novolis-governance\scripts\get-coverage-report.ps1 -PlatformSlnx -ListRepos
```

Requires .NET 10 SDK (MTP `--coverage`) and `reportgenerator` (`dotnet tool install -g dotnet-reportgenerator-globaltool` — auto-installed if missing).

Do **not** pass `--nologo` to `dotnet test` under MTP — it is treated as an unknown argument and yields exit code 5 with zero tests.

## Test gaps (no coverage run needed)

```powershell
pwsh -File d:\novolis\novolis-governance\scripts\get-test-gap-report.ps1 -FailOnGaps:`$false
```

Reports:

1. Repos/solutions with **no test hosts**
2. Production assemblies under `src/` / `codegen/` with **no direct test `ProjectReference`**

Same `-Exclude` / `coverage-excludes.txt` / `-Include` as the coverage collector. Output: `artifacts/test-gaps/SUMMARY.md`.

### Platform / native packages (allowed gaps)

These packables are intentionally without headless unit `ProjectReference` linkage (GPU, OS UI, P/Invoke, or Docker):

| Package | Why skipped |
|---------|-------------|
| `Novolis.IO.Mobile.Android` | Host-side ADB protocol / device tooling (headless tests cover parsers only; live ADB is dogfood) |
| `Novolis.Audio.Bindings` / `.Native` | Native audio P/Invoke |
| `Novolis.Audio.Output.NAudio` | Windows audio device |
| `Novolis.Audio.Voice.Platform.Maui` / `.Windows` | Platform voice hosts |
| `Novolis.Audio.Voice.SherpaOnnx` / `.EdgeTts` | Native ONNX / network TTS hosts |
| `Novolis.Avalonia.Mobile.Android` / `.Desktop` | Mobile/desktop UI hosts |
| `Novolis.Raylib` / `.Native` / `.Raygui.Native` / `.Runtime` / `.Raygui` / `.Bindings` | Native window / P/Invoke / runtime hosts |
| `Novolis.Raylib.Pipeline` / `.CodeGen` / `.Testing` | Native binding codegen / test-helper packages |
| `Novolis.Tools.Cli` / `.Docs` | Interactive CLI / docs tooling hosts |
| `Novolis.Markup.Html` | HTML layout/render host surface |
| `Novolis.Analyzers.Licensing` | Roslyn licensing analyzer (excluded via ReportGenerator assembly filter; netstandard2.0 cannot use assembly-level `ExcludeFromCodeCoverage`) |
| `Novolis.Geopolitics.Scenarios` | Scenario pack host helpers |
| `Novolis.Rendering.Presentation.Raylib` / `.Silk` | GPU presentation hosts |
| `Novolis.Rendering.Backends.Vulkan` / `.Igpu` | GPU device backends |
| `Novolis.Rendering.PathTrace.Demos` | GPU path-trace demos |
| `Novolis.Simulation.View` | Camera / view rig (GPU presentation bridge; headless sim tests skip) |
| `Novolis.Transports.Torrent` | BitTorrent / P2P network host |
| `Novolis.Transports.WireFish` | OS packet-capture host |
| `Novolis.Testing.Testcontainers` | Requires Docker |

Packables in this table carry `[assembly: ExcludeFromCodeCoverage]` in their project (see each package README or `AssemblyInfo.cs`). Org coverage collectors honor that attribute; do not filter these assemblies manually in scripts unless debugging.

ReportGenerator also excludes `MessagePack.*` generated formatters and legacy `Frank.*` assemblies from the merged aggregate so the gate reflects Novolis production source.

`novolis-avalonia` is listed in [`coverage-excludes.txt`](../scripts/coverage-excludes.txt) for the org gate: Avalonia visual-tree / UI-thread hosts are not scored in the aggregate line metric (Mobile Android/Desktop packables also carry `ExcludeFromCodeCoverage`).

## Outputs

Under `<Root>/artifacts/coverage/` (gitignored via repo `artifacts/`):

| Path | Content |
|------|---------|
| `SUMMARY.md` | Per-repo table for PRs / agents |
| `summary.json` | Machine-readable totals |
| `report/index.html` | Merged ReportGenerator HTML |
| `raw/<repo>/*.cobertura.xml` | Per-test-project Cobertura |
| `logs/<repo>.log` | Build/test transcript on failure |

## Excludes

Default list: [`scripts/coverage-excludes.txt`](../scripts/coverage-excludes.txt).

- Edit that file for standing skips (apps, templates, workflows, …).
- Pass `-Exclude repo1,repo2` for one-off skips (merged with the file).
- Pass `-Include repo1,repo2` to run only those repos (still applies excludes).
- Platform mode still applies these excludes when selecting test hosts from `Novolis.Platform.slnx`.

## How it works

### NuGet mode (default)

1. Discover `tests/**/*.csproj` that reference TUnit / VSTest / xUnit / NUnit.
2. Build each repo (unless `-SkipBuild`), then `dotnet test --coverage --coverage-output-format cobertura` with `NovolisUseProjectReferences=false`.
3. Repos run in parallel (`ForEach-Object -Parallel`, `-ThrottleLimit`).
4. ReportGenerator merges Cobertura → HTML + Markdown + aggregate Cobertura.

### Platform mode (`-PlatformSlnx`)

1. Optionally regenerate via [`build/Generate-Platform-Slnx.ps1`](../build/Generate-Platform-Slnx.ps1) (`-RegenerateSlnx`).
2. Enumerate MTP test hosts listed in `Novolis.Platform.slnx` (skip `coverage-excludes.txt` repos and non-hosts such as TestSupport).
3. `dotnet build` / `dotnet test --coverage` each selected host with `NovolisUseProjectReferences=true` (parallel by repo).
4. Merge and gate: default **FailBelow 95** when `-FailBelow` is omitted.

## Gate

```powershell
# NuGet mode — opt-in threshold
pwsh -File d:\novolis\novolis-governance\scripts\get-coverage-report.ps1 -FailBelow 60

# Platform org gate (defaults to FailBelow 95)
pwsh -File d:\novolis\novolis-governance\scripts\get-coverage-report.ps1 -PlatformSlnx -RegenerateSlnx
```

Exits 1 if aggregate line coverage is below the threshold, or if any selected repo fails.
