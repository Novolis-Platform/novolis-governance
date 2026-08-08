---
name: ArtillerySimulator dogfood
overview: Add a non-violent 3D dogfood app **ArtillerySimulator** that models a simplified NATO-style towed 155 mm gun firing over procedural terrain, using Novolis ballistics integration plus BVH terrain sweeps, with simple keyboard-driven inputs and minimal Raylib rendering.
todos:
  - id: scaffold-app
    content: Scaffold apps/ArtillerySimulator (csproj, Program, slnx, Directory.Packages.props, design.md row) with PackageReference to Ballistics, Collision.Simple, Raylib
    status: completed
  - id: terrain-mesh
    content: "Implement TerrainWorld: procedural height grid → StaticTriangleMesh/BvhStaticWorld + wireframe draw + R to reseed"
    status: completed
  - id: ballistics-loop
    content: "Implement ProjectileRun: ProjectileBallisticSimulation + per-step BallisticsQueries.SweepProjectileSphere until impact; trail buffer"
    status: completed
  - id: gun-inputs
    content: Implement GunModel preset (155mm simplified), keyboard inputs, muzzle pose from elevation/azimuth/charge
    status: completed
  - id: game-loop
    content: Implement ArtillerySimulatorGame + SimulationHud + OverviewCamera; non-violent visuals and fire/reset flow
    status: completed
  - id: validate
    content: Pack local NuGet, build Release, run app; optional flat vacuum sanity check vs textbook range
    status: completed
isProject: false
---

# ArtillerySimulator dogfood plan

## Goal

Scaffold [`apps/ArtillerySimulator`](d:\novolis\novolis-dogfooding\apps\ArtillerySimulator) in `novolis-dogfooding`: a **physics education / ballistic fidelity** demo, not a war game. User adjusts a few gun parameters, fires once, and watches a **single projectile** arc over **procedural terrain mesh** until terrain impact. No targets, explosions, or combat UI.

**Naming:** app, assembly, and window title use **ArtillerySimulator** (not ProjectileArc).

## What we dogfood (gaps BouncingBall did not hit)

| Package | Role in app |
|---------|-------------|
| [`Novolis.Physics.Ballistics`](d:\novolis\novolis-physics\src\Novolis.Physics.Ballistics) | `ProjectileBallisticSimulation`, `ProjectileState`, `ProjectileProfile`, `ProjectileBallisticEnvironment` — gravity + optional quadratic drag |
| [`Novolis.Physics.Collision.Simple`](d:\novolis\novolis-physics\src\Novolis.Physics.Collision.Simple) | `StaticTriangleMesh` + `BvhStaticWorld` for terrain; [`BallisticsQueries.SweepProjectileSphere`](d:\novolis\novolis-physics\src\Novolis.Physics.Ballistics\BallisticsQueries.cs) per sub-step |
| [`Novolis.Raylib`](d:\novolis\novolis-raylib) | Jam loop via [`RayGame.Run`](d:\novolis\novolis-dogfooding\apps\BouncingBall\Program.cs), world draw + [`HudText`](d:\novolis\novolis-raylib\src\Novolis.Raylib.Game\RayGame.cs) |

**Not in v1:** Simulation.World, sphere pile solver, ImGui panels, heightmap files (user chose **procedural** terrain).

## Physics model (fidelity without war-sim scope)

```mermaid
flowchart LR
  inputs[GunInputs] --> init[ProjectileState at muzzle]
  init --> step[ProjectileBallisticSimulation.Step]
  step --> sweep[BallisticsQueries.SweepProjectileSphere]
  sweep -->|miss| step
  sweep -->|hit| impact[Impact sample + HUD stats]
```

- **Integrator:** `ProjectileBallisticSimulation` at fixed `dt` (start with **1/120 s**, matching [`KnownPhysicsScenarioTests`](d:\novolis\novolis-physics\tests\Novolis.Physics.Unit\KnownPhysicsScenarioTests.cs)).
- **Environment:** `ProjectileBallisticEnvironment(9.80665, 1.225)`; toggle vacuum vs drag in HUD.
- **Drag profile (155 mm educational preset):** `ProjectileProfile` with ~43 kg mass, Cd ~0.35–0.5, reference area from 155 mm diameter — documented in code as *approximate training values*, not classified data.
- **Terrain collision:** each step, `BallisticsQueries.SweepProjectileSphere` from current position with displacement `velocity * dt` and small sphere radius (~0.08 m). On hit, interpolate impact point along segment (same pattern as [`CollisionSweepScenarioTests`](d:\novolis\novolis-physics\tests\Novolis.Physics.Unit\CollisionSweepScenarioTests.cs)).
- **Do not use** [`GroundImpact`](d:\novolis\novolis-physics\src\Novolis.Physics.Ballistics\GroundImpact.cs) for landing — it assumes **Y = 0** only; terrain is arbitrary height.

**Validation hook (dogfood + sanity):** flat terrain mode (procedural amplitude = 0) + vacuum → range should match closed-form tests within ~1% (same tolerances as physics unit tests). Optional small console/log line on fire with range, time of flight, impact speed.

## Gun model (NATO towed, simple)

Single preset: **“155 mm towed (M777-class, simplified)”** — static mesh or lines for tube + carriage at terrain edge, **non-animated**.

| Input | Control | Notes |
|-------|---------|--------|
| Quadrant elevation | `↑/↓` or `[` `]` | 0–800 mils or degrees in HUD (pick **degrees** for readability; show mils as secondary) |
| Azimuth | `←/→` | Degrees relative to +X (document on HUD) |
| Muzzle velocity | `1/2/3` charge presets | e.g. 400 / 600 / 800 m/s (educational steps, not real charge tables) |
| Drag | `D` toggle | Vacuum vs sea-level air |
| Fire | `Space` | Reset trail, run until impact |
| Reset | `R` | New random terrain seed + clear shot |

Muzzle position: fixed on a **firing baseline** at one end of the terrain patch, elevated slightly above local ground (raycast down or sample height function).

## Terrain (procedural mesh)

New app type [`TerrainWorld`](d:\novolis\novolis-dogfooding\apps\ArtillerySimulator\Game\TerrainWorld.cs) (name is generic, not “Battlefield”):

- Height function: smooth hills, e.g. sum of 2–3 sine/octave terms over XZ, amplitude ~30–80 m, ~500×500 m patch.
- Sample grid (e.g. 64×64), build triangle strip → `StaticTriangleMesh` → `BvhStaticWorld`.
- **Rendering:** wireframe or low-poly filled triangles via `DrawLine3D` / simple quad outline (match [`DoomLite3D` `LevelRenderer`](d:\novolis\novolis-dogfooding\apps\DoomLite3D\Game\LevelRenderer.cs) simplicity).
- `R` picks new `Random` seed for terrain + rebuild mesh.

**Expected library gap:** no `TerrainMeshBuilder` in Simulation — keep builder in app for v1; note as follow-up if reused.

## App structure (mirror BouncingBall Jam)

```
apps/ArtillerySimulator/
  Program.cs
  ArtillerySimulator.csproj
  Game/
    ArtillerySimulatorGame.cs    # RayGame loop, input, draw orchestration
    TerrainWorld.cs              # heightfield → BvhStaticWorld + draw
    GunModel.cs                  # preset constants, muzzle pose from elev/azimuth
    ProjectileRun.cs             # step + sweep loop, trail buffer
    SimulationHud.cs             # inputs, TOF, range, impact speed, mode flags
    OverviewCamera.cs            # fixed eye like BouncingBall FixedRoomCamera
```

## Project wiring

- Add to [`Novolis.Dogfooding.slnx`](d:\novolis\novolis-dogfooding\Novolis.Dogfooding.slnx).
- [`Directory.Packages.props`](d:\novolis\novolis-dogfooding\Directory.Packages.props): add `Novolis.Physics.Ballistics` `0.3.0-local`.
- **csproj:** `PackageReference` only per [dogfooding design](d:\novolis\novolis-dogfooding\docs\design.md) (restore from `artifacts/nuget-local` after pack). Match BouncingBall Raylib `ExcludeAssets` for `buildTransitive` if needed.
- Update [`docs/design.md`](d:\novolis\novolis-dogfooding\docs\design.md) apps table.

## Rendering (minimal, non-violent)

- Dark background, green/brown wire terrain, pale arc trail (`DrawLine` segments between stored positions).
- Muzzle flash: **none**; optional small neutral marker at impact (wire sphere or cross).
- HUD lines: elevation, azimuth, Mv, drag on/off, state (`Ready` / `In flight` / `Impacted`), range (horizontal), time of flight, impact coordinates.
- Window title: **Artillery Simulator** (physics demo subtitle in HUD footer).

## Out of scope (v1)

- Multiple simultaneous rounds, Coriolis, wind, MET tables, real NATO charge data, rotating gun animation, targeting reticles, damage.
- Unequal-radius or sphere-sphere physics (BouncingBall stack).
- ImGui (use keyboard + `HudText` only).
- Library changes unless dogfooding proves a clear missing helper (e.g. `SimulateUntilTerrainHit`); prefer app glue first, extract in physics follow-up.

## Build and validate

1. `pwsh d:\novolis\scripts\pack-novolis-local.ps1` (includes Ballistics).
2. `dotnet build Novolis.Dogfooding.slnx -c Release`.
3. `dotnet run --project apps/ArtillerySimulator -c Release`.
4. Manual: fire on hills — arc clears ridges; impacts on slope; vacuum flat range feels plausible.
5. Optional: add one **dogfood unit test** in physics or a tiny test project that runs vacuum flat sweep vs formula (can live in existing [`KnownPhysicsScenarioTests`](d:\novolis\novolis-physics\tests\Novolis.Physics.Unit\KnownPhysicsScenarioTests.cs) pattern) — only if time; not blocking app ship.

## Follow-up issues to watch (expected dogfood output)

- Missing high-level **ballistics + terrain sweep** API (app will loop manually).
- No terrain mesh builder in Simulation/Physics.
- Integrator `dt` / drag tuning docs for long-range 155 mm shots.
- Raylib: trail drawing perf if sample every frame at 120 Hz (subsample trail to every N steps).

