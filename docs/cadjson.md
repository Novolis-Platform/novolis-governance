# Cad JSON formats

Cross-repo interchange contracts for Draft Studio (and later converters). **No CadKit package** — schemas live here; apps implement load/save against them.

| Format | Extension | Schema | Role |
|--------|-----------|--------|------|
| `novolis.cad` | `.cadjson` | [`novolis.cad.schema.json`](../schemas/cad/novolis.cad.schema.json) | Authoring: analytic sketch + solids, walls/spaces, layer ids, optional `shapeId` |
| `novolis.cad.layers` | `.cadlayers.json` | [`novolis.cad.layers.schema.json`](../schemas/cad/novolis.cad.layers.schema.json) | Reusable layer catalog (NCS / ISO 13567 / custom) |
| `novolis.cad.shape` | `.cadshapejson` | [`novolis.cad.shape.schema.json`](../schemas/cad/novolis.cad.shape.schema.json) | Shared appearance / material metadata (no geometry) |
| `novolis.cad.phys` | `.cadphys.json` | [`novolis.cad.phys.schema.json`](../schemas/cad/novolis.cad.phys.schema.json) | Extension: triangle meshes + colliders (sidecar or inline) |

Examples: [`schemas/cad/examples/`](../schemas/cad/examples/) (`hull.*`, `calypso-toolkit-example.cadjson`, `ncs-house.cadlayers.json`, `calypso-ship.cadlayers.json`).

## Shared conventions

- UTF-8 JSON, **camelCase**, indented
- `format` + `schemaVersion` (both start at `1`)
- Right-handed, **+Y up**, planar sketch on **XZ** (`y = 0`)
- SI meters (`linearUnit: "meter"`, `unitScaleMeters`); angles in **radians**
- Vectors as `number[3]` = `[x, y, z]`; quaternions `[x, y, z, w]`
- Stable UUID entity / layer / shape / mesh ids
- Open `properties` bags for round-trip / app data

**Do not** store `CompiledScene`, BVH, or GPU buffers in these files.

## Authoring vs appearance vs tessellation

Sketch and solids stay **analytic** in `.cadjson` (lines, circles, boxes, **NURBS splines**, **walls**, **spaces**). Shared fill, stroke, and material presets live in `.cadshapejson` (or inline `shapes[]`) referenced by entity `shapeId` / wall `sides`. Tessellation is derived into `.cadphys.json` or at draw time.

### Walls and spaces (two-sided interiors)

- **`wall`** — directed baseline (`a`/`b` or `points`), `thickness`, `height`, `deck`. Optional `sides.a` / `sides.b` each carry a `shapeId`.
  - **Side A** = left of the directed baseline looking along `a→b` with world up `+Y` (right-hand rule). **Side B** = opposite.
  - Interior cameras pick the face whose outward normal points into the active space.
  - Fallback: entity `shapeId` / `color` / `material` when a side is omitted.
- **`space`** — closed footprint `points[]`, `deck`, clear `height`, optional `floorShapeId` / `ceilingShapeId`. Used for zone fills and interior eye placement (centroid + eye height).

Document `properties` conventions for multi-deck ships: `deckSpacingMeters`, `shipLoaMeters`, `beamMeters`, `heightMeters`.

### Engineering toolkit primitives (openings, ops, instances)

These additions keep `.cadjson` forward-compatible: apps may *store* the operation graph, but derive concrete `wall`/`space`/renderable solids in a later derivation step.

**C# package:** [`Novolis.Cad.Primitives`](https://github.com/Novolis-Platform/novolis-cad) (Avalonia-free DTOs). UI: `Novolis.Avalonia.Cad`.

- **`hooks[]`** (on any `entityBase`) — semantic anchors for runtime identification / camera targeting.
  - `id` (uuid), `tag` (string), `position` (vec3), optional `normal`, and optional `properties` bag.
- **`instance` / `arrayInstance`** — reusable placement of a prototype.
  - `instance`: `prototypeId` + `transform`.
  - `arrayInstance`: linear (`counts`×`spacing`) or radial (`axis` + `stepRadians` + `counts[0]`).
  - `realization`: `instances` (shared mesh), `separateCopies` (distinct meshes), or `fusedSolid` (one compound mesh).
- **`opening`** — door/hatch/window/ramp/iris placed as a 2D footprint (`footprint[]` polygon in XZ) on a `deck`.
  - Required: `openingType`, `deck`, `height`, `footprint`.
  - Optional: `hostWallId`, `connectsSides` (`["A","B"]`), and `swing` (door-specific).
  - Ship pressure fields (in `properties`): `pressureClass`, `clearWidth`, `clearHeight`, `sillHeight`, `airtightWhenClosed`, `leafState` (`Closed`|`Open`). Libraries: `Novolis.Ship.Primitives`.
- **`pressureVolume`** — sealed gas volume membership. Ship `properties`: `atmosphereClass`, `pressureKPa`, `memberSpaceIds[]`, `hullEntityIds[]`.
- **`airlock`** — outer/inner hatch pair + vestibule. Ship `properties`: `vestibuleSpaceId`, `outerOpeningId`, `innerOpeningId`.
- Document `properties` ship metrics: `shipLoaMeters`, `beamMeters`, `heightMeters`, `deckSpacingMeters`, `forwardPerpendicularZ`.
- **`weld`** — producer hint to merge operands that touch within tolerance.
  - Stack form: `inputId` / `sourceId` + `touchEpsilonMeters` (modifier on Mesh From Solid).
  - Legacy: `memberIds` (uuid[]), `touchEpsilonMeters`.
- **`boolean`** — evaluated solid set op between two operands (v1: AABB triangle filter, not full CSG).
  - Required: `operation` (`union|subtract|intersect`), `mode` (`region|solid`).
  - Operands: `leftId`/`rightId` and/or named `targetId`/`cutterId`.
- **`symmetry`** — mirror source about a plane; optional `mergeAtPlane`.
- **`connect`** — `memberIds` + `mode` (`group|joinMesh|compoundSolid|fuseSolid`); members resolve from evaluated CAD meshes when present.
- **`split`** — partition by `cuttingPlane` (v1) via `planePoint`/`normal`.
- **`meshFromSolid`** — adapter: `sourceId`, `linkMode` (`linked|detached|baked`).
- **`optimize`** / **`bridge`** — mesh modifier stack nodes (`inputId`).
- **`material`** / **`light`** / **`camera`** — Preview appearance nodes on the shared tree.
- **`mesh`** — stored triangle mesh (`meshVertices`, `meshIndices`).
- **`space.flags`** (optional cache) — derivation results for enclosure/hollowness:
  - `enclosed` (boolean), `hollow` (boolean).
  - Intended for persistence so apps can render “enclosed yet hollow” compartments without re-running full topology analysis.

Workspaces over one document: **CAD** (exact solids), **Modeling** (mesh modifiers), **Preview** (look). Same hierarchy; different tools and selection modes.

### Shape resolution

Prefer `shapeId` (and wall `sides`) for shared looks so `.cadjson` stays lean.

1. Resolve shape from `shapesDocument` (`.cadshapejson`) or inline `shapes[]`
2. Apply `extensions.appearance` / `extensions.material`
3. Entity-level `style`, `color`, and `material` **win when set** (local overrides)

### Layer catalogs

Optional `layersDocument` points at a `.cadlayers.json` catalog. Document `layers[].name` should match catalog names.

- [`ncs-house.cadlayers.json`](../schemas/cad/examples/ncs-house.cadlayers.json) — NCS-style house starter
- [`calypso-ship.cadlayers.json`](../schemas/cad/examples/calypso-ship.cadlayers.json) — custom ship layers for Calypso Rev G dogfood

## Pipeline

```text
.cadlayers.json ──(name / catalogId)──► .cadjson
.cadshapejson   ──(shapeId / sides)──► .cadjson
.cadjson  →  (tessellate / export)  →  .cadphys.json  →  TriangleMesh + Physics colliders
.cadjson  →  Novolis.Cad.SceneBridge.ToSceneDocument / SaveNov3dJson  →  .nov3djson (SceneDocument)
.cadjson  →  (parametric tessellate in app)  →  SceneBuilder / CompiledScene
```

**CAD Studio 3D:** authoring stays `.cadjson`; Model/Stage/render work on the bridged `.nov3djson`. Scene→Cad round-trip is out of scope for v1. Dual Agent Surfaces: Cad `:18775` / Scene `:18785` (same `Execute` catalogs as the UI).

## Consumers

- **Ship Designer** (`novolis-apps/src/ShipDesigner`) — freighter authoring home: Open/Save `.cadjson`, hatches, airtight validate, Calypso seed import
- **Novolis CAD Studio 3D** (`novolis-apps/src/CadStudio3D`) — product shell: Draft 2D/3D + Model + Stage/Render; Cad + Scene agent attach
- **Draft Studio** — Cad-only author of `.cadjson`; optional Export Phys for `.cadphys.json`
- **CalypsoCad** (dogfood) — generates Calypso Rev G walls/spaces; headless PNG / regenerate; exterior solids authored in Ship Designer survive regenerate
- Future DXF / glTF / STEP converters — schemas keep layers, ACI-friendly `colorIndex`, NURBS, and mesh normals/UVs
- Future **`.archijson`** (deferred) — building semantics will reference layer catalogs and project into `.cadjson`
