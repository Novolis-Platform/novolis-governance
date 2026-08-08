---
name: C4D-lite naming realign
overview: Realign Avalonia.3D as lightweight C4D-inspired modeling (not a lighting product)—rename LightLab→SceneLab, then ship usable Object Manager tools for primitives, arrays/cloners, mesh boolean, and shaping modifiers wired through Math.Geometry and SceneSession.
todos:
  - id: rename-scenelab
    content: Rename LightLab → SceneLab (dogfood + avalonia sample + slnx); modeling-first titles/CLI
    status: completed
  - id: primitives-arrays
    content: Expand MeshPrimitiveKind + session/UI create (Box/Sphere/Cylinder/Cone/Plane/Capsule/Torus); Array/Cloner with count/offset/axis evaluated to real EditableMesh instances
    status: completed
  - id: mesh-boolean
    content: Add Boole generator (Union/Difference/Intersection) with Target/Cutter roles; evaluate via Novolis.Math.Geometry.MeshBoolean; viewport draws result mesh
    status: completed
  - id: shaping-tools
    content: Usable shaping modifiers Extrude/Inset/Bevel-ish (face extrude), Subdivision, Weld, Optimize, Bridge — stack on MeshFromPrimitive; property params + session actions
    status: completed
  - id: rebalance-ui-docs
    content: Modeling-first SceneToolStrip (Primitives | Array/Boole | Shape | Look); READMEs/MCP copy; lights as Look peers
    status: completed
  - id: modeling-samples
    content: Samples primitive-stage, cloner-row, boole-cut, look-setup .nov3djson
    status: completed
  - id: verify-scenelab
    content: Unit tests for boolean/array/shaping eval; build SceneLab; remove LightLab paths
    status: completed
isProject: false
---

# C4D-lite SceneLab — lightweight modeling tools

## Intent

“Cinema4D **Light**” = **not heavy**: a thin, usable Object Manager modeling stack — not a lighting product, and not Cad solids.

Keep packages: [`Novolis.Modeling.Scene`](novolis-avalonia/src/Novolis.Modeling.Scene), [`Novolis.Agent.Surface`](novolis-avalonia/src/Novolis.Agent.Surface), [`Novolis.Avalonia.3D`](novolis-avalonia/src/Novolis.Avalonia.3D). Do **not** edit [`avalonia_3d_cinemalight_d2ad4ea5.plan.md`](d:\novolis\.cursor\plans\avalonia_3d_cinemalight_d2ad4ea5.plan.md).

Today: placeholder primitives (Raylib cubes/spheres), Cloner/Symmetry/Extrude stubs in [`MeshStackEvaluator`](novolis-avalonia/src/Novolis.Modeling.Scene/Evaluation/MeshStackEvaluator.cs), toolstrip lights-first. Math already has real kernels to dogfood: [`MeshBoolean`](novolis-math/src/Novolis.Math.Geometry/MeshBoolean.cs), [`MeshWeld`](novolis-math/src/Novolis.Math.Geometry/MeshWeld.cs), [`MeshOptimize`](novolis-math/src/Novolis.Math.Geometry/MeshOptimize.cs), [`MeshBridge`](novolis-math/src/Novolis.Math.Geometry/MeshBridge.cs), [`EditableMesh`](novolis-math/src/Novolis.Math.Geometry/EditableMesh.cs).

## Naming

| Current | Change to |
|---------|-----------|
| Dogfood `LightLab` | **`SceneLab`** (`novolis-dogfooding/apps/avalonia/SceneLab`) |
| Sample `samples/LightLab` | **`SceneLab`** |
| Product copy | “SceneLab — lightweight C4D-inspired modeling” |

UI chrome: **Object Manager / Modeling / Look** only (no commercial trademarks).

Session id `scene`, ports `18785/18786`, MCP `scene_*` unchanged.

## Modeling tool surface (usable)

### 1. Primitives

Expand `MeshPrimitiveKind`: **Box, Sphere, Cylinder, Cone, Plane, Capsule, Torus**.

- Tessellate into `EditableMesh` in Modeling.Scene (new `PrimitiveMesher`) with size/segments params on `MeshNode`.
- Session: `addmesh` gains `primitive|box,sphere,…` (+ size/segments).
- Viewport draws triangle meshes from eval cache (not only Raylib DrawCube).

### 2. Arrays / Cloner

`GeneratorKind.Cloner` (Array) becomes real:

- Params: `count`, `offset` (vec3), optional radial later.
- Eval: instantiate `count` transformed copies of source mesh into world cache (EditableMesh transform + concat).
- Keep `Symmetry` as mirror clone on axis X/Y/Z.

### 3. Boole

New `GeneratorKind.Boole` with named roles **Target** / **Cutter** (fields `targetId`, `cutterId`, `booleanKind` = union|difference|intersection).

- Evaluate with `MeshBoolean.Apply` / `ApplySolid` on tessellated operands.
- Session action `addboole` + `setboole`; UI button **Boole** + property enum.
- Schema: extend `novolis.scene.schema.json` generator node.

### 4. Shaping tools (modifier stack)

Make modifiers actually rewrite mesh topology via Math.Geometry:

| Tool | Kind | Kernel |
|------|------|--------|
| Weld | `ModifierKind.Weld` | `MeshWeld.Apply` |
| Optimize | `Optimize` | `MeshOptimize.Apply` |
| Bridge | `Bridge` | `MeshBridge.Apply` (equal loops; v1 param stub + smoke path) |
| Subdivision | `Subdivision` | simple mid-edge split loop (local in Modeling.Scene if Math lacks subdiv) |
| Extrude | move from Generator → shaping on selected mesh / face-band approx | push faces along normal by distance |
| Bevel (lite) | new `Bevel` | chamfer outer AABB edges lightly (usable box soft-edge, not full B-rep) |

Evaluation order (narrow invalidation preserved):

```text
Primitive tessellate → Generators (Cloner / Symmetry / Boole) → Modifier stack → World transforms → Look → Viewport
```

[`SceneEvaluator`](novolis-avalonia/src/Novolis.Modeling.Scene/Evaluation/SceneEvaluator.cs) + `MeshStackEvaluator` must produce `EvaluatedMesh` (vertices/indices + world) consumed by [`SceneViewportRenderer`](novolis-avalonia/src/Novolis.Avalonia.3D/Services/SceneViewportRenderer.cs) via triangle draw (Raylib mesh or line/tri immediate mode).

### 5. UI / session / Definition

Rebalance [`SceneToolStrip`](novolis-avalonia/src/Novolis.Avalonia.3D/Ui/SceneToolStrip.cs):

```text
[New][Fit] | Box Sphere Cylinder Cone Plane Capsule Torus | Array Symmetry Boole | Extrude Bevel Weld Optimize Subdiv | Camera Material | Omni Spot Infinite Area | Delete
```

Extend [`SceneSessionContract`](novolis-avalonia/src/Novolis.Avalonia.3D/Session/SceneSessionContract.cs) `[AgentAction]`s + `AgentCommandDto` fields (`primitive`, `booleanKind`, `targetId`, `cutterId`, `segments`, `distance`). Property inspector shows generator/modifier params.

## Samples (SceneLab)

1. **primitive-stage** — several primitives on a plane  
2. **cloner-row** — box + Array/Cloner  
3. **boole-cut** — box Target − cylinder Cutter (Difference)  
4. **look-setup** — mesh + Spot/Infinite/Area (Look peer, not product name)

CLI: `--cloner`, `--boole`, `--look`.

## Delivery order

1. Rename LightLab → SceneLab + docs/MCP wording  
2. PrimitiveMesher + viewport triangle draw + create UI  
3. Cloner/Symmetry real eval  
4. Boole + schema + session  
5. Shaping modifiers wired to Math.Geometry  
6. Samples + unit tests (boolean difference, cloner count, weld round-trip) + verify build  

## Explicit non-goals

- CadDocument / commercial B-rep / Cad boolean tree merge  
- Full sculpt, UVs, animation timeline, IES lights  
- Renaming `Novolis.Avalonia.3D` package id  
- Local NuGet feeds

