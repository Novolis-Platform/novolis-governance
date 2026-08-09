# Library boundaries — platform layer stack

Authoritative dependency law for Novolis libraries. Numeric spine: `novolis-math`, `novolis-physics`, `novolis-simulation`. Product spine continues through `novolis-gaming` and `novolis-avalonia` into apps.

**`novolis-raylib` is not part of this stack** — no package reference between Raylib and Simulation (either direction). Apps that need both wire them at the product layer.

There are **no “Kit” layers** in the platform (no GameKit, CadKit, LabKit packages). Product repos and hosts compose the stack directly.

## Stack (dependency direction)

```text
Math
  ↓
Physics
  ↓
Simulation
  ↓
Gaming (Novolis.Game.*)
  ↓
Avalonia (Novolis.Avalonia.*)
  ↓
Apps
```

Lower layers **must not** reference higher layers. Same-layer / peer facet refs are fine. **Apps** compose any combination.

**Avalonia isolation:** only `Novolis.Avalonia.*` libraries may take `Avalonia` / `Avalonia.*` package references. Math, Physics, Simulation, Gaming, Economy, Astro, Rendering, Raylib, Agent, Cad, Audio, etc. stay Avalonia-free. Product apps may reference Avalonia directly.

Enforced by `Novolis.Analyzers.StackBoundaries` (`NOV2006`, `NOV2007`) and `scripts/verify-layer-boundaries.ps1`.

**`novolis-raylib`** remains a separate graphics/input host — orthogonal to the spine (never ↔ Simulation).

**Simulation is not a game engine.** It is neutral orchestration: worlds, objects, systems, time, observation, recording, and replay. HexGame-style game ticks belong in Simulation and apps — not in Physics (see [hexgame-authoritative-core.md](architectural-ideals/hexgame-authoritative-core.md)).

## One-line rules

| Layer | Owns |
|-------|------|
| **Math** | Numbers, transforms, geometry, topology — **no time** |
| **Physics** | Physical evolution over time (forces, motion, collision response) |
| **Simulation** | Orchestration over time (world, systems, clocks, **all cameras**) |
| **Gaming** | Authoring / shipping glue (`Novolis.Game.*`) — no Avalonia |
| **Avalonia** | UI controls and hosts (`Novolis.Avalonia.*`) — only layer that may depend on Avalonia UI packages |
| **Apps** | Product composition in `novolis-apps`; package demos in `novolis-dogfooding` (not under library `apps/`) |

---

## `Novolis.Math.*` — space and numbers only

**Repo:** `novolis-math`

Math is one library family with **facets** (separate packages, same repo). Geometry and topology are **parts of math**, not separate platform layers or dependency tiers.

| Facet (current / planned) | Role |
|---------------------------|------|
| `Novolis.Math.Arrays` | Dense grids, indices, packed voxel chunks (`ChunkCoord3`, `VoxelChunk` 16³) |
| `Novolis.Math.Geometry` | BCL-backed primitives (`Ray`, `Sphere`, meshes), intersections, BVH |
| `Novolis.Math.Topology` | Connectivity: polygon, face, edge, shape |
| `Novolis.Math.Measure` | Scalar `Length`/`Size`/`Thickness`/`Rect` in points (page/print extents; no `Vector2`) |

### BCL type first — always, no exception

When the BCL provides a type, **use it**. Do **not** add Novolis duplicates.

| Use (BCL) | Do not add |
|-----------|------------|
| `System.Numerics.Vector3` | `Vector3d`, `Vector3D`, custom 3-vectors |
| `System.Numerics.Quaternion` | `Quaterniond`, custom quaternions |
| `System.Numerics.Matrix4x4` | `Matrix4x4d`, custom 4×4 |
| `System.Numerics.Plane` | custom plane types mirroring BCL |

**Allowed Novolis types** only where the BCL has **no** equivalent: `Ray`, `Sphere`, `AxisAlignedBox`, `TriangleMesh`, `DenseGrid<T>`, `VoxelChunk` / `ChunkCoord3`, topology records — composed from BCL primitives.

### No dimension suffixes or 2D types in Math public APIs

- **Forbidden:** `*3` / `*2D` suffixes on public Math types or members (`Ray3`, `Sphere3`, `AxisAlignedBox3`, …).
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
StaticCameraRig, OrbitCameraRig, TrackingCameraRig, FreeLookCameraRig
FirstPersonCameraRig, ThirdPersonCameraRig, CharacterCameraDirector, CharacterMotor
LookIntent / MoveIntent, YawPitchController, ViewPose, ObserverFrame
```

- **Tiles** (`Novolis.Simulation.Tiles`) — Prison Architect–style layered maps, edge walls/doors, room flood-fill, grid A*
- **Voxels** (`Novolis.Simulation.Voxels` + `.Meshing`) — chunked block worlds, streaming, terrain fill, face-culled / greedy mesh → `Math.Geometry` (no GPU)

Primitive third-person, orbit, first-person yaw/pitch, and CAD-style viewport cameras belong here. **Product-only** embellishments (e.g. run bobbing, weapon recoil shake, cinematic beats tied to a specific game) stay in **apps**, not platform Simulation.

**Humanoid skeleton / mocap target:** `Novolis.Simulation.Humanoid` — Mixamo/Unity-compatible bone ids, T-pose bind, FK/IK (including two-bone and FABRIK chain), animation clips. Physics ragdoll bridge: `Novolis.Simulation.Humanoid.Physics`. Import: `Novolis.Simulation.Humanoid.Import` (BVH / glTF joints). CPU skin: `Novolis.Simulation.Humanoid.Skinning`. Game clip banks: `Novolis.Game.Humanoid` (gaming repo).

### Kinematics vs skeletal IK (do not confuse)

| Package | Owns | Does **not** own |
|---------|------|------------------|
| `Novolis.Simulation.Humanoid` | FK (`HumanoidPoseSolver`), two-bone IK, FABRIK chains, full-body multi-effector helpers, clip schema | Planar agent locomotion |
| `Novolis.Simulation.Kinematics` | Planar XZ agent move (`PlanarAgent`) via occupancy / sphere sweep | Skeletal FK/IK, bone targets |
| `Novolis.Physics.Joints` | Distance / swing / hinge **dynamics** (ragdolls) | Target-reaching IK |

**Forbidden:** IK solvers in `Novolis.Math.*`; putting `TwoBoneIk` / FABRIK into `Simulation.Kinematics`; treating joint constraint projection as IK.

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
| Raylib → Rendering | **Forbidden** |
| Rendering → Raylib.Runtime | **Only** via `Novolis.Rendering.Presentation.Raylib` (blit adapter) |
| Rendering → Math | Allowed (`Novolis.Math.Geometry` for `Rgba32`, meshes, rays) |
| Wiring Simulation ↔ Rendering ↔ Raylib | **Apps only** — `ViewPose` → `CameraSnapshot` → `IRayTracingBackend` → host blit |

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
| `Vector3`, `Matrix4x4`, mesh, BVH, `Ray` hit | Math (Geometry facet; BCL vectors) |
| `Matrix4x4.CreateLookAt` (no camera record) | BCL / Math extension |
| `RigidBody` + integrate with `dt` | Physics |
| Sphere sweep + restitution | Physics |
| `SimulationClock`, tick order, replay | Simulation |
| Any `*Camera*`, `ViewPose`, observer rig | Simulation |
| Run bobbing / recoil / game-specific camera juice | App |
| Bridge Simulation camera → `CameraSnapshot` for trace | App (uses Rendering + Simulation; neither lib references the other) |
| `IMaterial`, `Scene`, `CompiledScene`, `IRayTracingBackend` | Rendering (`Novolis.Rendering.*`) |
| `IFramePresenter`, CPU/GPU blit adapters | `Novolis.Rendering.Presentation.Raylib`, `Novolis.Rendering.Presentation.Silk` |
| Material compile → `GpuMaterial` | `Novolis.Rendering.Materials` |
| Scene compile → BVH + flat buffers | `Novolis.Rendering.Compile` (+ BVH structure in `Novolis.Math.Geometry`) |
| `Camera3D`, draw loop | Raylib only |
| Planar occupancy, LOS on a world | Simulation |
| Edge-wall tile maps, room flood-fill, grid A* | `Novolis.Simulation.Tiles` |
| Chunked voxel world, dig/place, streamer | `Novolis.Simulation.Voxels` |
| Voxel → triangle mesh (face cull / greedy) | `Novolis.Simulation.Voxels.Meshing` |
| Packed 16³ block storage | `Novolis.Math.Arrays` (`VoxelChunk`) |
| Headless racing sim (tracks, sensors, tick loop) | `Novolis.Simulation.Racing` |
| NN evolution on racing (trainer, neural car controller) | Apps (e.g. `novolis-dogfooding` `NeuralRacing`) — not `Novolis.MachineLearning.*` |

---

## Package dependency graph

**Spine (closed, low → high):**

```text
novolis-math          (Arrays, Geometry, Topology, core numerics)
novolis-physics       →  math
novolis-simulation    →  math, physics
  (facets: Abstractions, World, View, Tiles, Voxels, Voxels.Meshing, Kinematics, World.Builders, Racing, …)
novolis-gaming        →  math / physics / simulation as needed; never → Avalonia UI packages
novolis-avalonia      →  math…gaming + Avalonia.* ; never pull Avalonia into lower layers
apps / dogfood        →  compose freely (including Avalonia + Raylib + Simulation)
```

**Orthogonal (not on the spine ranks; still Avalonia-free libraries):**

```text
novolis-machinelearning  (Core, Neural.*, AutoMl — building blocks only; no domain packages)
```

```text
novolis-raylib       →  math only (if needed); never → simulation; never → Avalonia
novolis-rendering    →  math only; never → simulation or raylib; never → Avalonia
```

```text
novolis-cad          →  Math only (Cad.Primitives, Cad.Blueprint, Cad.Evaluation, Cad.SceneBridge)
                         Avalonia-free .cadjson interchange + Cad→3D bridge
                         Must not host mesh scene graphs (those are Novolis.3D.*)
novolis-avalonia     →  also ships Avalonia-free Novolis.3D.Scene / Novolis.3D.Modeling / Novolis.3D.Import
                         (.nov3djson mesh graph; Modeling = Math.Geometry mesh-ops façade; Assimp import);
                         UI is Novolis.Avalonia.3D / Cad / Ship.Design
```

**Cad vs 3D cameras:** document pose bags (`CadCamera`, `CameraNode`) may live in Cad/3D DTOs. Orbit / free-look **controllers** and `ViewPose` stay in `Novolis.Simulation.View`. Apps/Avalonia compose DTO poses → ViewPose. Do not put Rendering soft-bridges in Cad libraries — apps wire Cad/3D lights → Rendering.

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
| Custom `Vector3d` / `Novolis.Physics.Numerics` (removed) | `System.Numerics` + `Novolis.Math.Geometry` primitives |
| BVH structure in Physics | `Novolis.Math.Geometry`; response stays Physics |
| `StaticTriangleMesh` in Physics | deleted — use `Novolis.Math.Geometry.TriangleMesh` |

---

## Related

- [hexgame-authoritative-core.md](architectural-ideals/hexgame-authoritative-core.md) — HexGame-shaped game loops: Tick in Simulation/apps; Physics is a callee only (no HexGame NuGet / no GameKit)
- [workspace-snapshot-timeline.md](architectural-ideals/workspace-snapshot-timeline.md) — editor workspaces, save points, and branchable timelines (`novolis-workspaces`)
- [gaming-layer-policy.md](gaming-layer-policy.md) — `novolis-gaming` authoring lane (identity, menus, multiplayer glue, session protocol)
- [simulation-layer-policy.md](simulation-layer-policy.md) — operational summary
- [wave-7-gameengine-math.md](extraction-briefs/wave-7-gameengine-math.md)
- [wave-11-simulation-repo.md](extraction-briefs/wave-11-simulation-repo.md)
- [local-nuget-development.md](local-nuget-development.md)
- [gameengine-reference-policy.md](gameengine-reference-policy.md)
