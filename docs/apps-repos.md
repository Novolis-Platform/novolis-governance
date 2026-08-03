# Application repositories

Novolis ships two kinds of consumer repositories for executables:

| Repository | Purpose | Shared in-repo code | CI |
|------------|---------|---------------------|-----|
| [novolis-dogfooding](https://github.com/Novolis-Platform/novolis-dogfooding) | Cross-package integration smoke apps | `apps/shared/*` helpers allowed | None |
| [novolis-apps](https://github.com/Novolis-Platform/novolis-apps) | Production / daily-use desktop apps | **None** — each app under `src/` is self-contained | Build on PR and merge |

Both repos consume `Novolis.*` packages from GitHub Packages only (`2026.1.*`). See [nuget-only-policy.md](nuget-only-policy.md).

## Placement (non-negotiable)

| Kind | Where |
|------|--------|
| Product / sustained-use hosts (GeoPolity, CadStudio, Live Studio, …) | `novolis-apps/src/<AppName>/` |
| Package demos, labs, smokes, Hello* / RenderingAvalonia-style walkthroughs | `novolis-dogfooding/apps/<…>/` |
| Library repos (`novolis-geopolitics`, `novolis-raylib`, …) | **No `apps/` or `samples/` hosts** — packable `src/`, unit `tests/`, and `tools/` (codegen, seed gen) only |

Do not leave a playable Avalonia/Spectre/Raylib host under a library repo “for convenience.” Point README run commands at `novolis-apps` or `novolis-dogfooding`.

## Migration

Studio-style apps (Voice Studio, MeshBench, WireFish Viewer) will move from dogfooding to `novolis-apps` over time. Dogfooding keeps lightweight integration demos; `novolis-apps` keeps apps intended for sustained use.

Before migrating an app, eliminate `ProjectReference` to `Novolis.Dogfooding.*` shared projects — publish reusable logic as `Novolis.*` packages or keep it inside the app project.

## Layout

- **novolis-dogfooding:** `apps/<AppName>/`
- **novolis-apps:** `src/<AppName>/`

Neither repo is included in `Novolis.Platform.slnx` as an apps tree; product apps are built from `Novolis.Apps.slnx` / dogfooding solutions separately.
