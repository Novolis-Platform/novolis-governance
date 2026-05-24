# FleetCommander — platform patterns (mine, pieces only)

> **Status (2026-05-25):** WEGO replay **shipped** as `Novolis.Simulation.Replay` (+ optional `ISimulationEventStore<T>` spike). FleetCommander repo should adopt via PackageReference in headless tests. Master plan: [platform-import-plan.md](../platform-import-plan.md).

**Source:** `D:\repos\FleetCommander` (also on `D:\github\FleetCommander`)  
**Verdict:** **Product — do not import the repo.** Extract **patterns** into `novolis-simulation`, `novolis-transports`, `novolis-storage`, `novolis-machinelearning` as needed.

## What (worth borrowing)

| FleetCommander area | Types / behavior | Novolis target |
|---------------------|------------------|----------------|
| **WEGO simulation** | `RoundPlan` → lock → `RoundSimulator.Resolve` → `RoundPackage` / `GameEvent` list | `Novolis.Simulation.*` — deterministic round pipeline |
| **Replay** | `ReplayTimeline`, `RoundRecord`, `ReplayScrubber`, MessagePack `RoundPackageMessagePack` | New facet e.g. `Novolis.Simulation.Replay` |
| **Interpolation** | `Interpolate` / `InterpolateFromPackage` for render scrub | Simulation.View or app bridge |
| **Transport** | `FleetCommander.Transport.Abstractions` + InProcess `Channel` + SignalR | Inspiration for **test transport**; SignalR stays in apps |
| **Scenarios** | JSON scenarios under `.storage/blob/scenarios/` | `Novolis.Simulation.World.Builders` or scenario loader |
| **Headless CLI** | `FleetCommander.Headless` play-scenario | Dogfood pattern for simulation tests |
| **AI** | ONNX + heuristics; uses **Frank.ML.Foundation.Neural** NuGet | Already aligned with `novolis-machinelearning`; keep training in product |
| **Rendering** | Veldrid + Raylib adapters | **Skip** — use `novolis-rendering` + `novolis-raylib`; FC renderers are product-specific |

## Why

- [simulation-layer-policy.md](../simulation-layer-policy.md) lists **replay** under Simulation; **`Novolis.Simulation.Replay`** is implemented (WEGO-style timelines; racing still uses ticks).
- FleetCommander is the most mature **deterministic sim + replay + transport** Frank product on disk.
- Full import would violate boundaries (Veldrid, SignalR, Azure storage, game domain in platform).

## How

### P1 — Replay facet (shipped)

**Status:** `Novolis.Simulation.Replay` in `novolis-simulation` (`SimulationTimeline`, `InMemorySimulationRecorder`, `ReplayPlayback`, `SimultaneousPlanBuffer`).

Original spike steps:

1. ~~**Spike** in `novolis-simulation` (new project `Novolis.Simulation.Replay`):~~
   - `ISimulationRecorder` / `ISimulationPlayback` with immutable snapshots (BCL + optional MessagePack).
   - Borrow **data model** from `RoundRecord` / `ReplayTimeline`, not FC namespaces or ship/combat types.
2. **Unit tests:** record 10 ticks of `Novolis.Simulation.Racing` or a minimal `SimulationWorld` → playback equality.
3. **No** PackageReference to FleetCommander.

### P2 — WEGO planning (only if SCR/WEGO product needs it)

- `PlanBuffer` + simultaneous commit phase — generic names in `Novolis.Simulation.Abstractions`.
- Document difference vs real-time `SimulationClock` tick.

### P3 — Scenario JSON loader

- Extract **schema style** from FC scenario files for dogfood; keep game content in apps.

### Skip (duplicates)

| FC piece | Already in Novolis |
|----------|-------------------|
| Raylib rendering project | `novolis-raylib` |
| Neural foundation | `novolis-machinelearning` |
| General physics | `novolis-physics` |
| Aspire host | `novolis-aspire` (separate) |

## Acceptance

- Replay facet documented in `library-boundaries.md` placement table when implemented.
- Zero `FleetCommander.*` references in platform packages.
