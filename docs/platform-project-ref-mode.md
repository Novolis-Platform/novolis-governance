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
| `-p:NovolisLibraryRoot=PATH` | Resolve mapped library projects from a selected checkout root, such as `d:\novolis\novolis-lab\submodules`; defaults to the workspace forest |

## Regenerate map + meta solution

```powershell
dotnet run --project d:\novolis\novolis-tools\src\Novolis.Solution.Tool\Novolis.Solution.Tool.csproj --no-launch-profile -- generate --root d:\novolis
# or the thin PowerShell front door:
pwsh -File d:\novolis\novolis-governance\build\Generate-Platform-Slnx.ps1
```

Outputs:

- `Novolis.Platform.slnx` at the **workspace root** (canonical open/build path); a path-adjusted checked-in copy also lands under `novolis-governance/build/`
- [`novolis-governance/build/generated/Novolis.PackageToProject.props`](../build/generated/Novolis.PackageToProject.props)

Regenerate after adding/removing packable projects.

## Daily use

```powershell
# Open meta solution in VS / Rider, or:
dotnet build Novolis.Platform.slnx

# Single consumer against sibling source:
dotnet build path/to/Consumer.csproj -p:NovolisUseProjectReferences=true

# A lab with selected library submodules:
dotnet build path/to/Consumer.csproj -p:NovolisUseProjectReferences=true -p:NovolisLibraryRoot=path/to/submodules
```

## Verify

```powershell
dotnet run --project d:\novolis\novolis-tools\src\Novolis.Solution.Tool\Novolis.Solution.Tool.csproj --no-launch-profile -- verify --root d:\novolis
dotnet run --file d:\novolis\novolis-governance\scripts\verify-nuget-only.cs
pwsh -File d:\novolis\novolis-governance\scripts\gpr-health-check.ps1 -SkipRemote
```

`novolis-solution verify` checks map completeness and LibraryReference copy-drift.

## Implementation files

| File | Role |
|------|------|
| [`Novolis.ProjectReferenceMode.props`](../build/Novolis.ProjectReferenceMode.props) | Trigger + workspace root |
| [`Novolis.ProjectReferenceMode.targets`](../build/Novolis.ProjectReferenceMode.targets) | Evaluation-time intersect substitution (required for NuGet static-graph restore) |
| [`Novolis.LibraryReferenceBridge.props`](../build/Novolis.LibraryReferenceBridge.props) | Copy map → `LibraryProjectMap` |
| [`Novolis.LibraryReference.targets`](../build/Novolis.LibraryReference.targets) | Expand `LibraryReference` after the map; default version `2026.1.*` |
| [`Novolis.Packaging.targets`](../build/Novolis.Packaging.targets) | Imports mode targets (all repos) |
| `Novolis.Workspaces.DotNet.Slnx` + `novolis-solution generate` | Map + meta-solution generator |

Stack analyzers (`Novolis.StackAnalyzers.props`) stay a separate analyzer `ProjectReference` (no PackageReference in csproj to substitute).

## LibraryReference

Every repo that imports [`Novolis.Packaging.targets`](../build/Novolis.Packaging.targets) already expands `LibraryReference`. No per-repo copy of the targets, and no `PackageReference` to `Novolis.MSBuild.LibraryReference` inside the forest (that package is for consumers outside the workspace; its targets are not on disk for the first static-graph restore).

```xml
<ItemGroup>
  <LibraryReference Include="Novolis.Math.Geometry" />
</ItemGroup>
```

Governance copies `@(NovolisPackageProject)` into `@(LibraryProjectMap)`, then expands the item: sibling `.csproj` exists → `ProjectReference`; missing → `PackageReference` at `2026.1.*` (`LibraryReferenceDefaultVersion`). This does not depend on `NovolisUseProjectReferences`.

Existing `PackageReference` items still use ProjectReference mode. Leave that mode in place until those items are switched.

The targets under [`build/libraryreference/`](../build/libraryreference/) match the package in `novolis-msbuild`. CI uses the copy because it clones governance and not `novolis-msbuild`. A full workspace uses the live package files. `verify-project-ref-mode.ps1` fails if the two copies drift.

## Related

- [nuget-only-policy.md](nuget-only-policy.md)
- [local-nuget-development.md](local-nuget-development.md) (deprecated folder-feed path)
- [README-Platform-Solution.md](../build/README-Platform-Solution.md)
