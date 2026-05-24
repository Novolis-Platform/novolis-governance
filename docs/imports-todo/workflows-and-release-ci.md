# Workflows + ReleaseOrchistrator — CI pieces (mine)

**Sources:**

- `D:\repos\Workflows` — reusable GitHub Actions
- `D:\repos\ReleaseOrchistrator` — multi-stage release stub
- `D:\github\frank-docfx-publish`, `frank-dotnet-script-*` — doc/tooling (optional)

## What

| Repo | Content |
|------|---------|
| **Workflows** | Composite actions: dotnet restore/build/test/pack/publish patterns |
| **ReleaseOrchistrator** | dev → test → prod approval workflow skeleton |

**Not** platform libraries — **reference by URL** in `novolis-workflows` (GitHub org) and per-repo `.github/workflows`.

## Why

- `novolis-workflows` org templates should stay DRY; Frank Workflows repo already exists locally.
- Duplicating YAML into every `novolis-*` repo drifts; central reusable workflows match governance scale (22+ repos).

## How

1. Audit `D:\repos\Workflows` actions vs `novolis-workflows` current workflows.
2. Publish/mirror needed composites to `Novolis-Platform/.github` or `novolis-workflows` repo.
3. Wire `verify-nuget-only.ps1`, `doc-audit.ps1`, and `dotnet test` in standard pipeline.
4. Evolve **ReleaseOrchistrator** into documented release policy ([release-policy.md](../release-policy.md)) — approval gates for GPR.

### Skip

- Packaging Workflows as NuGet.
- Importing ReleaseOrchistrator as C# library.

## Acceptance

- New `novolis-*` repo created from template gets workflow via `workflow_call` not copy-paste.
- Documented in [maintainer-guide.md](../maintainer-guide.md).
