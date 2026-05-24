# Imports TODO — sourced from `D:\frankrepos`

Actionable backlog for **what to bring from local Frank.\* repos** into Novolis platform libraries. Each document: **what** (Frank source), **why** (gap in Novolis), **how** (target repo, wave, constraints).

**Source of truth:** `D:\frankrepos` (scanned 2026-05-25). Cross-check [frank-inventory.md](../frank-inventory.md) for P0 migration status.

**Not in scope here:** finishing in-flight work inside `d:\novolis` only (see [internal-novolis-audit/](internal-novolis-audit/)).

## Priority index

| Doc | Frank source | Novolis target | Priority |
|-----|--------------|----------------|----------|
| [frankrepos-catalog.md](frankrepos-catalog.md) | All repos under `D:\frankrepos` | — | Reference |
| [gameengine-assets-mesh-import.md](gameengine-assets-mesh-import.md) | `Frank.GameEngine.Assets` | `novolis-raylib` or `novolis-math` loaders facet | **P0** |
| [gameengine-input.md](gameengine-input.md) | `Frank.GameEngine.Input` | `novolis-raylib` (new facet) | **P0** |
| [gameengine-audio.md](gameengine-audio.md) | `Frank.GameEngine.Audio` | `novolis-audio` (new) or `novolis-raylib` | **P1** |
| [gameengine-2d-scene-rendering.md](gameengine-2d-scene-rendering.md) | Primitives 2D + `IRenderer2D` | `novolis-raylib` + optional `novolis-math` | **P1** |
| [gameengine-core-composition.md](gameengine-core-composition.md) | `Frank.GameEngine.Core` | Apps / thin `novolis-raylib.Game` extension | **P2** |
| [frank-mapping.md](frank-mapping.md) | `Frank.Mapping` (+ Analyzers, Documents) | `novolis-mapping` (new) | **P0** |
| [frank-messaging-facade.md](frank-messaging-facade.md) | `Frank.Messaging` | `novolis-messaging` | **P1** |
| [frank-workflow-engine.md](frank-workflow-engine.md) | `Frank.WorkflowEngine` | `novolis-workflows` (new) | **P2** |
| [frank-scheduling-cronjobs.md](frank-scheduling-cronjobs.md) | `Frank.CronJobs` | `novolis-scheduling` (new) | **P1** |
| [frank-entityframeworkcore.md](frank-entityframeworkcore.md) | `Frank.EntityFrameworkCore.*` | `novolis-data` / EF facet (new) | **P2** |
| [frank-codegen-devtools.md](frank-codegen-devtools.md) | Blazor JsInterop, SolutionManager, GitKit | `novolis-codegen` / devtools | **P2** |
| [frank-ml-remainder.md](frank-ml-remainder.md) | `Frank.ML` domain/presentation | `novolis-machinelearning`, apps | **P2** |
| [frank-networking-caching.md](frank-networking-caching.md) | `Frank.Networking`, `Frank.UmbrellaCache` | `novolis-transports` | **P3** |
| [frank-repos-explicit-skip.md](frank-repos-explicit-skip.md) | WPF, HttpDude, Finance, … | — | Policy |

## Conventions

- Extract/rebuild per [gameengine-reference-policy.md](../gameengine-reference-policy.md) and [frank-migration-runbook.md](../frank-migration-runbook.md).
- **PackageReference only** across Novolis repos; no `ProjectReference` into `D:\frankrepos`.
- Stack rules unchanged: [library-boundaries.md](../library-boundaries.md) (Math → Physics → Simulation; Raylib orthogonal).

## Suggested wave order (post P0 inventory)

```text
Mapping → Scheduling (CronJobs) → Messaging facade → WorkflowEngine
Parallel game lane: Assets/OBJ → Input → Audio → 2D (after novolis-raylib stable)
```
