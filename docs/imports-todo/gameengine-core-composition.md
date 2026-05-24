# Import: `Frank.GameEngine.Core` (composition facade)

**Source:** `D:\frankrepos\Frank.GameEngine\src\Frank.GameEngine.Core`

## What

| Type | Role |
|------|------|
| `GameEngine` / `GameEngine2D` | Wire physics, input, audio, renderer, scenes |
| `Simulator` | Simple update/draw loop host |
| `SceneManager`, `Scene2DManager` | Multi-scene switching |
| `RandomPile.*` | Aerodynamics toy calculators (overlap with `novolis-physics` domains) |

Also documents two execution models in `docs/architecture.md`: classic loop vs Raylib Generic Host channel experiment (`RayLibHostedPhysicsService`).

## Why

- Gap between **`Novolis.Raylib.Hosting`** (low-level) and **`Novolis.Simulation`** (worlds, clocks, replay) is wide for “small game” authors.
- Frank samples expect `new GameEngine()` + `Initialize(IRenderer)` ergonomics.

## Why defer (P2)

- High overlap risk with existing Novolis pieces if copied verbatim.
- Hosted channel pipeline **duplicates** concepts in `Novolis.Raylib.Hosting` with different API — confusing.
- `RandomPile` belongs in Physics or apps, not a new Core package.

## How (if pursued)

### Recommended approach: **patterns, not port**

1. Document in `novolis-raylib/docs` how to compose:
   - `RayGameContext` loop
   - `Novolis.Simulation.View` cameras
   - `Novolis.Physics.*` when needed
2. Optional thin **`Novolis.Raylib.Game.Scenes`** helper:
   - `IScene`, `SceneStack` — 50–100 lines, no Frank copy-paste
3. **Do not** port `GameEngine` class name or `Frank.GameEngine.Physics.PhysicsEngine` dependency.

### Alternative (not recommended)

Full port of `GameEngine` → requires adapter types for `Novolis.Math` + `Novolis.Raylib` renderer interface — large breaking surface.

## Acceptance

- Either closed as “documentation + SceneStack only” or explicit ADR before any `Novolis.Raylib.Core` package.
