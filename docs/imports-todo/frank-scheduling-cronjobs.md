# Import: `Frank.CronJobs` → Novolis

**Source:** `D:\frankrepos\Frank.CronJobs`

## What

| Package | Role |
|---------|------|
| `Frank.CronJobs` | Hosted cron job registration, DI integration |
| `Frank.CronJobs.Cron` | Cron expression parsing/scheduling |

**Dependencies:** `Frank.Reflection` (→ `novolis-codegen` subset after wave 5).

**Consumer:** `Frank.WorkflowEngine` (`PackageReference` CronJobs 2.0.0, Mapping 1.1.0, Channels 1.2.0).

## Why

- Listed P1 **conditional** in [frank-inventory.md](../frank-inventory.md); blocks WorkflowEngine port.
- Aspire/service hosts need periodic jobs without copying cron parsing.
- 0 tests in quick inventory — rebuild with TUnit during port.

## How

### Target

**New repo:** `novolis-scheduling` (name per [frank-naming-and-structure.md](../frank-naming-and-structure.md))

| Novolis package | Frank source |
|-----------------|--------------|
| `Novolis.Scheduling` | `Frank.CronJobs` |
| `Novolis.Scheduling.Cron` | `Frank.CronJobs.Cron` (or nested) |

### Port steps

1. Spike public API surface + Reflection usage.
2. Bootstrap repo; `net10.0`; `Novolis.Testing.TUnit`.
3. Port or rewrite with deterministic clock injection for tests.
4. Publish before [frank-workflow-engine.md](frank-workflow-engine.md).
5. Add registry + inventory row.

### Blockers

- `novolis-testing` and codegen Reflection on GPR.

## Acceptance

- `Frank.WorkflowEngine` csproj can switch to `Novolis.Scheduling` + `Novolis.Mapping` + `Novolis.Messaging.Channels` (PackageReference only).
