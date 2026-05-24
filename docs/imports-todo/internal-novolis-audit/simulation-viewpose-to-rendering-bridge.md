# Simulation `ViewPose` → Rendering `CameraSnapshot` bridge

## What

Standardize how apps connect **platform observers** (Simulation) to **ray tracing** (Rendering) without forbidden package references.

**Types today:**

| Package | Type | Role |
|---------|------|------|
| `Novolis.Simulation.View` | `ViewPose` | Position, target, up, FOV° — compose-time observer |
| `Novolis.Rendering.Runtime` | `CameraSnapshot` | Orthonormal basis + vertical FOV radians + aspect |
| `Novolis.Math.Geometry` | `ViewBasis` | Basis construction + primary ray direction |

**Gap:** Every trace app repeats:

```csharp
CameraSnapshot.LookAt(pose.Position, pose.Target, pose.Up, pose.FieldOfViewDegrees, aspect);
```

Dogfood (`RaytraceHello`, `SilkTrace*`) calls `CameraSnapshot` directly; simulation-first games (`DoomLite3D`, `ArtillerySimulator`) build `ViewPose` then bridge manually.

## Why

- [library-boundaries.md](../library-boundaries.md): **Rendering must not reference Simulation**; **Simulation must not reference Rendering**.
- A shared “bridge” package is usually overkill for a one-liner; the problem is **discoverability and drift** (different FOV conventions, up-axis fixes).
- Documenting the canonical bridge prevents apps from reimplementing `LookAt` math incorrectly.

## How

### Recommended: app-layer extension (no new package)

Add to **dogfooding shared helpers** or copy into each app:

```csharp
static CameraSnapshot ToCameraSnapshot(this ViewPose pose, float aspectRatio) =>
    CameraSnapshot.LookAt(
        pose.Position,
        pose.Target,
        pose.Up,
        pose.FieldOfViewDegrees,
        aspectRatio);
```

Place in `novolis-dogfooding` shared project if one exists, or document in `novolis-dogfooding/docs/design.md`.

### Platform improvements (allowed)

1. **`CameraSnapshot.LookAt`** — delegate to `ViewBasis` (see [rendering-viewbasis-ray-generation.md](rendering-viewbasis-ray-generation.md)) so Simulation and Rendering share basis math via Math only.
2. **`Simulation.View` XML docs** — “For path tracing, apps map to `CameraSnapshot.LookAt` at compose time; Rendering does not reference Simulation.”
3. **Optional `ViewPose` helper on Simulation side** — only if it does not reference Rendering:
   - e.g. `ViewPose.ToLookAtArgs()` returning `(position, target, up, fovDegrees)` tuple for apps — rarely worth it.

### Do not

- Add `CameraSnapshot.FromViewPose(ViewPose)` on Rendering (would require Rendering → Simulation).
- Add `Novolis.Simulation.View` reference to `Novolis.Rendering.*`.

### Pick / mouse rays

- Document that screen-space picking should use `ViewBasis.PrimaryRayDirection` with the same basis as `CameraSnapshot` (see RagdollPlay `BuildPickRay` — candidate to align in dogfood doc).

## Acceptance

- `novolis-dogfooding/docs` or governance imports-todo cross-link shows the one-liner bridge.
- No new forbidden dependency edges in solution graphs.
- At least one dogfood app uses the shared extension after [rendering-viewbasis-ray-generation.md](rendering-viewbasis-ray-generation.md) lands.
