# Package publishing (GitHub Packages + nuget.org)

Novolis uses two feeds:

| When | Feed | Workflow |
|------|------|----------|
| Every merge to `main` | [GitHub Packages](https://github.com/orgs/Novolis-Platform/packages) | `merge.yml` → `dotnet-merge-publish.yml` |
| GitHub Release published | [nuget.org](https://www.nuget.org/) | `release.yml` → `dotnet-release-publish.yml` |

PRs only build and test (`pull-request.yml`).

## GitHub Packages feed

```text
https://nuget.pkg.github.com/Novolis-Platform/index.json
```

Publishing on merge uses `GITHUB_TOKEN` (`packages: write`) for packages in that repository.

### Cross-repo dependencies

`GITHUB_TOKEN` cannot restore packages published from **other** Novolis repos. For repos that reference `Novolis.*` from GitHub Packages, add an organization secret:

| Secret | Scopes | Purpose |
|--------|--------|---------|
| `NOVOLIS_GPR_TOKEN` | `read:packages` | CI restore of Novolis packages from other repos |

**Public** on GitHub Packages means any authenticated GitHub user can download them (your existing `gh` token is enough for local restore). It does **not** mean anonymous NuGet restore: unauthenticated requests to `nuget.pkg.github.com` return **401**. Configure credentials once in user `%APPDATA%\NuGet\NuGet.Config` via `configure-gpr-user-nuget.ps1`; never commit tokens into repo `nuget.config`.

See [github-packages-org-settings.md](./github-packages-org-settings.md) for org defaults.

## nuget.org releases

1. Add org or repo secret **`NUGET_API_KEY`** (nuget.org API key with push rights for the package IDs).
2. Publish a GitHub Release with tag `v{major}.{minor}.{patch}` (optional `v` prefix stripped).

The release workflow packs at that version, pushes to nuget.org (`--skip-duplicate`), and attaches `.nupkg` / `.snupkg` to the release with `gh release upload`.

## Consuming packages

Each repo has a `nuget.config` with nuget.org + GitHub feed mapping (`Novolis.*` → `github`) only — no credentials in git.

**Local restore:** run once per machine:

```powershell
.\novolis-governance\scripts\configure-gpr-user-nuget.ps1
```

That writes the `github` source and token into `%APPDATA%\NuGet\NuGet.Config`. Re-run after `gh auth` token rotation.

## Scripts

| Script | Purpose |
|--------|---------|
| `configure-gpr-user-nuget.ps1` | User-level GitHub Packages credentials (`%APPDATA%\NuGet\NuGet.Config`) |
| `gpr-health-check.ps1` | One-shot feed + float + nuget-only health check |
| `gpr-package-overview.ps1` | Org package inventory (latest, repo link, junk flags) |
| `gpr-find-junk-versions.ps1` / `gpr-remove-junk-versions.ps1` | Find/delete throwaway versions that poison `2026.1.*` |
| `find-build-line-floats.ps1` | Fail on `2026.1.N.*` floats in `Directory.Packages.props` |
| `configure-package-publishing.ps1` | Version props, targets, `nuget.config`, workflows |
| `apply-pr-merge-release-workflows.ps1` | Write `pull-request.yml`, `merge.yml`, `release.yml`; remove `ci.yml` |

See [gpr-maintenance.md](gpr-maintenance.md) for the operational runbook.
