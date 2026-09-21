# Import: `Frank.WorkflowEngine` → Novolis

**Source:** `D:\frankrepos\Frank.WorkflowEngine`

**Status:** Extracted and redesigned in the local `novolis-workflow-engine`
repository. Six packable components and TUnit tests are under `src/` and
`tests/`; the deterministic host sample is in
`d:\novolis\novolis-lab\labs\workflows\WorkflowEngineLab`.

## What

Original shape: one packable library `Frank.WorkflowEngine` + sample app +
tests. The Novolis shape separates contracts, core execution, hosting, channel
input, mapping, and cron adapters.

**Frank package dependencies:**

```xml
Frank.CronJobs 2.0.0
Frank.Mapping 1.1.0
Frank.Channels.DependencyInjection 1.2.0
Microsoft.Extensions.Hosting.Abstractions
Microsoft.Extensions.Caching.Memory
```

Orchestration layer for multi-step workflows on top of channels, cron, and mapping.

## Why

- Capstone for **infrastructure lane** (messaging + scheduling + mapping).
- Not in P0 waves; no Novolis equivalent today.
- Useful for WireFish capture pipelines, codegen hosts, and long-running services.

## How

### Target

**New repo:** `novolis-workflow-engine` → `Novolis.WorkflowEngine.*`

Package grain:

- `Novolis.WorkflowEngine.Abstractions` — contracts, context, and results.
- `Novolis.WorkflowEngine` — named definitions and manual execution.
- `Novolis.WorkflowEngine.Hosting` — generic-host trigger pump.
- `Novolis.WorkflowEngine.Channels` — `Novolis.Messaging.Channels` adapter.
- `Novolis.WorkflowEngine.Mapping` — `Novolis.Mapping` adapter.
- `Novolis.WorkflowEngine.Scheduling` — `Novolis.Scheduling` cron adapter.

> **Note:** Org repo `novolis-workflows` is **GitHub Actions shared workflows** only. Do not put WorkflowEngine libraries there.

### Prerequisites (PackageReference only)

| Prerequisite | Doc |
|--------------|-----|
| `Novolis.Mapping` | [frank-mapping.md](frank-mapping.md) |
| `Novolis.Scheduling` | [frank-scheduling-cronjobs.md](frank-scheduling-cronjobs.md) |
| `Novolis.Messaging.Channels` | wave 0 (done in tree) |

### Port steps

1. Wait for all three on GPR `2026.1.*`.
2. Bootstrap `novolis-workflow-engine`; split contracts, execution, hosting, and
   source adapters; retarget dependencies to Novolis packages.
3. Port sample as `novolis-dogfooding` or docs sample (not shipped NuGet).
4. Rebuild tests with TUnit; no Frank.Testing package refs in production.
5. Modernize `Microsoft.Extensions.*` to .NET 10 aligned versions.

## Acceptance

- The WorkflowEngineLab sample runs against Novolis packages only.
- Documented in registry; frank-inventory updated.
