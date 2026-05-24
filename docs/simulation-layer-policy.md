# Simulation layer policy (summary)

Operational summary for agents and maintainers. **Full boundaries:** [library-boundaries.md](library-boundaries.md).

## Stack (closed)

```text
Math → Physics → Simulation
```

Math facets: `Novolis.Math.Arrays`, `Novolis.Math.Geometry`, future `Novolis.Math.Topology`.

Simulation facets include `Novolis.Simulation.Racing` (headless racing sim; ML-agnostic). Neural evolution on racing lives in apps, not in `novolis-machinelearning`.

| Repo | In stack? | Role |
|------|-----------|------|
| **novolis-math** | Yes | Numbers, geometry, topology — **never time** |
| **novolis-physics** | Yes | Physical evolution with `dt` |
| **novolis-simulation** | Yes | Worlds, systems, clocks, **all cameras**, replay |
| **novolis-raylib** | **No** | Separate graphics host — **no dep on Simulation, Simulation does not dep on Raylib** |
| **Apps** | Compose | Wire stack + Raylib (and product rules) at app layer |

## Dependency rule

```
physics → math
simulation → math, physics
```

**Forbidden:** `Novolis.Raylib.*` ↔ `Novolis.Simulation.*` (either direction). Same for dogfooding/SCR inside platform Simulation packages.

## Type rules

- **BCL first, always:** `System.Numerics.Vector3`, `Quaternion`, `Matrix4x4` — no `Vector3d` / `Novolis.Physics.Numerics` duplicates.
- **No Vector2** in stack; planar XZ = `Vector3` with `Y = 0`.

## Time rule

| Need | Home |
|------|------|
| No time (static spatial/math) | Math |
| `dt`, integration, forces, motion | Physics |
| Tick order, scenario clock, replay | Simulation |

## Cameras

**All platform cameras → Simulation.**

**Apps:** product-specific feel (run bobbing, recoil); **bridge** Simulation observers to Raylib `Camera3D` — not in either library.

## SCR vs platform

`StarConflictsRevolt.Server.Simulation` = product. `Novolis.Simulation.*` = platform.

## Related

- [library-boundaries.md](library-boundaries.md)
- [wave-11-simulation-repo.md](extraction-briefs/wave-11-simulation-repo.md)
- [local-nuget-development.md](local-nuget-development.md)
