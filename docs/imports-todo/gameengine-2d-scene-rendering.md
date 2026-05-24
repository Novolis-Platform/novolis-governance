# Import: `Frank.GameEngine` 2D scene + `IRenderer2D`

**Source:**

- `D:\frankrepos\Frank.GameEngine\src\Frank.GameEngine.Primitives` — `Scene2D`, `GameObject2D`, `Camera2D`, `Sprite2D`, `Transform2D`
- `D:\frankrepos\Frank.GameEngine\src\Frank.GameEngine.Rendering` — `IRenderer2D`
- `D:\frankrepos\Frank.GameEngine\src\Frank.GameEngine.Rendering.RayLib` — `RayLibRenderer2D`, 3D overlay/underlay

## What

Orthographic 2D scene graph and renderer seam for HUDs, board games, and mini-games — **separate** from `novolis-rendering` path tracing.

## Why

- `novolis-rendering` is **3D framebuffer / RT** focused; no `Scene2D`.
- `novolis-raylib` has bindings and `Game` loop but no shared 2D scene model.
- Frank samples: `Hello2D`, `Pong`, `Battleship` (`Board<T>` in Primitives) validate the model.
- 3D Raylib apps use **Underlay2D/Overlay2D** for HUD — useful pattern for dogfood.

## How

### Split import (recommended)

| Piece | Target |
|-------|--------|
| `Board<T>`, `BoardHistory<T>` (if needed) | `Novolis.Math.Arrays` or `Novolis.Simulation.World` — policy: grid games = Simulation if stateful |
| `Scene2D`, `GameObject2D`, `Camera2D` | `Novolis.Raylib.Scene2D` (new, references Math for `Vector3` XZ or `Rgba32`) |
| `IRenderer2D` + Raylib impl | `Novolis.Raylib.Presentation` or `.Game` |

### Do not

- Merge into `novolis-math` as “2D types” — avoid `Vector2`; use `Vector3` Y=0 per stack policy.
- Reference `novolis-rendering` from Raylib 2D facet.

### Port steps

1. Spike: port `Scene2D` + `RayLibRenderer2D` minimal draw (solid quads).
2. One dogfood sample: Pong or Hello2D using PackageReference only.
3. Document 3D+2D overlay pattern (Underlay2D) in `novolis-raylib/docs`.

### Priority

**P1** after [gameengine-assets-mesh-import.md](gameengine-assets-mesh-import.md) and [gameengine-input.md](gameengine-input.md).

## Acceptance

- Sample runs from NuGet packages only.
- No `Frank.GameEngine.Rendering.MonoGame` unless separate decision (template already exists).
