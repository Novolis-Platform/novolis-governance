# Import: `Frank.GameEngine.Input` → Novolis

**Source:** `D:\frankrepos\Frank.GameEngine\src\Frank.GameEngine.Input`

## What

| Type | Role |
|------|------|
| `IInputSource` | Abstract input (keyboard/mouse) |
| `InputManager` | Global hook-backed implementation (SharpHook) |
| `NullInputSource` | No global hook — window API polls instead |
| `KeyboardKey`, converters | Engine-agnostic key enum + SharpHook mapping |

Used by `GameEngine.Initialize(IRenderer)` to start background input unless `NullInputSource` is passed (FPS samples with Raylib polling).

## Why

- **`novolis-raylib`** exposes per-frame `RayGameContext` polling; no shared abstraction for desktop games that want **global hooks** (borderless fullscreen, overlays) vs **null** for Raylib-native FPS.
- Dogfood (`DoomLite3D`, `XFighter`) duplicate input wiring patterns.
- Orthogonal to Simulation (no clocks) — fits Raylib host lane, not `Novolis.Simulation.*`.

## How

### Target

**`novolis-raylib`** — e.g. `Novolis.Raylib.Input`:

- Depends on BCL + SharpHook (same as Frank).
- **Must not** reference `Novolis.Simulation`.

### Port steps

1. Strip `Frank.GameEngine.*` namespaces → `Novolis.Raylib.Input`.
2. Keep `IInputSource` + `NullInputSource` as public surface; hide SharpHook in implementation assembly if desired.
3. Document pairing with `Novolis.Raylib.Game`: default null for Raylib-polling games; opt-in `InputManager` for global hook.
4. TUnit: `NullInputSource` no-op; converter round-trip tests (no hook in CI).
5. Update one sample in `novolis-dogfooding` to demonstrate both modes.

### Boundaries

- Do not pull `Frank.GameEngine.Core` — input only.
- Raylib bindings stay in `Novolis.Raylib.Bindings`; this is policy layer above.

## Acceptance

- Package published; README shows Raylib-poll vs global-hook choice.
- Zero Simulation package references.
