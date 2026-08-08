# Coverage reports

Org-wide line/branch coverage for `novolis-*` test hosts, collected in parallel and merged into one HTML report.

## Preferred: `novolis-coverage` (dotnet tool)

```powershell
dotnet tool install --global Novolis.Tools.Coverage.Cli --version 2026.1.*

# Platform.slnx + ProjectRef (skip rebuild when already warm)
novolis-coverage collect --platform --skip-build --fail-below -1 --out d:\novolis\coverage

# List hosts
novolis-coverage list --platform

# Analyze an existing Cobertura (library API; no test run)
novolis-coverage gaps --cobertura d:\novolis\coverage\report\Cobertura.xml --target 95 --write d:\novolis\coverage\GAPS.md

# One markdown file: Platform.slnx Cobertura fan-in (parallel), caller's cwd or --out
novolis-coverage crap --fail-above -1
novolis-coverage crap --out d:\novolis\CRAP.md --coverage-dir d:\novolis\coverage
```

Library (preferred over growing PowerShell): `Novolis.Tools.Coverage` — parse/analyze/gate/CRAP.
Test authoring helpers: `Novolis.Testing.Coverage` (`PublicApiSurface`).
Governance scripts remain thin policy wrappers around the tool.

Local without install:

```powershell
dotnet run --project d:\novolis\novolis-tools\src\Novolis.Tools.Coverage.Cli -p:NovolisUseProjectReferences=true -- collect --platform --skip-build --fail-below -1 --out d:\novolis\coverage
dotnet run --project d:\novolis\novolis-tools\src\Novolis.Tools.Coverage.Cli -p:NovolisUseProjectReferences=true -- gaps --cobertura d:\novolis\coverage\Cobertura.xml --target 95
dotnet run --project d:\novolis\novolis-tools\src\Novolis.Tools.Coverage.Cli -p:NovolisUseProjectReferences=true -- crap --out d:\novolis\CRAP.md --fail-above -1
```

HTML: `d:\novolis\COVERAGE.html` (single-file summary + risk hotspots, next to `Novolis.Platform.slnx`). Full drill-down still under `d:\novolis\coverage\`.

## PowerShell (CI / legacy)

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
| `Novolis.Audio.Playback` / `.Runtime` / `.Live.Visuals` | Device playback / runtime / live-visual hosts |
| `Novolis.Audio.Voice.Platform.Maui` / `.Windows` | Platform voice hosts |
| `Novolis.Audio.Voice.SherpaOnnx` / `.EdgeTts` | Native ONNX / network TTS hosts |
| `Novolis.Avalonia.Mobile.Android` / `.Desktop` | Mobile/desktop UI hosts |
| `Novolis.MachineLearning.TestSupport` | Shared ML test-support helpers (not product logic) |
| `Novolis.Raylib` / `.Native` / `.Raygui.Native` / `.Runtime` / `.Raygui` / `.Bindings` | Native window / P/Invoke / runtime hosts |
| `Novolis.Raylib.Game` / `.Capture` / `.Hosting` / `.Loaders` / `.Input` / `.Manifests` | Native window / game / capture / input hosts |
| `Novolis.Raylib.Pipeline` / `.CodeGen` / `.CodeGen.Hooks` / `.CodeGen.Abstractions` / `.Testing` | Native binding codegen / test-helper packages |
| `Novolis.Tools.Cli` / `.Docs` / `.Docs.Cli` | Interactive CLI / docs tooling hosts |
| `Novolis.Tools.Coverage.Cli` | Interactive org coverage CLI host |
| `Novolis.Tools.Coverage` `CoverageCollector` / `ReportGeneratorInvoker` | Process orchestration (`dotnet test` / ReportGenerator); workspace/discovery/Cobertura helpers remain scored |
| `Novolis.Tools.Sqlite.Cli` / `.LiteDb.Cli` | Interactive SQLite / LiteDB CLI hosts |
| `Novolis.Logging.Transports` | HTTP / LocalIpc log transport hosts |
| `Novolis.Messaging.Coordination.Redis` | Redis / Garnet network coordination host (requires live Redis; Testcontainers gated) |
| `Novolis.Modeling.Import.AssimpSkinnedMeshImporter` | Native Assimp skinned FBX/glTF import (bone weights); guard clauses remain unit-tested |
| `Novolis.Markup.Html` | HTML layout/render host surface |
| `Novolis.Analyzers.Licensing` | Roslyn licensing analyzer (excluded via ReportGenerator assembly filter; netstandard2.0 cannot use assembly-level `ExcludeFromCodeCoverage`) |
| `Novolis.Geopolitics.Scenarios` | Scenario pack host helpers |
| `Novolis.Rendering.Presentation.Abstractions` / `.Raylib` / `.Silk` | GPU presentation bridge / hosts |
| `Novolis.Rendering.Backends.Vulkan` / `.Igpu` | GPU device backends |
| `Novolis.Rendering.Backends.TwoD.Silk` | Silk.NET OpenGL 2D window / game-loop host |
| `Novolis.Rendering.PathTrace.Demos` | GPU path-trace demos |
| `Novolis.Simulation.View` | Camera / view rig (GPU presentation bridge; headless sim tests skip) |
| `Novolis.Transports.Torrent` | BitTorrent / P2P network host |
| `Novolis.Transports.WireFish` | OS packet-capture host |
| `Novolis.Testing.Testcontainers` | Requires Docker |
| `Novolis.Video.Rtc.Abstractions` | RTC / capture device abstractions (device host surface) |

Packables in this table carry `[assembly: ExcludeFromCodeCoverage]` in their project (see each package README or `AssemblyInfo.cs`). Org coverage collectors honor that attribute; do not filter these assemblies manually in scripts unless debugging.

`LoggingSurface` (in `Novolis.Logging.Agent`) is also `[ExcludeFromCodeCoverage]` — it only attaches AgentSurface / LogTransports network hosts.

### Generated / wire-only surfaces

| Surface | Treatment |
|---------|-----------|
| `Novolis.Xsd.Ubl` / `.Ubl.Lean` `Generated/**/*.g.cs` | ReportGenerator `-filefilters:-*.g.cs` (do **not** assembly-exclude — hand-written `UblDocument` / `*BaseMapper` stay scored) |
| `Novolis.Xsd.Peppol` XSCG SBDH DTOs (`*.g.cs`) | Same `.g.cs` filter; envelope helpers remain covered |
| `Novolis.Xsd.Ubl.Lean.StripEmbeddedMapper` | `[ExcludeFromCodeCoverage]` — reflective Wire↔Base projection (same role as generated mappers) |
| `Novolis.Xsd.Ubl.Validation.SchemaSetFromDirectory` | `[ExcludeFromCodeCoverage]` — schema disk I/O / XmlSchema.Read error edges; public validators remain scored |
| `Novolis.Analyzers.Licensing` | Assembly filter (netstandard2.0) |
| `Novolis.Logging.Agent.LoggingAgentSurfaceContract` | Attribute reflection glue for AgentSurface attach |

### ProjectRef transitive bleed (per-repo reports)

Under Platform.slnx ProjectRef mode, consumer Cobertura files often include sibling assemblies (e.g. `Novolis.Simulation.Humanoid` under gaming, `Novolis.Economy.Core` under civics, `Novolis.Storage.*` under tools, `Novolis.CodeGen.*` under xsd). Per-repo ReportGenerator merges use **home-assembly include filters** (`Get-RepoAssemblyFilter` / `CoverageWorkspace.RepoAssemblyFilter`) so SUMMARY line % reflects that repo's packages. Aggregate org merges still combine all Cobertura files so each assembly is scored from its home repo when present.

ReportGenerator also excludes `MessagePack.*` generated formatters and legacy `Frank.*` assemblies from the merged aggregate so the gate reflects Novolis production source.

`novolis-avalonia` is listed in [`coverage-excludes.txt`](../scripts/coverage-excludes.txt) for the org gate: Avalonia visual-tree / UI-thread hosts are not scored in the aggregate line metric (Mobile Android/Desktop packables also carry `ExcludeFromCodeCoverage`).

`novolis-workspaces` **is included** in Platform coverage (Snapshots / Timeline / Workspaces). Agent tests are discovered on disk even when omitted from the meta slnx, and collected **serially** to avoid LocalIpc hangs.

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

Exits 1 if aggregate **line or branch** coverage is below the threshold, or if any selected repo fails.
