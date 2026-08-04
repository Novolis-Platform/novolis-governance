# Release policy

## Version format

All NuGet and GitHub Package versions use **four numeric segments only** (no text, no prerelease labels):

```text
YEAR.MAJOR.MINOR.BUILD
```

Example: `2026.1.1.351` — merge run 351 and release run 351 both use that exact shape.

| Segment | Source | When it changes |
|---------|--------|-----------------|
| `YEAR` | `build/version.json` | Platform generation (e.g. settled .NET baseline year) |
| `MAJOR` | `build/version.json` | Breaking public API change (reset `minor` to 0) |
| `MINOR` | `build/version.json` | Manual bump before intentional release line |
| `BUILD` | `github.run_number` in CI | Every workflow run; **never committed** |

Human-owned intent: [`build/version.json`](../build/version.json).

MSBuild projection: `build/version.props` (run `scripts/sync-version-props.ps1` after editing JSON).

Local pack without CI: `YEAR.MAJOR.MINOR.1` via `NovolisLocalBuild` (override with `/p:NovolisLocalBuild=42`).

Cross-repo references: floating **`2026.1.1.*`** in `Directory.Packages.props`.

## Registries

| Registry | Trigger | Version |
|----------|---------|---------|
| GitHub Packages | Push to `main` (`merge.yml`) | `2026.1.1.{run}` |
| nuget.org | GitHub Release published (`release.yml`) | `2026.1.1.{run}` |

Same version rules for both; only the feed differs.

## Workflows

| File | Trigger | Purpose |
|------|---------|---------|
| `pull-request.yml` | PR to `main` | Build + test (cancels superseded PR runs) |
| `merge.yml` | Push to `main` | Build + test; pack/publish to GitHub Packages only when package surface changes |
| `release.yml` | Release published | Pack, push to nuget.org |

### Merge short-circuit (libraries)

Reusable `dotnet-merge-publish.yml` classifies the push:

| Change set | CI | GPR publish |
|------------|----|-------------|
| `src/**`, `*.csproj`, `Directory.Packages.props`, … | yes | yes |
| `tests/**`, `Directory.Build.props` (policy/warnings), `scripts/**` | yes | **no** |
| docs / `**.md` / version bump props (paths-ignore) | skipped | skipped |

Direct pushes to `main` remain supported. Cross-repo “herds” still run in parallel; same-repo re-pushes cancel in-progress merge runs.

### Apps Windows usage

`novolis-apps` runs Linux CI first; the Windows release job starts only when CI succeeds **and** release-impacting paths changed. Older GitHub Releases are pruned to the newest 5 after a successful release.

Shared Windows glue lives in `novolis-workflows` composites: `install-inno-setup`, `write-sha256sums`, and `ensure-github-release` (create-if-missing + asset upload). App catalog publish stays in `novolis-apps` scripts.

Release tag: `v2026.1.1` (platform line) or `v2026.1.1.{run}` (full version). Pack always uses `YEAR.MAJOR.MINOR` from JSON plus current `github.run_number`.

## Permissions

```yaml
permissions:
  contents: read
  packages: write
```

Requires org/repo secret **`NUGET_API_KEY`** for nuget.org release.

## Local development

```bash
dotnet pack -c Release /p:NovolisLocalPack=true
# Produces 2026.1.1.0 (or set /p:NovolisLocalBuild=42)
```
