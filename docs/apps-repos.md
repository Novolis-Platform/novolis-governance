# Executable repositories

Novolis has three shipping repositories and one staging repository for executables:

| Repository | Purpose | Shared in-repo code | CI |
|------------|---------|---------------------|-----|
| [novolis-tools](https://github.com/Novolis-Platform/novolis-tools) | NuGet-distributed `PackAsTool` commands for .NET developers | Tool-private code only; package libraries come through `PackageReference` | Changed-tool validation; merge publishes tool packages |
| [novolis-utilities](https://github.com/Novolis-Platform/novolis-utilities) | Small technical executables with no installer | Utility-private code only; no lab shared projects | Changed-utility validation; selected executable zip releases |
| [novolis-apps](https://github.com/Novolis-Platform/novolis-apps) | Production / daily-use product hosts | **None** — each app under `src/` is self-contained | Changed-app PR/merge matrices; selected-app release |
| [novolis-lab](https://github.com/Novolis-Platform/novolis-lab) | Fast package experiments, demos, labs, smokes, and benchmarks | `labs/shared/*` helpers allowed temporarily | Changed-lab validation; no release artifacts |

All four repositories consume `Novolis.*` packages from GitHub Packages only (`2026.1.*`) in committed projects. See [nuget-only-policy.md](nuget-only-policy.md).

## Placement (non-negotiable)

| Kind | Where |
|------|--------|
| .NET developer command installed with `dotnet tool install` | `novolis-tools/src/<ToolName>/` |
| Small technical executable with no installer | `novolis-utilities/src/<UtilityName>/` |
| Product / sustained-use hosts (GeoPolity, CAD Studio, Live Studio, Merglyph, …) | `novolis-apps/src/<AppName>/` |
| Package demos, labs, smokes, Hello* / RenderingAvalonia-style walkthroughs | `novolis-lab/labs/<…>/` |
| Library repos (`novolis-geopolitics`, `novolis-raylib`, …) | **No `apps/` or `samples/` hosts** — packable `src/`, unit `tests/`, and `tools/` (codegen, seed gen) only |

Do not leave a playable Avalonia/Spectre/Raylib/MAUI host or a shipped CLI under a library repo “for convenience.” Point README run commands at `novolis-apps`, `novolis-utilities`, or `novolis-lab`.

Library `tools/` directories are repository-private code generation and maintenance projects. They are not the `novolis-tools` product repository and must remain `IsPackable=false`.

`novolis-lab` is explicitly a staging area: a host starts there, proves a package, and then graduates to `novolis-tools`, `novolis-utilities`, or `novolis-apps`. It is not a release catalog. Every tree under `novolis-apps/src/` must declare at least one `Ship` channel in `build/apps.json`.

## Product repo shape

- **One product repository:** `novolis-apps` (not one GitHub repo per executable).
- **One solution per app:** `src/<App>/<App>.slnx` generated from `build/apps.json`.
- **Aggregate convenience only:** root `Novolis.Apps.slnx` is Linux-safe discovery; it is not the default PR or release graph and must never force Android/MAUI workloads onto Linux CI.
- **Authoritative catalog:** `novolis-apps/build/apps.json` — Local targets vs Ship channels, permissions, storage, and release metadata. Do not maintain parallel lists in scripts, README tables, and workflows.

`novolis-tools` has the same catalog principle in `build/tools.json`; `novolis-utilities` uses `build/utilities.json`; `novolis-lab` uses `build/labs.json` for changed-lab validation only.

## Local versus Ship

| Declaration | Meaning |
|-------------|---------|
| `local` | Platforms the app can restore/build/debug on a developer machine |
| `ship` | Release channels that produce artifacts (`windows-inno`, `android-apk`; Linux channel deferred until a named product needs it) |

An app may `local` more platforms than it `ship`s. Merglyph ships Android APK only; Windows remains local debug.

Tools and utilities do not have `Ship` channels from the app catalog:

- Tools publish NuGet tool packages from `novolis-tools`.
- Utilities publish executable artifacts from `novolis-utilities`; they never receive an installer.
- Labs do not publish.

## Migration

Studio-style lab hosts may move from `novolis-lab` to `novolis-apps` when they become sustained-use products. Before migrating, eliminate `ProjectReference` to `Novolis.Lab.*` shared projects — publish reusable logic as `Novolis.*` packages or keep it inside the app project.

## Layout

- **novolis-tools:** `src/<ToolName>/` + `build/tools.json`
- **novolis-utilities:** `src/<UtilityName>/` + `build/utilities.json`
- **novolis-lab:** `labs/<Name>/` + `build/labs.json`
- **novolis-apps:** `src/<AppName>/` + per-app `.slnx` + `build/apps.json`

`novolis-apps`, `novolis-utilities`, and `novolis-lab` are included in `Novolis.Platform.slnx` so platform work can be performed in one solution context. They retain their per-app, per-utility, and per-lab `.slnx` files for focused work. `novolis-tools` remains in the platform map because its reusable tool libraries are packable; its executable hosts consume published packages.

## Related

- [installer-data-lifecycle.md](installer-data-lifecycle.md)
- [executable-grains.md](executable-grains.md)
- [release-policy.md](release-policy.md)
- [library-boundaries.md](library-boundaries.md)
