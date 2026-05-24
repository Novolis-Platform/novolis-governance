# Release policy

## Version format

Package repos use a **4-part version**: `major.minor.patch.build` (starting at **0.0.1.1**).

| Segment | When it changes |
|---------|-----------------|
| major / minor / patch | Manual edit of `.novolis/version.props` before a release |
| build (4th) | After each successful **merge** publish to GitHub Packages |

## Registries

| Registry | Trigger | Purpose |
|----------|---------|---------|
| GitHub Packages | Push to `main` (`merge.yml`) | Continuous integration builds for org consumption |
| nuget.org | GitHub Release **published** (`release.yml`) | Public releases; packages also attached to the release |

GitHub Packages feed:

```text
https://nuget.pkg.github.com/Novolis-Platform/index.json
```

## Workflows

| File | Trigger | Purpose |
|------|---------|---------|
| `pull-request.yml` | PR to `main` | Build + test only |
| `merge.yml` | Push to `main` | Build, test, pack, push to GitHub Packages, bump build |
| `release.yml` | Release published | Pack at tag version, push to nuget.org, upload packages to release |

## Permissions

`merge.yml`:

```yaml
permissions:
  contents: write
  packages: write
```

`release.yml`:

```yaml
permissions:
  contents: write
```

Requires repo or org secret **`NUGET_API_KEY`** (passed explicitly to the reusable release workflow).

## Local development

Version: `.novolis/version.props` via `Novolis.Version.targets`.

Local pack without publishing: `dotnet pack /p:NovolisLocalPack=true`.
