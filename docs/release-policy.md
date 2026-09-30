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

| Registry | Who | Trigger | Version |
|----------|-----|---------|---------|
| GitHub Packages and nuget.org | Libraries | Push to `main` (`merge.yml`) | `2026.1.1.{run}` |
| GitHub Packages | `novolis-tools`, `novolis-analyzers` | GitHub Release published (`release.yml`) | `2026.1.1.{run}` |

Library `merge.yml` pushes the same pack to GitHub Packages and nuget.org. `release.yml` does not push nuget.org. nuget.org trust is one policy per repository, owned by the NuGet organization **Novolis**, named for the repository, matching GitHub owner `Novolis-Platform` and package glob `Novolis.*`. The short-lived key comes from `NuGet/login` as nuget.org user `frankhaugen` inside `dotnet-merge-publish.yml`.

## Workflows

| File | Trigger | Purpose |
|------|---------|---------|
| `pull-request.yml` | PR to `main` | Build + test (cancels superseded PR runs) |
| `merge.yml` | Push to `main` | Libraries: build + test; pack/publish to GitHub Packages and nuget.org when the package surface changes. Tools and analyzers: build + test only |
| `release.yml` | Release published | Pack, push to GitHub Packages, and attach the packages to the GitHub Release. Does not push nuget.org. App and utility hosts stay on their own release workflows |

### Executable repositories

Executable publishing is organized by host grain rather than by the library that
implements the domain:

| Repository | Release artifact | Trigger | Installer |
|------------|------------------|---------|-----------|
| `novolis-tools` | NuGet `PackAsTool` packages | A published release pushes to GitHub Packages. nuget.org is the library merge path | None |
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
| `release.yml` | Manual `workflow_dispatch` with no inputs. Every app, every channel declared in `ship`. |

Channels (phase one):

| Channel | Artifact | Notes |
|---------|----------|-------|
| `windows-inno` | Per-user Inno + portable zip + SHA-256 | Install under `%LocalAppData%\Programs\Novolis\…` |
| `android-apk` | Installable APK + SHA-256 | Persistent keystore preferred; adhoc signing allowed for sideload testing; monotonic `versionCode` |
| Linux | — | Local/PR capability only until a named product needs a Linux channel |

Catalog source of truth: `novolis-apps/build/apps.json`. See [apps-repos.md](apps-repos.md) and [installer-data-lifecycle.md](installer-data-lifecycle.md).

Google Play delivery is a separate product distribution path rather than a
`ship` channel. An app opts in with
`release.googlePlay.enabled=true` in `novolis-apps/build/apps.json`. The
`novolis-apps/.github/workflows/play-store.yml` workflow starts from an
existing GitHub Release tag, builds a signed Android App Bundle, and uploads
it to a selected Play testing or production track. It does not remove or
replace the GitHub Release APK. Play uploads require a persistent app upload
key and the `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` secret in the selected GitHub
Environment; the adhoc APK fallback is forbidden for Play.

Older GitHub Releases are pruned to the newest 5 after a successful release (`scripts/prune-github-releases.ps1`).

Shared host setup and GitHub Release publish live in `novolis-workflows` composites: `prepare-novolis-build`, `publish-built-release`, `install-inno-setup`, `write-sha256sums`, and `ensure-github-release`. App catalog publish stays in `novolis-apps` scripts. Google Play (`upload-google-play-bundle`, `play-store.yml`) is separate. nuget.org (`publish-nuget-org`) runs from library `merge.yml` (`dotnet-merge-publish`), not from `dotnet-release-publish`.

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
- Merge does not publish packages.
- A published release pushes the packages to GitHub Packages and attaches them to
  the GitHub Release. It does not push nuget.org.
- `novolis-analyzers` uses that same release publish. Library repositories publish
  GitHub Packages and nuget.org from `merge.yml`.
- Command names and package IDs must remain stable across host moves.

Release tag: `vYEAR.MAJOR.MINOR.BUILD` from `build/version.json` plus `github.run_number`.

## Permissions

```yaml
permissions:
  contents: read
  packages: write
  id-token: write
```

Library nuget.org pushes use Trusted Publishing (`id-token: write`). Android APK product releases prefer persistent `ANDROID_KEYSTORE_*` secrets; adhoc keys are allowed for sideload testing and are not upgrade-safe. Google Play releases additionally require app-specific upload-key secrets and a Play Console service account with app-level release permissions.

## Local development

```bash
dotnet pack -c Release /p:NovolisLocalPack=true
# Produces 2026.1.1.0 (or set /p:NovolisLocalBuild=42)
```
