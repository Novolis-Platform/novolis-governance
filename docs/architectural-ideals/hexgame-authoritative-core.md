# HexGame-aligned authoritative core (informative)

**Status:** Informative ideal — not a Novolis BCP 14 RFC and not a mandate to take a HexGame PackageReference.  
**External pattern:** [HexGame](https://github.com/frankhaugen/HexGame) (draft architecture 0.1).  
**Stack law:** [library-boundaries.md](../library-boundaries.md) — Math → Physics → Simulation; no Kit layers.

## Purpose

Describe how Novolis games can follow HexGame’s loop — commands in, authoritative advance, snapshots and effects out — by composing **existing** Novolis packages and **app-owned** application cores, without:

- Vendoring `HexGame.*` into the platform
- Adding a GameKit / `Novolis.HexGame.*` umbrella
- Putting game ticks or world orchestration in Physics

## Non-goals

- Re-hosting HexGame’s normative prose as Novolis law
- Stride Lite or any Stride engine island
- Requiring dogfood apps to rename types to HexGame names
- Shipping `Novolis.Game.Intent` or shared frame DTO packages before 2–3 apps share a shape

## Stack roles

| Layer | Owns | Must not own |
|-------|------|--------------|
| **Math** | Numbers, transforms, geometry — no time | `dt`, clocks, ticks, cameras, games |
| **Physics** | Forces, integrators, collision, domain solvers with **physical** `dt` | Tick order, `SimulationWorld`, replay, commands, players, cameras, HexGame frame |
| **Simulation** | Worlds, systems, `SimulationClock` / `SimulationStep`, replay, cameras, intents, orchestration | Raylib/Rendering package refs; product game rules; becoming a full game engine |
| **Apps** | `IGameApplication`-shaped Start/Tick/Save/Load, domain rules, effect catalogs, host composition | Pushing product rules into Physics or `Novolis.Game.*` domain models |
| **Raylib / Rendering** | Window loop, draw, input bindings, presenters | Authoritative simulation state |
| **Gaming** (`Novolis.Game.*`) | Identity, menus, lobby glue, procedural authoring, packaging | Simulation/Raylib refs; game domain models; owning Tick |

## Hard rule — Tick is Simulation + app

HexGame **Tick**, command dispatch into the core, world systems, replay, and presentation-oriented frame results belong in:

1. The **app** application core (owns the frame boundary), and  
2. **`Novolis.Simulation.*`** (clock, systems, world, replay, platform intents/cameras).

**Physics is a callee.** A Simulation system or app domain step may invoke `Novolis.Physics.*` with a physical `dt`. Physics never owns the HexGame frame or simulation-world tick ordering.

**Name trap:** `Novolis.Physics.Motion.SimulationPipeline` is an **integrator + force-model pipeline**, not simulation orchestration. Do not grow game-loop or tick APIs there. Prefer `FixedStepAccumulator` only under a Simulation/app tick owner.

## Composition

```text
Input adapter (Raylib / Silk / bot / replay)
    → commands / intents
App IGameApplication-shaped core (Start / Tick / Save / Load)
    → advances Novolis.Simulation (clock / systems / world)
        → optional Novolis.Physics (physical evolution inside a system)
    → snapshot + events + effects
Presenters / hosts (Raylib, Rendering, Avalonia) execute effects and present
```

| Concern | Location |
|---------|----------|
| Domain + Start/Tick/Save/Load | App project |
| Authoritative world / systems / clock / replay | `Novolis.Simulation.*` |
| Physical laws if needed | `Novolis.Physics.*` — called from Simulation systems or domain step |
| Keys → intents | Host input adapter → `Simulation.View` intents (or future `Game.Intent`) |
| Window host loop (non-authoritative) | `Novolis.Raylib.Hosting` / Silk TwoD game host |
| Present snapshot | App presenter → Raylib / Rendering |
| Headless tests | App tests → application core → Simulation (+ Physics only if domain uses it) |
| Lobby / identity / packaging | `Novolis.Game.*` |
| Launcher shell | `Novolis.Avalonia.*` when needed |

## Package map (existing homes)

| HexGame-shaped idea | Novolis home |
|---------------------|--------------|
| Tick / systems / world | `Novolis.Simulation.Abstractions`, `SimulationClock`, facets |
| Replay / determinism harness | `Novolis.Simulation.Replay` |
| Cameras / `MoveIntent` / `LookIntent` | `Novolis.Simulation.View` |
| Physical integration / collision | `Novolis.Physics.*` (callee) |
| Local graphical host phases | `Novolis.Raylib.Hosting` |
| Presentation adapters | `Novolis.Rendering.*` + app presenters |
| Editor save points | `Novolis.Snapshots.*` / workspaces — **not** sim step replay |
| NL / tool parse → queue | `Novolis.Commands.*` — **not** the game tick inbox |
| Identity / lobbies | `Novolis.Game.Identity.*`, `Novolis.Game.Multiplayer.*` |
| Tick leadership / rate limits | `Novolis.Messaging.Coordination.*` |

Do **not** add `PackageReference` to `HexGame.Abstractions`, `HexGame.Hosting`, or `HexGame.Testing` as platform foundation. Apps may study the external contracts; Novolis ships its own seams.

## Deferred (exit criteria)

| Candidate | Home if extracted | When |
|-----------|-------------------|------|
| `Novolis.Game.Intent` | `novolis-gaming` (BCL-only; no Simulation/Raylib/Physics refs) | 2–3 apps share the same player-command envelope |
| Shared frame request/result DTOs | `Novolis.Simulation.Abstractions` or stay app-local | Same convergence; never under Physics |
| Presentation `FrameSnapshots` facet | `novolis-simulation` | Multiple sims share a presenter-oriented shape; Replay already covers step records |
| Authoritative host glue | App + Multiplayer / Messaging | Product need; server advances app core → Simulation |

Never grow HexGame-style orchestration under Physics.

## Conformance checklist

Use in dogfood / PR review for HexGame-aligned games:

- [ ] Engine / GPU objects are projections, not authoritative save state  
- [ ] App Tick advances Simulation (same core path local and multiplayer-ready hosts aim for)  
- [ ] Physics is not the tick owner; no game command inbox in Physics  
- [ ] No `HexGame.*` PackageReference in platform library csproj files  
- [ ] No new GameKit / `Novolis.HexGame.*` umbrella package  
- [ ] `novolis-gaming` packages do not reference Simulation or Raylib  
- [ ] Headless tests can exercise the application core without a renderer when logic is under test  
- [ ] `Novolis.Commands.*` is not used as a substitute for player tick commands unless intentional  

## Related

- [library-boundaries.md](../library-boundaries.md)
- [simulation-layer-policy.md](../simulation-layer-policy.md)
- [gaming-layer-policy.md](../gaming-layer-policy.md)
- [gameengine-reference-policy.md](../gameengine-reference-policy.md) — Frank.GameEngine mining (distinct from HexGame)
- [HexGame repository](https://github.com/frankhaugen/HexGame)
