# Scheduling — extract Frank.CronJobs

## What

Create a **`novolis-scheduling`** repo (name TBD) and migrate Frank.CronJobs subset:

| Frank | Novolis (proposed) |
|-------|---------------------|
| `Frank.CronJobs` | `Novolis.Scheduling` |
| `Frank.CronJobs.Cron` | `Novolis.Scheduling.Cron` or nested facet |

From [frank-inventory.md](../frank-inventory.md): P1 **conditional** — 2 packages, depends on Reflection + Testing; **0 facts** in quick scan; rebuild with tests.

## Why

- Cron scheduling is orthogonal to Math/Physics/Simulation stack — fits platform “commands / infrastructure” lane.
- Aspire and service hosts will need periodic jobs without pulling full Frank.Reflection into production.
- Reflection dependency should map to existing `novolis-codegen` subset, not duplicate Roslyn stack.

## How

1. **Spike (1–2 days)**
   - Shallow clone Frank.CronJobs; list public API and Frank dependencies.
   - Decide: extract verbatim vs rebuild minimal `ICronJob` + scheduler.
2. **Repo bootstrap**
   - Use `novolis-template-dotnet`; `net10.0`; TUnit from `novolis-testing`.
3. **Dependency policy**
   - `Novolis.Scheduling` → `Novolis.CodeGen.Reflection` (or Abstractions only) + BCL.
   - No dependency on Messaging unless job dispatch needs channels (explicit decision).
4. **Tests**
   - Port or rewrite cron expression tests; clock injection for determinism.
5. **Publish**
   - GPR `2026.1.*`; registry entry; frank-inventory table update.

## Blockers

- Testing package on GPR (migration gate).
- Reflection subset version alignment with codegen repo.

## Acceptance

- Reserved repo exists with green CI and at least one scheduled job sample in docs.
- frank-inventory P1 row moves to “migrated” or “rebuilt”.
