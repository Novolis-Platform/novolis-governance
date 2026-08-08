# NuGet-only dependency policy

**Indisputable rule:** In **committed source**, any dependency on another Novolis repository is expressed **only** via `PackageReference` from **GitHub Packages** or **nuget.org**. Cross-repo `ProjectReference` in `.csproj`, sibling-checkout MSBuild properties (`NovolisRenderingSrc`, etc.), conditional dual reference blocks in projects, and **local folder feeds** in `nuget.config` are **forbidden**.

**Exception (build-time only):** When building the meta solution `Novolis.Platform` (or with `-p:NovolisUseProjectReferences=true`), MSBuild may substitute existing `Novolis.*` PackageReferences for sibling ProjectReferences. See [platform-project-ref-mode.md](platform-project-ref-mode.md). That does **not** change committed `.csproj` files.

**Allowed committed alternative:** `LibraryReference` from package `Novolis.MSBuild.LibraryReference` (`novolis-msbuild`). It expands at build time to `ProjectReference` when a mapped/explicit `.csproj` exists, otherwise `PackageReference`. Do not commit cross-repo `ProjectReference` or dual Package/Project conditionals — use `LibraryReference` or `PackageReference` only.

> **Cursor agents:** Use GPR for publish/CI consumers — never `artifacts/nuget-local`, `pack-local.ps1`, or `novolis-local` sources. For local multi-repo iteration before publish, use `Novolis.Platform.slnx` (ProjectReference mode). See `.cursor/rules/nuget-only-dependencies.mdc`.

## Allowed

| Scope | Reference style |
|-------|-----------------|
| Same repository | `ProjectReference` to projects under that repo's `src/`, `codegen/`, or `tests/` |
| Another Novolis repo (committed) | `PackageReference` + version in `Directory.Packages.props` (`2026.1.*` for GPR), **or** `LibraryReference` (expands at build time; see `novolis-msbuild`) |
| Another Novolis repo (local meta build) | Same PackageReference in source; MSBuild substitutes via [platform-project-ref-mode.md](platform-project-ref-mode.md) |
| Third-party | `PackageReference` with a **pinned** version on nuget.org |

Float Novolis packages only on the **platform line** (`2026.1.*`). Do **not** use build-line floats such as `2026.1.10.*` or `2026.1.1.*` — those resolve to the latest CI build number and fail restore when that build was never published (publish race / failed merge).

Never publish throwaway versions such as `2026.1.99` or `1.0.0` to GitHub Packages. Under a `2026.1.*` float, `2026.1.99` sorts **above** real CI builds like `2026.1.10.36` and will silently win restore. Delete such versions from the org feed if they appear.

## GPR maintenance

```powershell
pwsh -File D:\novolis\novolis-governance\scripts\gpr-health-check.ps1
pwsh -File D:\novolis\novolis-governance\scripts\gpr-health-check.ps1 -SkipRemote
```

Covers: junk versions, build-line floats, local folder feeds, stale package ids
(`Host.NAudio` → `Output.NAudio`, …), committed cross-repo `ProjectReference` leaks, and ProjectReference-mode map health.
Optional: `-CheckBrokenDeps` for latest-nuspec → missing dependency versions.

Full runbook: [gpr-maintenance.md](gpr-maintenance.md).

## Forbidden

- `ProjectReference` in a **committed `.csproj`** whose path crosses into a sibling `novolis-*` directory
- MSBuild properties that auto-detect sibling clones (`NovolisRenderingSrc`, `UseLocalNovolis`, …)
- `ItemGroup Condition` blocks **in `.csproj`** that switch between `ProjectReference` and `PackageReference`
- Submodule or junction paths used for **compile-time** dependencies in apps or libraries
- Local folder NuGet feeds (`novolis-local`, `artifacts/nuget-local`, …)

## Validation (required before merge)

```powershell
pwsh -File D:\novolis\novolis-governance\scripts\verify-nuget-only.ps1
pwsh -File D:\novolis\novolis-governance\scripts\verify-project-ref-mode.ps1 -SkipBuild
pwsh -File D:\novolis\novolis-governance\scripts\verify-banned-packages.ps1
```

CI should run `verify-nuget-only.ps1` on every library repo and on `novolis-dogfooding`. Banned third-party stacks (Markdig, QuestPDF): [markdown-and-pdf-policy.md](markdown-and-pdf-policy.md).

## Proving a change is done

A dependency cleanup is **not complete** until:

1. `verify-nuget-only.ps1` exits 0 across the org checkout.
2. Affected libraries are **published** to GitHub Packages (merge to `main` → CI publish).
3. Consumers **restore and build** using **nuget.org + github** only (`dotnet restore`, `dotnet build`).

Local meta-solution builds prove API shape early; they do **not** replace step 2–3 for ship.

See [nuget-setup.md](nuget-setup.md) and [platform-project-ref-mode.md](platform-project-ref-mode.md).

## Related

- [platform-project-ref-mode.md](platform-project-ref-mode.md) — meta-solution ProjectReference substitution
- [gpr-maintenance.md](gpr-maintenance.md) — GitHub Packages inventory and junk-version cleanup
- [markdown-and-pdf-policy.md](markdown-and-pdf-policy.md) — Markdig / QuestPDF banned; Documents + Novolis Markdown
- [repository-policy.md](repository-policy.md)
- [novolis-dogfooding design](../../novolis-dogfooding/docs/design.md)
