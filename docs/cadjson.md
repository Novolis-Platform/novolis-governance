# Cad JSON formats (`novolis.cad` / `novolis.cad.phys`)

Cross-repo interchange contracts for Draft Studio (and later converters). **No CadKit package** — schemas live here; apps implement load/save against them.

| Format | Extension | Schema | Role |
|--------|-----------|--------|------|
| `novolis.cad` | `.cadjson` | [`novolis.cad.schema.json`](../schemas/cad/novolis.cad.schema.json) | Authoring: analytic sketch + solids, layers, styles, NURBS curves |
| `novolis.cad.phys` | `.cadphys.json` | [`novolis.cad.phys.schema.json`](../schemas/cad/novolis.cad.phys.schema.json) | Extension: triangle meshes + colliders (sidecar or inline) |

Examples: [`schemas/cad/examples/`](../schemas/cad/examples/).

## Shared conventions

- UTF-8 JSON, **camelCase**, indented
- `format` + `schemaVersion` (both start at `1`)
- Right-handed, **+Y up**, planar sketch on **XZ** (`y = 0`)
- SI meters (`linearUnit: "meter"`, `unitScaleMeters`); angles in **radians**
- Vectors as `number[3]` = `[x, y, z]`; quaternions `[x, y, z, w]`
- Stable UUID entity/layer/mesh ids
- Open `properties` bags for round-trip / app data

**Do not** store `CompiledScene`, BVH, or GPU buffers in either file.

## Authoring vs tessellation

Sketch and solids stay **analytic** in `.cadjson` (lines, circles, boxes, **NURBS splines** with `degree` / `knots` / `controlPoints` / `weights`). Tessellation is derived into `.cadphys.json` or at draw time. Fit points may appear as authoring hints; the file of record for curves is evaluable NURBS.

## Pipeline

```text
.cadjson  →  (tessellate / export)  →  .cadphys.json  →  TriangleMesh + Physics colliders
.cadjson  →  (parametric tessellate in app)  →  SceneBuilder / CompiledScene
```

## Consumers

- **Draft Studio** — primary author of `.cadjson`; optional Export Phys for `.cadphys.json`
- **Concept Studio** — still uses `concept.json` in v1; format is designed so solids/groups *can* migrate later
- Future DXF / glTF / STEP converters — schemas keep layers, ACI-friendly `colorIndex`, NURBS, and mesh normals/UVs so converters do not invent geometry
