# NuGet-only dependency policy

**Indisputable rule:** Any dependency on another Novolis repository is consumed **only** via `PackageReference` from **GitHub Packages** or **nuget.org**. Cross-repo `ProjectReference`, sibling-checkout MSBuild properties (`NovolisRenderingSrc`, etc.), conditional dual reference blocks, and **local folder feeds** in `nuget.config` are **forbidden**.

> **Cursor agents:** Use GPR only — never `artifacts/nuget-local`, `pack-local.ps1`, or `novolis-local` sources. See `.cursor/rules/nuget-only-dependencies.mdc`.

## Allowed

| Scope | Reference style |
|-------|-----------------|
| Same repository | `ProjectReference` to projects under that repo's `src/`, `codegen/`, or `tests/` |
| Another Novolis repo | `PackageReference` + version in `Directory.Packages.props` (`2026.1.*` for GPR) |
| Third-party | `PackageReference` with a **pinned** version on nuget.org |

Float Novolis packages only on the **platform line** (`2026.1.*`). Do **not** use build-line floats such as `2026.1.10.*` or `2026.1.1.*` — those resolve to the latest CI build number and fail restore when that build was never published (publish race / failed merge).

Never publish throwaway versions such as `2026.1.99` or `1.0.0` to GitHub Packages. Under a `2026.1.*` float, `2026.1.99` sorts **above** real CI builds like `2026.1.10.36` and will silently win restore. Delete such versions from the org feed if they appear.

## GPR maintenance

```powershell
pwsh -File D:\novolis\novolis-governance\scripts\gpr-health-check.ps1
```

Full runbook: [gpr-maintenance.md](gpr-maintenance.md) (inventory, junk-version find/delete, build-line float scan).

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
2. Affected libraries are **published** to GitHub Packages (merge to `main` → CI publish).
3. Consumers **restore and build** using **nuget.org + github** only (`dotnet restore`, `dotnet build`).

See [nuget-setup.md](nuget-setup.md) and [local-nuget-development.md](local-nuget-development.md).

## Related

- [gpr-maintenance.md](gpr-maintenance.md) — GitHub Packages inventory and junk-version cleanup
- [repository-policy.md](repository-policy.md)
- [novolis-dogfooding design](../../novolis-dogfooding/docs/design.md)
