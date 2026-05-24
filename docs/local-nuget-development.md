# Local NuGet development

Novolis library repos publish to a **shared local feed** for consumers (`novolis-dogfooding`, StarConflictsRevolt, etc.). Cross-repo `ProjectReference` is **forbidden** — see [nuget-only-policy.md](nuget-only-policy.md). Enforce with `scripts/verify-nuget-only.ps1`.

## Feed location

| Default | Override |
|---------|----------|
| `d:\novolis\artifacts\nuget-local` | Environment variable `NOVOLIS_LOCAL_FEED` |

Root [`nuget.config`](../../nuget.config) (monorepo checkout only) registers source `novolis-local` → `artifacts/nuget-local`. **Do not** add `novolis-local` to per-repo `nuget.config` files committed to GitHub — CI runners have no `../artifacts/nuget-local` path and restore fails with NU1301.

## Pack workflow

After changing a library:

```powershell
cd d:\novolis
.\scripts\pack-novolis-local.ps1
```

Or per repo:

```powershell
cd d:\novolis\novolis-math
.\scripts\pack-local.ps1
```

Pack order (handled by `pack-novolis-local.ps1`): math → physics → simulation → raylib → messaging → transports → avalonia → testing.

## Stack boundary verification

Before packing math / physics / simulation:

```powershell
.\novolis-governance\scripts\verify-stack-boundaries.ps1
```

See [library-boundaries.md](library-boundaries.md).

## Consumer setup

1. Ensure `nuget.config` includes the `novolis-local` source (repo root or machine-wide).
2. Use `PackageReference` only in `.csproj`.
3. Pin versions in `Directory.Packages.props` (e.g. `0.3.0-local` for iterative work).

```xml
<PackageVersion Include="Novolis.Math.Geometry" Version="0.3.0-local" />
```

4. `dotnet restore` then `dotnet build`.

## Versioning

| Context | Version |
|---------|---------|
| Local iterative | `x.y.z-local` — bump in consumer `Directory.Packages.props` when breaking API |
| CI / nuget.org | Semver from release tag — see [package-policy.md](package-policy.md) |

## Troubleshooting

| Issue | Fix |
|-------|-----|
| NU1102 package not found | Run `pack-novolis-local.ps1` |
| Stale assembly after pull | Re-pack changed repos |
| Wrong version resolved | Clear `obj/` / global-packages cache or bump `PackageVersion` |
| `Access to the path 'Microsoft.SourceLink.*.dll' is denied` on restore/pack | Another process (Rider, Visual Studio, `dotnet`) has locked DLLs under `%USERPROFILE%\.nuget\packages`. Close IDEs, run `dotnet build-server shutdown`, retry. `pack-novolis-local.ps1` uses a dedicated cache at `artifacts/nuget-packages-pack` and `/p:NovolisLocalPack=true` to reduce lock contention. If it still fails, delete the locked package folder (e.g. `microsoft.sourcelink.github`) while nothing is using it. |

**PowerShell 7:** `pack-novolis-local.ps1` requires `pwsh` (`#Requires -Version 7.0`). From Windows PowerShell 5.1 use:

```powershell
pwsh -File D:\novolis\scripts\pack-novolis-local.ps1
```

## Related

- [simulation-layer-policy.md](simulation-layer-policy.md)
- [package-policy.md](package-policy.md)
