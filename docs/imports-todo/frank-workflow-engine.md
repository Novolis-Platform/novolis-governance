# Import: `Frank.WorkflowEngine` → Novolis

**Source:** `D:\frankrepos\Frank.WorkflowEngine`

## What

Single packable library `Frank.WorkflowEngine` + sample app + tests.

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

**New repo:** `novolis-workflows` → `Novolis.Workflows`

### Prerequisites (PackageReference only)

| Prerequisite | Doc |
|--------------|-----|
| `Novolis.Mapping` | [frank-mapping.md](frank-mapping.md) |
| `Novolis.Scheduling` | [frank-scheduling-cronjobs.md](frank-scheduling-cronjobs.md) |
| `Novolis.Messaging.Channels` | wave 0 (done in tree) |

### Port steps

1. Wait for all three on GPR `2026.1.*`.
2. Bootstrap `novolis-workflows`; port core library; retarget deps to Novolis packages.
3. Port sample as `novolis-dogfooding` or docs sample (not shipped NuGet).
4. Rebuild tests with TUnit; no Frank.Testing package refs in production.
5. Modernize `Microsoft.Extensions.*` to .NET 10 aligned versions.

## Acceptance

- `Frank.WorkflowEngine` sample runs against Novolis packages only.
- Documented in registry; frank-inventory updated.
