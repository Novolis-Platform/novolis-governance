# Platform ProjectReference mode

Local multi-repo iteration **without** local NuGet feeds or committed cross-repo `ProjectReference`s.

When you open or build **`Novolis.Platform`** (the meta solution), MSBuild rewrites each project's **existing** `Novolis.*` `PackageReference` items into sibling `ProjectReference`s using a generated PackageId → `.csproj` map.

Committed `.csproj` files stay PackageReference-only. Per-repo solutions and CI stay on GitHub Packages.

## Hard rules

| Rule | Detail |
|------|--------|
| Intersect only | Substitute **only** if the project has that `PackageReference` **and** the id is in the map **and** the path exists. Never invent ProjectReferences for unreferenced packages. |
| Map providers | Packable projects only (`IsPackable=true` + `PackageId`). Tests/samples are consumers (they get substitution when they PackageReference Novolis packages). |
| No csproj dual-ref | Never hand-edit Package↔Project conditionals into `.csproj`. |
| No local feeds | Do not use `artifacts/nuget-local` / `novolis-local`. |
| Prove done | Still publish to GPR for consumers outside meta mode. |

## Trigger

| How | Effect |
|-----|--------|
| `SolutionName == Novolis.Platform` | Auto-enable |
| `-p:NovolisUseProjectReferences=true` | Force on (any solution / single project) |
| `-p:NovolisUseProjectReferences=false` | Force off (wins over SolutionName) |
| Env `NOVOLIS_USE_PROJECT_REFERENCES=true` | Force on when property unset |

## Regenerate map + meta solution

```powershell
pwsh -File novolis-governance/build/Generate-Platform-Slnx.ps1
# or map only:
pwsh -File novolis-governance/build/Generate-PackageToProjectMap.ps1
```

Outputs:

- `Novolis.Platform.slnx` (workspace root + copy under `novolis-governance/build/`)
- [`novolis-governance/build/generated/Novolis.PackageToProject.props`](../build/generated/Novolis.PackageToProject.props)

Regenerate after adding/removing packable projects.

## Daily use

```powershell
# Open meta solution in VS / Rider, or:
dotnet build novolis-governance/build/Novolis.Platform.slnx

# Single consumer against sibling source:
dotnet build path/to/Consumer.csproj -p:NovolisUseProjectReferences=true
```

## Verify

```powershell
pwsh -File novolis-governance/scripts/verify-project-ref-mode.ps1
pwsh -File novolis-governance/scripts/verify-nuget-only.ps1
pwsh -File novolis-governance/scripts/gpr-health-check.ps1 -SkipRemote
```

`verify-project-ref-mode.ps1` checks map completeness, static intersect dry-run, and MSBuild smoke (PackageReference ∩ map only).

## Implementation files

| File | Role |
|------|------|
| [`Novolis.ProjectReferenceMode.props`](../build/Novolis.ProjectReferenceMode.props) | Trigger + workspace root |
| [`Novolis.ProjectReferenceMode.targets`](../build/Novolis.ProjectReferenceMode.targets) | Intersect substitution |
| [`Novolis.LibraryReferenceBridge.props`](../build/Novolis.LibraryReferenceBridge.props) | Copy map → `LibraryProjectMap` for optional LibraryReference |
| [`Novolis.Packaging.targets`](../build/Novolis.Packaging.targets) | Imports mode targets (all repos) |
| [`Generate-PackageToProjectMap.ps1`](../build/Generate-PackageToProjectMap.ps1) | Map generator |

Stack analyzers (`Novolis.StackAnalyzers.props`) stay a separate analyzer `ProjectReference` (no PackageReference in csproj to substitute).

## LibraryReference (optional)

Package [`Novolis.MSBuild.LibraryReference`](../../novolis-msbuild/README.md) provides a committed `LibraryReference` item that expands to project-or-package without enabling ProjectReference mode. Governance copies `@(NovolisPackageProject)` into `@(LibraryProjectMap)` via [`Novolis.LibraryReferenceBridge.props`](../build/Novolis.LibraryReferenceBridge.props) so Novolis PackageIds resolve paths when that package’s targets are imported.

ProjectReference mode remains the supported org-wide workflow until repos adopt `LibraryReference`.

## Related

- [nuget-only-policy.md](nuget-only-policy.md)
- [local-nuget-development.md](local-nuget-development.md) (deprecated folder-feed path)
- [README-Platform-Solution.md](../build/README-Platform-Solution.md)
