# Application repositories

Novolis ships two kinds of consumer repositories for executables:

| Repository | Purpose | Shared in-repo code | CI |
|------------|---------|---------------------|-----|
| [novolis-dogfooding](https://github.com/Novolis-Platform/novolis-dogfooding) | Package demos, labs, smokes, Hello* walkthroughs | `apps/shared/*` helpers allowed | None |
| [novolis-apps](https://github.com/Novolis-Platform/novolis-apps) | Production / daily-use product hosts | **None** — each app under `src/` is self-contained | Changed-app PR/merge matrices; selected-app release |

Both repos consume `Novolis.*` packages from GitHub Packages only (`2026.1.*`). See [nuget-only-policy.md](nuget-only-policy.md).

## Placement (non-negotiable)

| Kind | Where |
|------|--------|
| Product / sustained-use hosts (GeoPolity, CadStudio, Live Studio, Merglyph, …) | `novolis-apps/src/<AppName>/` |
| Package demos, labs, smokes, Hello* / RenderingAvalonia-style walkthroughs | `novolis-dogfooding/apps/<…>/` |
| Library repos (`novolis-geopolitics`, `novolis-raylib`, …) | **No `apps/` or `samples/` hosts** — packable `src/`, unit `tests/`, and `tools/` (codegen, seed gen) only |

Do not leave a playable Avalonia/Spectre/Raylib/MAUI host under a library repo “for convenience.” Point README run commands at `novolis-apps` or `novolis-dogfooding`.

Dogfooding is **not** a holding area for production hosts that have not yet been packaged. Every tree that remains under `novolis-apps/src/` must declare at least one `Ship` channel in `build/apps.json`. Completely unpublishable trees are removed from the product repo (Git history retains provenance); they are not relocated to dogfooding.

## Product repo shape

- **One product repository:** `novolis-apps` (not one GitHub repo per executable).
- **One solution per app:** `src/<App>/<App>.slnx` generated from `build/apps.json`.
- **Aggregate convenience only:** root `Novolis.Apps.slnx` is Linux-safe discovery; it is not the default PR or release graph and must never force Android/MAUI workloads onto Linux CI.
- **Authoritative catalog:** `novolis-apps/build/apps.json` — Local targets vs Ship channels, permissions, storage, and release metadata. Do not maintain parallel lists in scripts, README tables, and workflows.

## Local versus Ship

| Declaration | Meaning |
|-------------|---------|
| `local` | Platforms the app can restore/build/debug on a developer machine |
| `ship` | Release channels that produce artifacts (`windows-inno`, `android-apk`; Linux channel deferred until a named product needs it) |

An app may `local` more platforms than it `ship`s. Merglyph ships Android APK only; Windows remains local debug.

## Migration

Studio-style apps may move from dogfooding to `novolis-apps` when they become sustained-use products. Before migrating, eliminate `ProjectReference` to `Novolis.Dogfooding.*` shared projects — publish reusable logic as `Novolis.*` packages or keep it inside the app project.

## Layout

- **novolis-dogfooding:** `apps/<AppName>/`
- **novolis-apps:** `src/<AppName>/` + per-app `.slnx` + `build/apps.json`

Neither repo is included in `Novolis.Platform.slnx` as an apps tree; product apps are built from per-app solutions / the aggregate separately.

## Related

- [installer-data-lifecycle.md](installer-data-lifecycle.md)
- [release-policy.md](release-policy.md)
- [library-boundaries.md](library-boundaries.md)
