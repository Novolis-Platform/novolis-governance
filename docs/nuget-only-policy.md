# NuGet-only dependency policy

**Indisputable rule:** Any dependency on another Novolis repository is consumed **only** via `PackageReference` from GitHub Packages (or a local feed during iterative work). Cross-repo `ProjectReference`, sibling-checkout MSBuild properties (`NovolisRenderingSrc`, etc.), and conditional dual reference blocks are **forbidden**.

## Allowed

| Scope | Reference style |
|-------|-----------------|
| Same repository | `ProjectReference` to projects under that repo's `src/`, `codegen/`, or `tests/` |
| Another Novolis repo | `PackageReference` + version in `Directory.Packages.props` (`2026.1.*` for GPR) |
| Third-party | `PackageReference` (nuget.org) |

## Forbidden

- `ProjectReference` whose path crosses into a sibling `novolis-*` directory (e.g. `..\..\..\novolis-codegen\...`)
- MSBuild properties that auto-detect sibling clones (`NovolisRenderingSrc`, `UseLocalNovolis`, …)
- `ItemGroup Condition` blocks that switch between `ProjectReference` and `PackageReference`
- Submodule or junction paths used for **compile-time** dependencies in apps or libraries

## Validation (required before merge)

```powershell
pwsh -File D:\novolis\novolis-governance\scripts\verify-nuget-only.ps1
```

CI should run this script on every library repo and on `novolis-dogfooding`.

## Proving a change is done

A dependency cleanup is **not complete** until:

1. `verify-nuget-only.ps1` exits 0 across the org checkout.
2. Affected libraries are **published** (merge to `main` → GitHub Packages, or `pack-local.ps1` → `artifacts/nuget-local`).
3. Consumers **restore and build** using packages only (`dotnet restore`, `dotnet build`).

See [nuget-setup.md](nuget-setup.md) and [local-nuget-development.md](local-nuget-development.md).

## Related

- [repository-policy.md](repository-policy.md)
- [novolis-dogfooding design](../../novolis-dogfooding/docs/design.md)
