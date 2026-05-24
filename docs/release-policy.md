# Release policy

## Version format

Package repos use a **4-part version**: `major.minor.patch.build` (starting at **0.0.1.1**).

| Segment | When it changes |
|---------|-----------------|
| major / minor / patch | Manual edit of `.novolis/version.props` (or a tagged GitHub Release for legacy flows) |
| build (4th) | **Automatically** after each successful merge to `main` (CI build, test, pack, publish) |

The build number is stored in `.novolis/version.props` (`NovolisVersionBuild`) and committed by `merge.yml` with `[skip ci]`.

## Workflows

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| `pull-request.yml` | PR to `main` | Build + test only |
| `merge.yml` | Push to `main` | Build, test, pack, publish to nuget.org, bump build |
| `release.yml` | GitHub Release (optional) | Tag-driven publish for manual semver bumps |

## NuGet

- Publish via **Trusted Publishing** (OIDC). Configure each repo on nuget.org with workflow file **`merge.yml`** and environment **`nuget.org`**.
- Org variable: `NUGET_USERNAME` = `Novolis`.
- Do not publish from PRs or forks.

## Local development

- Version comes from `.novolis/version.props` via `Novolis.Version.targets` (imported in `Directory.Build.targets`).
- Local packs without bumping CI: `dotnet pack /p:NovolisLocalPack=true`.

Tag examples for manual releases: `v0.0.2.0`, `v0.1.0.0`.
