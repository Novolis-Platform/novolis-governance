# Local NuGet development

Novolis library repos publish to a **shared local feed** for consumers (`novolis-dogfooding`, StarConflictsRevolt, etc.). Cross-repo `ProjectReference` is not used for compile-time dependencies.

## Feed location

| Default | Override |
|---------|----------|
| `d:\novolis\artifacts\nuget-local` | Environment variable `NOVOLIS_LOCAL_FEED` |

Root [`nuget.config`](../../nuget.config) (monorepo checkout) registers source `novolis-local` → `artifacts/nuget-local`.

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

## Related

- [simulation-layer-policy.md](simulation-layer-policy.md)
- [package-policy.md](package-policy.md)
