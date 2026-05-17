# Wave 11 — novolis-simulation + local NuGet platform

**Target repo:** [novolis-simulation](https://github.com/Novolis-Platform/novolis-simulation) (new)  
**Also:** governance, monorepo `nuget.config`, consumer migration (dogfooding, StarConflictsRevolt)

## Scope (in)

| Area | Novolis home |
|------|--------------|
| Planar occupancy (move, LOS, raycast, push-out) | `Novolis.Simulation.World` (from `GridCollision2D`) |
| View controllers, `ViewPose` | `Novolis.Simulation.View` (from `FirstPersonCamera`) |
| Planar agent motion (grid vs BVH) | `Novolis.Simulation.Kinematics` |
| Occupancy → `BvhStaticWorld` | `Novolis.Simulation.World.Builders` |
| Local NuGet feed standard | `d:\novolis\nuget.config`, `scripts/pack-novolis-local.ps1` |

## Out of scope (wave 11)

- Full camera variant implementations (orbit, third-person) — stubs OK
- `Novolis.Physics.Materials` (future)
- nuget.org publish of simulation (local feed first)

## Migrations

| Source | Destination |
|--------|-------------|
| `Novolis.Math.Geometry.GridCollision2D` | `Novolis.Simulation.World.PlanarOccupancy` + obsolete alias |
| `Novolis.Math.Geometry.FirstPersonCamera` | `Novolis.Simulation.View.YawPitchController` + obsolete alias |
| `Novolis.Physics.Collision.Simple.RoomMeshBuilder` | `Novolis.Simulation.World.Builders.OccupancyColumnMeshBuilder` |
| `Novolis.Physics.Collision.Simple.GridPhysicsMovement` | `Novolis.Simulation.Kinematics.PlanarAgent` |

## Done when

- `novolis-simulation` builds, tests pass, packs to `artifacts/nuget-local`
- Policies: [library-boundaries.md](../library-boundaries.md), [simulation-layer-policy.md](../simulation-layer-policy.md), [local-nuget-development.md](../local-nuget-development.md)
- DoomLite3D and SCR build with `PackageReference` only against local feed
- Math/physics retain obsolete forwards only (one release)

## Related

- [wave-9-doom-dogfood.md](wave-9-doom-dogfood.md)
- [wave-7-gameengine-math.md](wave-7-gameengine-math.md)
