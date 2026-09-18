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

### Executable repositories

Executable publishing is organized by host grain rather than by the library that
implements the domain:

| Repository | Release artifact | Trigger | Installer |
|------------|------------------|---------|-----------|
| `novolis-tools` | NuGet `PackAsTool` packages | Merge publishes to GitHub Packages; a published release can push to nuget.org | None |
| `novolis-utilities` | Selected framework-dependent executable zips and SHA-256 manifest | Manual selected-utility release | None |
| `novolis-apps` | Selected app channels such as Inno or APK | Manual selected-app release | Product channel only |
| `novolis-lab` | None | Changed-lab validation only | None |

Library repositories publish libraries only. They must not publish a domain CLI
or a tool package. Existing command names and package IDs are preserved when
their hosts move into `novolis-tools`.

### Merge short-circuit (libraries)

Reusable `dotnet-merge-publish.yml` classifies the push:

| Change set | CI | GPR publish |
|------------|----|-------------|
| `src/**`, `*.csproj`, `Directory.Packages.props`, … | yes | yes |
| `tests/**`, `Directory.Build.props` (policy/warnings), `scripts/**` | yes | **no** |
| docs / `**.md` / version bump props (paths-ignore) | skipped | skipped |

Direct pushes to `main` remain supported. Cross-repo “herds” still run in parallel; same-repo re-pushes cancel in-progress merge runs.

### Apps product releases (`novolis-apps`)

`novolis-apps` does **not** publish installers or APKs on every push to `main`.

| Workflow | Behavior |
|----------|----------|
| `pull-request.yml` / `merge.yml` | Changed-app matrices from `build/apps.json` (scoped solutions + tests; Android compile only when declared). No packaging. |
| `release.yml` | Manual `workflow_dispatch`: selected app (or explicit `All`) and optional channel override restricted to that app's `ship` list |

Channels (phase one):

| Channel | Artifact | Notes |
|---------|----------|-------|
| `windows-inno` | Per-user Inno + portable zip + SHA-256 | Install under `%LocalAppData%\Programs\Novolis\…` |
| `android-apk` | Signed APK + SHA-256 | Persistent keystore required; monotonic `versionCode` |
| Linux | — | Local/PR capability only until a named product needs a Linux channel |

Catalog source of truth: `novolis-apps/build/apps.json`. See [apps-repos.md](apps-repos.md) and [installer-data-lifecycle.md](installer-data-lifecycle.md).

Older GitHub Releases are pruned to the newest 5 after a successful release (`scripts/prune-github-releases.ps1`).

Shared Windows glue lives in `novolis-workflows` composites: `install-inno-setup`, `write-sha256sums`, and `ensure-github-release`. App catalog publish stays in `novolis-apps` scripts.

### Utility releases (`novolis-utilities`)

Utilities are one-executable technical hosts. They do not use Inno, APK
packaging, Start Menu registration, an AppId, or an uninstall lifecycle.

- Pull requests and merges restore/build/test changed utilities only.
- A manual release selects one utility or explicitly selects `All`.
- Each selected utility is published as a framework-dependent executable
  artifact using the supported .NET runtime/SDK and placed in a zip.
- Each zip is accompanied by `SHA256SUMS.txt`.
- Utility release assets are attached directly to a GitHub Release and older
  releases are pruned using the same retention policy as apps.
- `dotnet publish --self-contained true` is not a utility classification rule.
  A utility may use a framework-dependent publish because SDK/runtime
  requirements are allowed.

### Tool releases (`novolis-tools`)

`novolis-tools` is the sole publisher of `PackAsTool` commands. Tool hosts use
`dotnet tool install`; they never receive an installer or utility zip.

- Changed tool hosts and their package libraries are validated in PR/merge CI.
- Merge publishes the affected tool packages to GitHub Packages.
- A published release may push the same version to nuget.org, following the
  four-segment version policy.
- Command names and package IDs must remain stable across host moves.

Release tag: `vYEAR.MAJOR.MINOR.BUILD` from `build/version.json` plus `github.run_number`.

## Permissions

```yaml
permissions:
  contents: read
  packages: write
```

Requires org/repo secret **`NUGET_API_KEY`** for nuget.org library releases. Android APK product releases require persistent `ANDROID_KEYSTORE_*` secrets (no adhoc keys for upgrade-safe channels).

## Local development

```bash
dotnet pack -c Release /p:NovolisLocalPack=true
# Produces 2026.1.1.0 (or set /p:NovolisLocalBuild=42)
```
