# Import: `Frank.GameEngine.Assets` → Novolis

**Source:** `D:\frankrepos\Frank.GameEngine\src\Frank.GameEngine.Assets`  
**Also:** `tools\Frank.GameEngine.Generators.AssetsGenerator`

## What

| Frank API | Role |
|-----------|------|
| `SceneMeshImporter` | AssimpNet: FBX/OBJ/glTF/… → `TriangleMesh` |
| `ObjParser`, `ObjHelper` | Lightweight OBJ without Assimp |
| `IAssetsProvider<T>`, embedded models | Sample/test meshes |
| `Frank.GameEngine.Generators.AssetsGenerator` | Roslyn analyzer: `AdditionalFiles` → typed path helpers |

`Frank.GameEngine.Assets.csproj` references **AssimpNet** and the analyzer; depends only on **Primitives** (→ use `Novolis.Math.Geometry.TriangleMesh` after port).

## Why

- `Novolis.Math.Geometry.TriangleMesh` has no loader; rendering dogfood and simulation builders hand-roll geometry.
- [wave-7b-raylib-obj.md](../extraction-briefs/wave-7b-raylib-obj.md) is deferred; **this repo is the concrete source** on disk.
- Path tracing (`novolis-rendering`) and BVH tests need real meshes without copying vertices into apps.

## How

### Target home (recommended)

**`novolis-avalonia`** — packable `Novolis.3D.Import` (AssimpNet → `TriangleMesh` / `EditableMesh`).

Also: **`novolis-raylib`** `Novolis.Raylib.Loaders` remains OBJ-only (no Assimp).

### Status

- **Done:** `Novolis.3D.Import` (`AssimpMeshImporter`, `MeshImportOptions`), SceneLab `importmesh` + **Import…**, CorellianFreighterBuilder `--import` uses the package.
- Publish `2026.1.*` to GPR before single-repo consumers without ProjectReference mode.

### Port steps

1. Copy `ObjParser`/`ObjHelper`; retarget output to `TriangleMesh` / `Vector3` (BCL).
2. Port `SceneMeshImporter` behind `IMeshImporter` interface; document supported formats.
3. Move analyzer to `novolis-raylib/codegen` or `novolis-analyzers` if shared — keep `PrivateAssets="all"` analyzer pattern.
4. TUnit: cube.obj, quad.obj, one Assimp sample (skip in CI if native DLL flaky — use OBJ gate).
5. Wire one dogfood app (`RaytraceHello` or SilkTrace) to load via package API.
6. Publish `2026.1.*`; add registry entry.

### Do not port

- `Frank.GameEngine.Primitives` types already in math.
- GameEngine `Scene` / `GameObject` graph — stay in apps.

### Dependencies

- Complete math BCL naming on GPR ([internal-novolis-audit/math-bcl-refactor-publish-wave.md](internal-novolis-audit/math-bcl-refactor-publish-wave.md)).
- [gameengine-reference-policy.md](../gameengine-reference-policy.md): no `Frank.*` package refs in production.

## Acceptance

- `dotnet add package Novolis.Raylib.Loaders` (name TBD) loads OBJ into `TriangleMesh`.
- No `ProjectReference` to `D:\frankrepos`.
- Assimp optional package documented separately if split.
