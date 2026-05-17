# Wave 7 — GameEngine math subset

**Target repo:** [novolis-math](https://github.com/Novolis-Platform/novolis-math)  
**Source:** [frankhaugen/Frank.GameEngine](https://github.com/frankhaugen/Frank.GameEngine) (personal repo stays active)  
**Naming:** [frank-naming-and-structure.md](../frank-naming-and-structure.md)

## Scope (in)

| Frank | Novolis |
|-------|---------|
| `Frank.GameEngine.Primitives/SubPrimitives/*` | `Novolis.Math.Arrays` |
| Polygon, TriangleMesh, Shape, Transform*, Camera*, Face/Edge, IntPoint, IntRect, Rgba32, Grid, … | `Novolis.Math.Geometry` |
| `Array2DTests` | `Novolis.Math.Arrays.Tests` |
| `Polygon*`, `TriangleMesh*`, `MeshTransform3D*`, `TransformAndCamera*` tests | `Novolis.Math.Geometry.Tests` |

## Out of scope

- All `Rendering.*`, `Core`, `Input`, `Audio`, `Physics`, `Assets` (except wave 7b OBJ)
- `GameObject`, `Scene`, `Scene2D`, `Sprite2D`, `Board*`, `Rigidbody`, `Collision` record with GameObject
- Samples, AppHost, benchmarks

## Dependencies

- No `Frank.*` package references in production code
- TUnit assertions only for tests

## Done when

- Both packages build on `net10.0`
- Tests pass
- Registry entries added
- Frank.GameEngine README partial-migration block (no archive)

## Follow-up

- Wave 7b: `ObjHelper` → `novolis-raylib`
- Optional: merge `Frank.Collections` JSON `Array2D` helpers into `Novolis.Math.Arrays`
