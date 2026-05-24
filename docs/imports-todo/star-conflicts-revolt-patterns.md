# Star Conflicts Revolt (SCR) — patterns for platform (mine, product)

**Source:** `D:\github\StarConflictsRevolt` (not under `D:\frankrepos`; ~54 projects).  
**Product rule:** `StarConflictsRevolt.Server.Simulation` stays **product** code. Platform is `Novolis.Simulation.*` per [library-boundaries.md](../library-boundaries.md).

## Why this was easy to miss

- SCR is **not** in the `d:\novolis` workspace or `D:\frankrepos` scan.
- It lives on **`D:\github\StarConflictsRevolt`** only (plus governance references to `StarConflictsRevolt.Server.Simulation`).
- It is **not** WEGO/tactical like FleetCommander — it is **4X strategy** with **server-authoritative event sourcing**.

## What SCR contains (high value)

| Area | Location | Pattern |
|------|----------|---------|
| **Event log replay** | `SessionAggregate.ReplayEvents`, `IEventStore`, `WorldEngine` | Append-only `IGameEvent` → apply to `World` |
| **Deterministic ticks** | `GameSim`, `Advance*Tick` events | Seeded RNG per session/tick for encounters |
| **Game model** | `StarConflictsRevolt.Server.GameModel` | Fleets, diplomacy, encounters, economy — **product domain** |
| **Storage facets** | JsonFiles, LiteDb, InMemory, Local | Event persistence — compare `novolis-storage` |
| **Coordination** | Garnet + InMemory | Session/coordination — not in Novolis yet |
| **Clients** | Raylib hosts, multiplayer SignalR | Apps compose Novolis + SCR — no platform merge |
| **Spatial spec consumer** | [inertial-frame-stack-spec.md](../inertial-frame-stack-spec.md) | Future `novolis-spatial` driven by SCR needs |

## What to import (pieces only)

### P1 — Event journal abstraction (platform)

SCR's `IGameEvent` + `ApplyTo(World)` is **domain-specific**. Platform analogue (new or extend `Novolis.Simulation.Replay`):

| Platform type | SCR analogue |
|---------------|--------------|
| `SimulationTimeline<TState>` | Snapshot after each tick |
| `ISimulationStepRunner<TState>` | Re-run one tick for integrity |
| **Future:** `ISimulationEvent<TState>` + `ISimulationEventStore` | `IGameEvent` + `IEventStore` — generic, no fleet/planet types |

**Do not** port `World`, `Fleet`, or `GameSim` into `Novolis.Simulation`.

### P1 — Replay (implemented 2026-05)

See **`Novolis.Simulation.Replay`** — tick timelines + `SimultaneousPlanBuffer` for WEGO-style commit collection. SCR should keep **event JSON lines** in product storage; optionally **also** emit platform timelines for debug/scrub.

### P2 — Encounter resolver pattern (inspiration)

`AbstractEncounterResolver` + deterministic `Random` — useful for **Physics/Simulation tests**, not a new package. Reimplement as small helper in product or `novolis-physics` tests.

### P2 — Storage event line format

`StarConflictsRevolt.Storage.Local` persisted event lines — **inspiration** for `novolis-storage` append-only facet if SCR needs shared tooling (not a full port).

### P3 — Garnet coordination

`Server.Coordination.Garnet` — product-only unless Novolis hosts multi-node sessions.

## Skip (duplicates or wrong lane)

| SCR piece | Reason |
|-----------|--------|
| Raylib bindings / codegen | `novolis-raylib` |
| Server.Simulation naming | Product; do not rename per governance |
| Client rendering (Veldrid path in FC; SCR uses Raylib hosts) | Apps |
| Full GameModel | Product |

## vs FleetCommander

| | FleetCommander | Star Conflicts Revolt |
|--|----------------|----------------------|
| Genre | WEGO tactical rounds | 4X tick + orders |
| Replay unit | `RoundRecord` + `GameEvent` list | `IGameEvent` stream + version |
| Platform fit | `SimultaneousPlanBuffer` + timeline | Event store interface + tick timeline |
| Repo path | `D:\repos\FleetCommander` | `D:\github\StarConflictsRevolt` |

## How SCR should consume platform work

1. **PackageReference** `Novolis.Simulation.Replay` for headless regression timelines.
2. Keep **`IGameEvent`** in `StarConflictsRevolt.Server.GameModel` — adapter maps tick end state → `SimulationStepRecord` when useful.
3. **PackageReference** `Novolis.Transports.Tcp.*` / Http for any custom wire protocols (not SignalR replacement).
4. **`novolis-spatial`** when spec moves from draft — SCR dogfoods first.

## Acceptance

- This doc linked from [README.md](README.md).
- No `ProjectReference` from `novolis-simulation` to SCR.
- SCR event store remains product; platform offers optional generic event-store **interface** only if second consumer appears.
