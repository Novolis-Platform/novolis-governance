# Rendering — adopt `ViewBasis` for host primary rays

## What

Wire **`Novolis.Math.Geometry.ViewBasis`** into the Rendering host path so primary-ray direction math lives in one tested place:

| Location | Today | Target |
|----------|-------|--------|
| `PathTracerEngine.RenderSample` | Manual `tanHalfFov`, `u`/`v`, `Normalize(Forward + u*Right + v*Up)` | `ViewBasis.FromLookAt` + `ViewBasis.PrimaryRayDirection` |
| `CameraSnapshot.LookAt` | Duplicated Gram–Schmidt-style basis build | Delegate to `ViewBasis.FromLookAt`, map to snapshot fields |

`ViewBasis` and `RigidTransform` exist in Geometry but **no consumer references them yet** (grep 2026-05-25).

## Why

- Dogfood and trace apps already build observers via **`ViewPose`** (Simulation) or **`CameraSnapshot.LookAt`** (Rendering); the basis math is duplicated twice with slightly different epsilon handling.
- Centralizing in Math keeps **Simulation free of Rendering** while giving Rendering a single dependency for ray generation (allowed: Rendering → Math).
- Reduces risk that CPU path tracer and future software rasterizers diverge from Simulation pick rays (`BuildPickRay` in RagdollPlay, etc.).

## How

1. **`CameraSnapshot`** (`Novolis.Rendering.Runtime`)
   - In `LookAt`, call `ViewBasis.FromLookAt(position, target, up)` and copy `Forward`, `Right`, `Up` into the record.
   - Keep public surface unchanged (no new package dep beyond existing Geometry).
2. **`PathTracerEngine`** (`Novolis.Rendering.Backends.Cpu`)
   - Construct `var basis = new ViewBasis(camera.Forward, camera.Right, camera.Up)` once per tile or frame (or add `CameraSnapshot.ToViewBasis()` helper on Rendering side using those fields).
   - Replace lines 52–54 with `ViewBasis.PrimaryRayDirection(in basis, u, v, tanHalfFov, aspect)`.
3. **Tests**
   - Unit test: `CameraSnapshot.LookAt` vs `ViewBasis.FromLookAt` — forward/right/up agree within `GeometryConstants` scale.
   - Golden pixel or direction test: one pixel center ray matches previous implementation (regression).
4. **Optional follow-up (apps, not platform)**
   - RagdollPlay `BuildPickRay` can mirror `PrimaryRayDirection` for mouse picking consistency.

## Out of scope

- Moving GGX/glass/sky shading into Math (Rendering-only).
- ILGPU device kernels (see [ilgpu-bvh-slab-parity.md](ilgpu-bvh-slab-parity.md)).

## Acceptance

- No manual `Cross`/`Normalize` basis construction in `PathTracerEngine` for primary rays.
- `CameraSnapshot` and `ViewBasis` stay aligned under test.
