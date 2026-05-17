# Simulation layer policy

Defines how **math**, **physics**, **simulation**, and **raylib** divide responsibility. Applies to `novolis-simulation`, `novolis-math`, `novolis-physics`, and consumers.

## Layers

| Repo | Owns | Does not own |
|------|------|----------------|
| **novolis-math** | `DenseGrid`, meshes, transforms, topology, **`Camera`** (view/projection record + matrix extensions) | Input, occupancy semantics, controller behaviors, game rules |
| **novolis-physics** | Forces, integration, collision mathematics (BVH, sweeps, restitution), domain solvers (ballistics, orbits, gravity, aero) | Walkable-cell conventions, maze generation, third-person shoulder offset |
| **novolis-simulation** | World models (occupancy, LOS), composed motion (grid + BVH policy), view controllers, grid→mesh bridges | GPU draw, networking, product UI |
| **novolis-raylib** | Host loop, draw, input bindings, HUD helpers | Simulation rules |
| **Apps** (dogfooding, SCR) | Product logic | Reusable textbook physics |

## Cameras

| Concept | Home |
|---------|------|
| View/projection parameters → matrices | **Math** `Camera` + extensions |
| `ViewPose`, yaw/pitch controllers | **Simulation** `Novolis.Simulation.View` |
| `FirstPerson`, `ThirdPerson`, `Orbit`, `God`, `MapProjection`, etc. | **Simulation** (convenience controllers) |
| GPU / `Camera3D` interop | **Raylib** (host) |

Math stays unaware of “over the shoulder” offsets; simulation controllers produce poses, then adapters map to `Novolis.Math.Geometry.Camera`.

## Naming: Star Conflicts Revolt

`StarConflictsRevolt.Server.Simulation` is **product** simulation (event loop, server). **`Novolis.Simulation.*`** is the **platform** library. Do not rename SCR projects; use `PackageReference` to `Novolis.Simulation.*` when adopting platform APIs.

## Dependencies

```
novolis-math
novolis-physics → math
novolis-simulation → math, physics
novolis-raylib → (minimal math where needed)
consumers → simulation, physics, math, raylib (as needed)
```

Simulation must not reference raylib, dogfooding, or SCR.

## Related

- [wave-11-simulation-repo.md](extraction-briefs/wave-11-simulation-repo.md)
- [local-nuget-development.md](local-nuget-development.md)
- [gameengine-reference-policy.md](gameengine-reference-policy.md)
