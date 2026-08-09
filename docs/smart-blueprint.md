# CadBlueprint (`novolis.cad.blueprint`)

**`CadBlueprint`** is the contextual companion to **`CadDocument`**.

| | CadDocument | CadBlueprint |
|---|---|---|
| Package | `Novolis.Cad.Primitives` | `Novolis.Cad.Blueprint` |
| Role | Full CAD SoT | Contextual / simplified projection |
| Knows | Sketch, solids, modifiers, meshes, walls, spaces, … | **Shells (exteriors)**, **walls**, **spaces (interiors)**, **openings** (doors / hatches / holes) |
| File | `.cadjson` | `.cadblueprint.json` |
| Format | `novolis.cad` | `novolis.cad.blueprint` |

Intended for **spaceships, space stations, seagoing ships, houses, and skyscrapers** — same schema; `context` is an open string (`spaceship`, `house`, …).

Smart HTML5 sheets (toggleable layer folders, print profiles) are **presentation** attached as `sheets[]` — not a second geometry SoT.

Schema: [`schemas/cad/novolis.cad.blueprint.schema.json`](../schemas/cad/novolis.cad.blueprint.schema.json)  
C#: `Novolis.Cad.Blueprint` (`CadBlueprint`, `CadBlueprintProjector`, `CadBlueprintDom`)  
HTML skeleton: [`schemas/cad/examples/smart-blueprint-skeleton.html`](../schemas/cad/examples/smart-blueprint-skeleton.html)

Related: [cadjson.md](./cadjson.md), [`novolis.cad.layers`](../schemas/cad/novolis.cad.layers.schema.json).

## Axioms

1. **Companion, not replacement** — Full authoring stays in `.cadjson`. Blueprint lifts walls / interiors / exteriors / openings for GA-style reasoning and export.
2. **Projection** — Prefer `CadBlueprintProjector.FromCadDocument`; do not invent sizes absent from CAD/lock sources.
3. **Openings are first-class** — Doors, hatches, and holes share one model (`kind` + clear size + host wall/shell).
4. **HTML5 sheets are optional** — `sheets[]` carry layer folders (`interior/*`, `dims/*`, …) for smart browser/print views.
5. **Screen ≠ plot** — Layer `defaultVisible` vs `plot`; presets snapshot intents.
6. **Generic kernel** — Must work for a house (NCS) without Ship/Calypso types. Ship orientation is a sheet `orientation`, not a hard dependency.
7. **Align with CAD layers** — Optional `layerId` / `layerName` map into `novolis.cad.layers`.

## Contextual elements

| Element | Meaning |
| --- | --- |
| `levels[]` | Deck / storey indexes |
| `shells[]` | Exterior / hull / facade envelopes |
| `walls[]` | Partitions / bulkheads |
| `spaces[]` | Interiors / rooms / cabins / zones |
| `openings[]` | Doors, hatches, holes, windows |
| `sheets[]` | Smart HTML presentation |

## HTML5 sheet DOM (when exporting a sheet)

| Hook | Role |
| --- | --- |
| `html[data-nbp-format="novolis.cad.blueprint"]` | Smart sheet document |
| `#nbp-manifest` | JSON — sheet slice or full blueprint |
| `#nbp-sheet` | Root SVG (mm viewBox) |
| `#nbp-ui` | Layer tree — hidden when printing |
| `g[data-nbp-layer]` | Matches `sheets[].layers[].id` |

See `CadBlueprintDom` for constants. Prefer CSS `:has()` toggles; script is progressive enhancement.

## Pipeline

```text
.cadjson  (+ .cadlayers.json)
    │
    ▼
CadBlueprintProjector.FromCadDocument
    │
    ▼
.cadblueprint.json
    │
    ├─ app / Ship Designer review
    └─ HTML emitter → smart .html (sheets[])
```

## Library placement

| Package | Owns |
| --- | --- |
| `Novolis.Cad.Blueprint` | `CadBlueprint` model, `CadBlueprintProjector`, sheet DTOs, DOM constants, (future) HTML writer |
| `Novolis.Cad.Primitives` | `CadDocument` only |
| `Novolis.Ship.*` | Optional ship adapters — must not be required to compile Cad.Blueprint |
| CalypsoCad | Golden consumer / lock → CAD → blueprint |

**Genericity test:** Draft Studio house → `CadBlueprint` with walls/spaces/openings and a plan sheet — zero Ship/Calypso references.

## Non-goals (v1)

- Replacing `.cadjson` authoring
- Interactive 2D CAD inside the HTML file
- Requiring npm/Node
- SceneBridge / 3D on the print path
