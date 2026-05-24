# Release policy

## Version format

Package repos use **`SDKYEAR.APIBREAK.FEATURE`** (starting at **2026.1.0**).

| Segment | Source | When it changes |
|---------|--------|-----------------|
| `SDKYEAR` | `build/version.json` | Platform generation / settled .NET baseline |
| `APIBREAK` | `build/version.json` | Deliberate breaking public API change (resets `feature` to 0) |
| `FEATURE` | `build/version.json` | Manual bump before a stable release |
| `BUILD` | `github.run_number` in CI only | Never committed; used for internal packages and file versions |

Human-owned intent: [`build/version.json`](../build/version.json) (do not use `eng/` — ambiguous).

MSBuild projection: `build/version.props` (regenerate via `scripts/sync-version-props.ps1`).

Cross-repo package references use floating **`2026.1.*`** (aligned to `sdkYear.apiBreak.*` in `version.json`).

## Registries

| Registry | Trigger | Package version |
|----------|---------|-----------------|
| GitHub Packages | Push to `main` (`merge.yml`) | `2026.1.0-ci.{run}` |
| nuget.org | GitHub Release **published** (`release.yml`) | `2026.1.0` (3-part, no build) |

GitHub Packages feed:

```text
https://nuget.pkg.github.com/Novolis-Platform/index.json
```

## Workflows

Implemented in [`novolis-workflows`](https://github.com/Novolis-Platform/novolis-workflows).

| File | Trigger | Purpose |
|------|---------|---------|
| `pull-request.yml` | PR to `main` | Build + test only |
| `merge.yml` | Push to `main` | Build, test, pack, push to GitHub Packages (no version commit) |
| `release.yml` | Release published | Pack at tag version, push to nuget.org, upload packages |

Release tag must match `build/version.json`, e.g. `v2026.1.0`.

## Permissions

`merge.yml`:

```yaml
permissions:
  packages: write
```

`release.yml`:

```yaml
permissions:
  contents: read
  packages: write
```

Requires repo or org secret **`NUGET_API_KEY`** (passed explicitly to the reusable release workflow).

## Local development

Import `build/version.props` from `Directory.Build.props`. Packable projects get stable `2026.1.0` via `Novolis.Version.targets` unless CI overrides.

Local pack without publishing:

```bash
dotnet pack -c Release /p:NovolisLocalPack=true
```

## Floating versions and CI packages

NuGet floating `2026.1.*` resolves **stable** versions. Internal `-ci.{run}` packages on GitHub Packages are for continuous consumption; publish the first stable `2026.1.0` to GPR or nuget.org before downstream repos can restore via `2026.1.*` alone.
