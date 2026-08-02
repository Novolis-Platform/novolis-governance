# Coverage reports

Org-wide line/branch coverage for `novolis-*` test hosts, collected in parallel and merged into one HTML report.

## Quick start

```powershell
# List which repos would run (after excludes)
pwsh -File novolis-governance/scripts/get-coverage-report.ps1 -ListRepos

# Full parallel run → artifacts/coverage/
pwsh -File novolis-governance/scripts/get-coverage-report.ps1 -OpenReport

# Subset
pwsh -File novolis-governance/scripts/get-coverage-report.ps1 -Include novolis-astro,novolis-io,novolis-math

# Extra excludes + throttle
pwsh -File novolis-governance/scripts/get-coverage-report.ps1 -Exclude novolis-raylib,novolis-audio -ThrottleLimit 6
```

Requires .NET 10 SDK (MTP `--coverage`) and `reportgenerator` (`dotnet tool install -g dotnet-reportgenerator-globaltool` — auto-installed if missing).

Do **not** pass `--nologo` to `dotnet test` under MTP — it is treated as an unknown argument and yields exit code 5 with zero tests.

## Test gaps (no coverage run needed)

```powershell
pwsh -File novolis-governance/scripts/get-test-gap-report.ps1 -FailOnGaps:`$false
```

Reports:

1. Repos/solutions with **no test hosts**
2. Production assemblies under `src/` / `codegen/` with **no direct test `ProjectReference`**

Same `-Exclude` / `coverage-excludes.txt` / `-Include` as the coverage collector. Output: `artifacts/test-gaps/SUMMARY.md`.

### Platform / native packages (allowed gaps)

These packables are intentionally without headless unit `ProjectReference` linkage (GPU, OS UI, P/Invoke, or Docker):

| Package | Why skipped |
|---------|-------------|
| `Novolis.Audio.Bindings` / `.Native` | Native audio P/Invoke |
| `Novolis.Audio.Output.NAudio` | Windows audio device |
| `Novolis.Audio.Voice.Platform.Maui` / `.Windows` | Platform voice hosts |
| `Novolis.Avalonia.Mobile.Android` / `.Desktop` | Mobile/desktop UI hosts |
| `Novolis.Raylib` / `.Native` / `.Raygui.Native` | Native window / meta-package |
| `Novolis.Rendering.Presentation.Raylib` | GPU presentation |
| `Novolis.Testing.Testcontainers` | Requires Docker |

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

## How it works

1. Discover `tests/**/*.csproj` that reference TUnit / VSTest / xUnit / NUnit.
2. Build each repo (unless `-SkipBuild`), then `dotnet test --coverage --coverage-output-format cobertura`.
3. Repos run in parallel (`ForEach-Object -Parallel`, `-ThrottleLimit`).
4. ReportGenerator merges Cobertura → HTML + Markdown + aggregate Cobertura.

## Gate (optional)

```powershell
pwsh -File novolis-governance/scripts/get-coverage-report.ps1 -FailBelow 60
```

Exits 1 if aggregate line coverage is below the threshold, or if any selected repo fails.
