# Release policy

## Version format

Package repos use a **4-part version**: `major.minor.patch.build` (starting at **0.0.1.1**).

| Segment | When it changes |
|---------|-----------------|
| major / minor / patch | Manual edit of `.novolis/version.props` |
| build (4th) | After each successful merge publish to **GitHub Packages** |

## Registry

Packages are published to **[GitHub Packages](https://github.com/orgs/Novolis-Platform/packages)** only. **Do not** publish to nuget.org until explicitly enabled.

Org NuGet feed:

```text
https://nuget.pkg.github.com/Novolis-Platform/index.json
```

## Workflows

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| `pull-request.yml` | PR to `main` | Build + test only |
| `merge.yml` | Push to `main` | Build, test, pack, push to GitHub Packages, bump build |
| `release.yml` | GitHub Release (optional) | Tag-driven pack + push |

## Permissions

`merge.yml` requires:

```yaml
permissions:
  contents: write
  packages: write
```

## Local development

Version: `.novolis/version.props` via `Novolis.Version.targets`.

Local pack without publishing: `dotnet pack /p:NovolisLocalPack=true`.
