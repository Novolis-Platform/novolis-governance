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
| Core numerics (TBD) | `Vector3D`, `QuaternionD`, `Matrix4x4D`, `Transform3D`, `Interval`, units, tolerances |
| `Novolis.Math.Geometry` | `Ray`, `Mesh`, primitives, intersections, BVH structure/queries |
| `Novolis.Math.Topology` (planned) | Connectivity, faces/edges, meshes-as-topology when distinct from metric geometry |

**Owns:**

- Pure spatial and numeric types and operations
- Static helpers (e.g. `LookAt` matrix from eye/at/up) that do **not** imply a clock, tick, or observer lifecycle

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
| `Vector3D`, `Matrix4x4D`, mesh, BVH, ray hit | Math (Geometry / Topology facets) |
| `LookAt` matrix helper (no clock) | Math |
| `RigidBody` + integrate with `dt` | Physics |
| Sphere sweep + restitution | Physics |
| `SimulationClock`, tick order, replay | Simulation |
| Any `*Camera*`, `ViewPose`, observer rig | Simulation |
| Run bobbing / recoil / game-specific camera juice | App |
| Bridge Simulation camera → `Camera3D` for draw | App (uses Raylib + Simulation; neither lib references the other) |
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
novolis-raylib     →  math only (if needed); never → simulation
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
| Vectors in `Novolis.Physics.Numerics` | Math core numerics facet |
| BVH structure in Physics | `Novolis.Math.Geometry`; response stays Physics |

---

## Related

- [simulation-layer-policy.md](simulation-layer-policy.md) — operational summary
- [wave-7-gameengine-math.md](extraction-briefs/wave-7-gameengine-math.md)
- [wave-11-simulation-repo.md](extraction-briefs/wave-11-simulation-repo.md)
- [local-nuget-development.md](local-nuget-development.md)
- [gameengine-reference-policy.md](gameengine-reference-policy.md)
