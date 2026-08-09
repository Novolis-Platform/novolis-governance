# Sketch JSON (`.sketchjson`)

Cross-repo interchange contract for Sketch Studio and `Novolis.Avalonia.Controls.Sketch`.

| | |
|---|---|
| Extension | `.sketchjson` |
| Implementation | [`SketchJson.cs`](https://github.com/Novolis-Platform/novolis-avalonia/blob/main/src/Novolis.Avalonia.Controls.Sketch/SketchJson.cs) |
| Product host | [Sketch Studio](https://github.com/Novolis-Platform/novolis-apps/tree/main/src/SketchStudio) |
| Dogfood | SketchLab |
| Related CAD | [cadjson.md](./cadjson.md) (different domain — do not mix) |

This page is the **wire contract**. There is no separate JSON Schema file; the C# DTO + round-trip tests are authoritative.

---

## Conventions

- UTF-8 JSON, **camelCase**, indented (`WriteIndented`)
- `System.Text.Json` with `JsonStringEnumConverter` (camelCase enum names)
- `DefaultIgnoreCondition = WhenWritingNull` — defaults omitted on write; readers apply defaults
- 2D points: `{ "x": number, "y": number }` in authoring / world units (screen-style Y down as drawn)
- Stable string element `id`s (GUID `"N"` hex when generated)
- **Not persisted:** selection, undo/redo stacks, viewport camera, tool, UI chrome

---

## Versions

| `version` | Meaning |
|-----------|---------|
| `1` | Legacy strokes only; missing `kind` → `stroke`; no rotation/groups/text/images expected |
| `2` | `kind`, `rotationDegrees`, `groupId`, text fields, `imagePngBase64` |
| `3` | Layers: `layers[]`, `activeLayerId`, element `layerId` |
| `≤ 0` | Treated as `1` on load |

Hosts write `3` when non-default layers are present. Old files continue to load.

---

## Document root

```json
{
  "version": 3,
  "grid": {
    "size": 20,
    "visible": true,
    "snapEnabled": true
  },
  "activeLayerId": "layer-default",
  "layers": [
    { "id": "layer-default", "name": "Layer 1" }
  ],
  "elements": []
}
```

| Field | Type | Default / notes |
|-------|------|-----------------|
| `version` | number | See table above |
| `layers` | array? | `{ id, name, visible?, locked? }` |
| `activeLayerId` | string? | Active layer for new elements |
| `grid.size` | number | `20` |
| `grid.visible` | boolean | `true` |
| `grid.snapEnabled` | boolean | `false` if omitted |
| `elements` | array | Ordered z-order (first = bottom) |

---

## Element object

Every element is a `StrokeShape`-shaped record:

| Field | Type | Write | Load default |
|-------|------|-------|--------------|
| `id` | string | always | new GUID if missing |
| `kind` | enum string | omit when `stroke` | `stroke` |
| `strokeColor` | string | `#RRGGBB` or `#AARRGGBB` | `#1e1e1e` |
| `strokeWidth` | number | | `2` if `≤ 0` |
| `fillColor` | string? | omit if empty (`#RRGGBB` / `#AARRGGBB`) | `null` |
| `strokeStyle` | enum string | omit when `solid` | `solid` |
| `closed` | boolean? | omit when false | `false` |
| `rotationDegrees` | number? | omit when `≈ 0` | `0` |
| `groupId` | string? | omit when none | `null` |
| `layerId` | string? | omit when default layer | default layer |
| `text` | string? | omit when empty | `null` |
| `fontSize` | number? | omit when default `16` for text kinds | `16` |
| `imagePngBase64` | string? | images only | `null` |
| `points` | `{x,y}[]` | geometry | `[]` |

### `kind` enum

| Value | Geometry |
|-------|----------|
| `stroke` | Polyline / freehand / box / ellipse / speech-bubble outline |
| `text` | `points[0]` = text anchor; `text` + `fontSize` |
| `textBox` | `points` define placement rect; border + `text` |
| `image` | `points` define placement rect; `imagePngBase64` holds PNG |

### `strokeStyle` enum

`solid` (default), `dashed`, `dotted`, `dashDot`, `stipple`

### Fuse / groups

`Ctrl+G` (Fuse) assigns the same `groupId` to every selected element. Selecting any member expands to the whole group for move/resize/rotate/delete. `Ctrl+Shift+G` clears `groupId`.

### Rotation

`rotationDegrees` is about the axis-aligned bounding box center of `points` (before rotation). Hit-testing and export apply the same transform.

---

## Full example (v2)

```json
{
  "version": 2,
  "grid": {
    "size": 20,
    "visible": true,
    "snapEnabled": true
  },
  "elements": [
    {
      "id": "a1b2c3d4e5f64789a0b1c2d3e4f50617",
      "strokeColor": "#1e1e1e",
      "strokeWidth": 2,
      "closed": true,
      "fillColor": "#2a9d8f",
      "points": [
        { "x": 40, "y": 40 },
        { "x": 120, "y": 40 },
        { "x": 120, "y": 100 },
        { "x": 40, "y": 100 },
        { "x": 40, "y": 40 }
      ]
    },
    {
      "id": "b2c3d4e5f6478901a2b3c4d5e6f70819",
      "kind": "text",
      "strokeColor": "#e63946",
      "text": "Hello",
      "fontSize": 22,
      "rotationDegrees": 15,
      "points": [
        { "x": 50, "y": 120 },
        { "x": 120, "y": 150 }
      ]
    },
    {
      "id": "c3d4e5f64789012a3b4c5d6e7f8091a0",
      "kind": "image",
      "imagePngBase64": "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==",
      "points": [
        { "x": 200, "y": 40 },
        { "x": 280, "y": 40 },
        { "x": 280, "y": 120 },
        { "x": 200, "y": 120 },
        { "x": 200, "y": 40 }
      ]
    }
  ]
}
```

---

## Legacy v1 load

```json
{
  "version": 1,
  "grid": { "size": 20, "visible": true, "snapEnabled": false },
  "elements": [
    {
      "id": "legacy",
      "strokeColor": "#000000",
      "strokeWidth": 2,
      "points": [ { "x": 1, "y": 2 }, { "x": 3, "y": 4 } ]
    }
  ]
}
```

Loads as `kind: stroke`, `rotationDegrees: 0`.

---

## What is not in the file

| Concern | Where it lives |
|---------|----------------|
| PNG / SVG export | Sketch Studio `SketchExport` (clipboard / Save As) |
| MRU / last path | `%LocalAppData%\Novolis\Sketch Studio\settings.json` |
| Active tool / UI | Session only |
| Selection / undo | Session only |

---

## Tests & hosts

- Unit: `Novolis.Avalonia.Unit` — `SketchDocumentTests` (gridify, undo, fuse, v1/v2 round-trip)
- Smoke: `dotnet run --project d:\novolis\novolis-apps\src\SketchStudio -- --smoke`
- Host documentation tree: [Sketch Studio docs/](https://github.com/Novolis-Platform/novolis-apps/blob/main/docs/sketch-studio/README.md)
