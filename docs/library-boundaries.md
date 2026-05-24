# Library boundaries — Math, Physics, Simulation

Authoritative split for the numerical / physical / runtime stack. Applies to `novolis-math`, `novolis-physics`, and `novolis-simulation`.

**`novolis-raylib` is not part of this stack** — no package reference between Raylib and Simulation (either direction). Apps that need both wire them at the product layer.

There are **no “Kit” layers** in the platform (no GameKit, CadKit, LabKit packages). Product repos and hosts compose the stack directly.

## Stack (dependency direction)

```text
Math
  ↓
Physics
  ↓
Simulation
```

**Apps** (dogfooding, SCR, …) compose the stack. **`novolis-raylib`** is a separate graphics/input host — orthogonal to Math / Physics / Simulation.

**Simulation is not a game engine.** It is neutral orchestration: worlds, objects, systems, time, observation, recording, and replay.

## One-line rules

| Layer | Owns |
|-------|------|
| **Math** | Numbers, transforms, geometry, topology — **no time** |
| **Physics** | Physical evolution over time (forces, motion, collision response) |
| **Simulation** | Orchestration over time (world, systems, clocks, **all cameras**) |

---

## `Novolis.Math.*` — space and numbers only

**Repo:** `novolis-math`

Math is one library family with **facets** (separate packages, same repo). Geometry and topology are **parts of math**, not separate platform layers or dependency tiers.

| Facet (current / planned) | Role |
|---------------------------|------|
| `Novolis.Math.Arrays` | Dense grids, indices |
| `Novolis.Math.Geometry` | BCL-backed primitives (`Ray3`, `Sphere3`, meshes), intersections, BVH |
| `Novolis.Math.Topology` (planned) | Connectivity, faces/edges when distinct from metric geometry |

### BCL type first — always, no exception

When the BCL provides a type, **use it**. Do **not** add Novolis duplicates.

| Use (BCL) | Do not add |
|-----------|------------|
| `System.Numerics.Vector3` | `Vector3d`, `Vector3D`, custom 3-vectors |
| `System.Numerics.Quaternion` | `Quaterniond`, custom quaternions |
| `System.Numerics.Matrix4x4` | `Matrix4x4d`, custom 4×4 |
| `System.Numerics.Plane` | custom plane types mirroring BCL |

**Allowed Novolis types** only where the BCL has **no** equivalent: `Ray3`, `Sphere3`, `TriangleMesh`, `DenseGrid<T>`, topology records — composed from BCL primitives.

### No 2D vectors in the stack

- **Forbidden:** `System.Numerics.Vector2`, `Vector2D`, or any Novolis 2D vector type.
- **Planar XZ:** `System.Numerics.Vector3` with **`Y = 0`** (optional extension helpers on `Vector3`, not new vector types).

**Owns:**

- Pure spatial operations on BCL numerics
- Static helpers (e.g. `Matrix4x4.CreateLookAt`) that do **not** imply a clock, tick, or observer lifecycle

**Hard rule — no time in Math:**

If a concept needs **time**, `deltaTime`, clocks, ticks, integration steps, or “what happens next frame”, it does **not** belong in Math. That is **Physics** (physical evolution) or **Simulation** (orchestration and observation).

**Does not own:**

- Cameras (any rig, pose, or controller) → Simulation
- Forces, bodies, integrators → Physics
- Worlds, scenarios, replay → Simulation

---

## `Novolis.Physics.*` — physical rules over time

**Repo:** `novolis-physics`

**Depends on:** Math only (`Novolis.Math.*` facets as needed).

**Owns:**

- `RigidBody`, `MassProperties`, `Velocity`, `Acceleration`
- `Force`, `Torque`, `Material`, `Collider`, `Contact`, `Constraint`
- `Integrator`, `CollisionSolver`, domain solvers (ballistics, orbits, gravity, aero)
- Stepping state forward with `dt` (physical time evolution)

**Must not reference or know:**

- Cameras, players, AI, networking, rendering, ECS, games
- Product occupancy conventions, maze generation
- Simulation-world tick ordering (orchestration is Simulation)

---

## `Novolis.Simulation.*` — neutral runtime model

**Repo:** `novolis-simulation`

**Depends on:** Math, Physics only. Must not reference `Novolis.Raylib.*`, dogfooding, or SCR.

**Owns:**

- `SimulationWorld`, `SimulationClock`, `SimulationStep`
- `ISimulationSystem`, `ISimulationState`, `ISimulationObject`
- Snapshots, determinism policy, unit-system policy, tick ordering
- Scenario loading, recording / replay
- **All cameras** — rigs, poses, controllers, and composition:

```text
StaticCameraRig, OrbitCameraRig, TrackingCameraRig, ThirdPersonCamera
FirstPersonCamera (yaw/pitch), MapProjectionCamera, SensorView, ObserverFrame
ViewPose, projection/view records used by observers
```

Primitive third-person, orbit, first-person yaw/pitch, and CAD-style viewport cameras belong here. **Product-only** embellishments (e.g. run bobbing, weapon recoil shake, cinematic beats tied to a specific game) stay in **apps**, not platform Simulation.

**Answers:** *How do multiple systems participate in one evolving world?*

**Naming:** `StarConflictsRevolt.Server.Simulation` is **product** simulation. `Novolis.Simulation.*` is the **platform** library. Do not rename SCR projects.

---

## Outside the stack

### `novolis-rendering`

Separate repo and dependency island. Owns **CPU framebuffer production** (ray tracing, future software rasterizers). **Does not** open windows, call GPU APIs, or own platform cameras.

| Rule | Detail |
|------|--------|
| Rendering → Raylib | **Forbidden** |
| Rendering → Simulation | **Forbidden** |
| Raylib → Rendering | **Forbidden** (optional presenter adapters may live under Raylib) |
| Rendering → Math | Allowed (`Novolis.Math.Geometry` for `Rgba32`, meshes, rays) |
| Wiring Simulation ↔ Rendering ↔ Raylib | **Apps only** — `ViewPose` → `RenderCamera` → `IRayTracer` → host blit |

### `novolis-raylib`

Separate repo and dependency island. Owns host loop, draw, input bindings, GPU types (e.g. `Camera3D`).

| Rule | Detail |
|------|--------|
| Raylib → Simulation | **Forbidden** |
| Simulation → Raylib | **Forbidden** |
| Raylib → Math | Allowed when needed for types/interop (not Simulation) |
| Wiring Simulation ↔ Raylib | **Apps only** — adapt `ViewPose` / platform cameras to GPU at compose time |

Raylib does not own platform camera logic; apps bridge observers to the renderer.

### Apps (dogfooding, SCR, …)

Product rules, HUD, networking, highly specific camera feel (run bobbing, recoil). May reference Math, Physics, Simulation, and Raylib independently.

---

## Placement guide

| Concept | Home |
|---------|------|
| `Vector3`, `Matrix4x4`, mesh, BVH, `Ray3` hit | Math (Geometry facet; BCL vectors) |
| `Matrix4x4.CreateLookAt` (no camera record) | BCL / Math extension |
| `RigidBody` + integrate with `dt` | Physics |
| Sphere sweep + restitution | Physics |
| `SimulationClock`, tick order, replay | Simulation |
| Any `*Camera*`, `ViewPose`, observer rig | Simulation |
| Run bobbing / recoil / game-specific camera juice | App |
| Bridge Simulation camera → `RenderCamera` / `CameraSnapshot` for trace | App (uses Rendering + Simulation; neither lib references the other) |
| `IMaterial`, `Scene`, `CompiledScene`, `IRayTracingBackend` | Rendering (`Novolis.Rendering.*`) |
| `IFramePresenter`, CPU/GPU blit adapters | `Novolis.Raylib.Presentation`, `Novolis.Silk.Presentation`, or `Novolis.Rendering.Presentation.Silk` stub |
| Material compile → `GpuMaterial` | `Novolis.Rendering.Materials` |
| Scene compile → BVH + flat buffers | `Novolis.Rendering.Compile` (+ BVH structure in `Novolis.Math.Geometry`) |
| `Camera3D`, draw loop | Raylib only |
| Planar occupancy, LOS on a world | Simulation |

---

## Package dependency graph

**Stack (closed):**

```text
novolis-math       (Arrays, Geometry, Topology, core numerics)
novolis-physics    →  math
novolis-simulation →  math, physics
```

**Orthogonal (not in stack, no link to Simulation):**

```text
novolis-raylib       →  math only (if needed); never → simulation
novolis-rendering    →  math only; never → simulation or raylib
```

**Apps** may reference any combination; they own cross-repo glue.

---

## Transitional state (2026-05)

Wave 7–11 migrations may still place types in legacy packages. Prefer the boundaries above for **new** code.

| Legacy location | Target home |
|-----------------|-------------|
| `Camera` / camera controllers in `Novolis.Math.Geometry` | `Novolis.Simulation.View` |
| `Novolis.Math.Geometry.GridCollision2D` | `Novolis.Simulation.World` |
| `Novolis.Physics.Collision.Simple.RoomMeshBuilder` | `Novolis.Simulation.World.Builders` |
| `Novolis.Physics.Collision.Simple.GridPhysicsMovement` | `Novolis.Simulation.Kinematics` |
| `Novolis.Physics.Numerics` (`Vector3d`, …) | `System.Numerics` + `Novolis.Math.Geometry` primitives |
| BVH structure in Physics | `Novolis.Math.Geometry`; response stays Physics |

---

## Related

- [simulation-layer-policy.md](simulation-layer-policy.md) — operational summary
- [wave-7-gameengine-math.md](extraction-briefs/wave-7-gameengine-math.md)
- [wave-11-simulation-repo.md](extraction-briefs/wave-11-simulation-repo.md)
- [local-nuget-development.md](local-nuget-development.md)
- [gameengine-reference-policy.md](gameengine-reference-policy.md)
