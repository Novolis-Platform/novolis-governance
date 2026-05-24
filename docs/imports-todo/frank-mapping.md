# Import: `Frank.Mapping` → Novolis

**Source:** `D:\frankrepos\Frank.Mapping`

## What

| Package | Role |
|---------|------|
| `Frank.Mapping` | `IMappingDefinition<TFrom,TTo>`, fluent object mapping |
| `Frank.Mapping.Analyzers` | Compile-time mapping diagnostics |
| `Frank.Mapping.Documents` | Document-oriented mapping helpers |

Published on NuGet; **no Frank.* production dependencies** (BCL + JsonPath/XPath per README).

**Consumers on disk:** `Frank.WorkflowEngine`, `Frank.ML.Domain.Legacy`.

## Why

- **Not listed** in [frank-inventory.md](../frank-inventory.md) P0 waves but is a **dependency of planned imports** (WorkflowEngine, ML Legacy).
- Replacing ad-hoc mapping in services reduces duplication across transports, storage DTOs, and ML pipelines.
- Analyzers fit Novolis quality bar (like `Novolis.Analyzers.AutoMapper`).

## How

### Target

**New repo:** `novolis-mapping` (or facet under `novolis-codegen` if you want analyzers co-located — prefer **standalone** for non-Roslyn users).

| Novolis package | Frank source |
|-----------------|--------------|
| `Novolis.Mapping` | `Frank.Mapping` |
| `Novolis.Mapping.Analyzers` | `Frank.Mapping.Analyzers` |
| `Novolis.Mapping.Documents` | `Frank.Mapping.Documents` (optional wave 2) |

### Port steps

1. Bootstrap `novolis-mapping` from `novolis-template-dotnet`, `net10.0`.
2. Rename namespaces; preserve public API where possible for low churn.
3. Port analyzer tests; enable `Novolis.Documentation.props`.
4. Publish `2026.1.*` before `Frank.WorkflowEngine` port.
5. Update `frank-inventory.md` with P1 row.

### Sequencing

**Wave 13 (proposed)** — before WorkflowEngine.

## Acceptance

- WorkflowEngine spike can reference `Novolis.Mapping` instead of `Frank.Mapping`.
- Zero `Frank.Mapping` in Novolis production csproj after migration.
