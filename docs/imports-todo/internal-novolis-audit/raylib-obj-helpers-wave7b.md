# Raylib — OBJ helpers (Wave 7b)

## What

Port **minimal OBJ loading** from Frank.GameEngine into `novolis-raylib` when the asset lane needs shared parsing:

| Source (Frank) | Target (Novolis) |
|----------------|------------------|
| `ObjHelper`, `ObjParser` | e.g. `Novolis.Raylib.Assets` or `Novolis.Raylib.Loaders` facet |
| Depends on | `Novolis.Math.Geometry` (`TriangleMesh`, optionally `Novolis.Math.Topology.Polygon`) |

**Out of scope:** Assimp, asset generator, embedded sample models ([wave-7b-raylib-obj.md](../extraction-briefs/wave-7b-raylib-obj.md)).

## Why

- Multiple dogfood/rendering paths build meshes manually; OBJ is the lowest-friction interchange for art iteration.
- Parsing belongs next to **Raylib host**, not Simulation or Physics — aligns with [gameengine-reference-policy.md](../gameengine-reference-policy.md).
- Prerequisite: Math geometry stable (post–BCL refactor publish wave).

## How

1. **Prerequisite gate**
   - Complete [math-bcl-refactor-publish-wave.md](math-bcl-refactor-publish-wave.md).
2. **New package or folder**
   - Prefer small packable project under `novolis-raylib/src/` with **PackageReference** to `Novolis.Math.Geometry` only.
3. **Port**
   - Strip GameObject/scene graph; output `TriangleMesh` or positions/indices arrays.
   - TUnit tests: cube.obj, quad.obj, negative face index handling.
4. **Wire dogfood**
   - One sample in `novolis-dogfooding` loads `.obj` via package API.
5. **Registry**
   - Add package to novolis registry when published.

## Status

**Deferred** until a Raylib app requires shared OBJ parsing (brief says “when geometry is stable”). Re-evaluate after Math GPR publish.

## Acceptance

- No `Frank.*` references; NuGet-only consumers build.
- Raylib package does not reference Simulation or Rendering.
