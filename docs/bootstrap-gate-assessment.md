# Bootstrap and migration gates

Assessment date: 2026-05-17. Split per [frank-naming-and-structure.md](frank-naming-and-structure.md).

## Two gates (do not conflate)

| Gate | Purpose | Status |
|------|---------|--------|
| **Org bootstrap** | GitHub org, template, workflows, registry, reserved repos, template CI | **Done** (smoketest validates template/workflows) |
| **Migration readiness** | Naming sign-off + first real library NuGet from a domain repo | **In progress** — pilot on `novolis-messaging` |

## Org bootstrap — verdict

| Activity | Allowed? |
|----------|----------|
| Frank inventory, scoring, planning docs | Yes |
| Governance and extraction briefs | Yes |
| Template / smoketest CI | Yes |
| Copying Frank source into `novolis-*` | Yes (after [frank-naming-and-structure.md](frank-naming-and-structure.md) sign-off) |

### Org bootstrap criteria

| Criterion | Status |
|-----------|--------|
| Organization exists | Done |
| Governance, template, workflows, installer, registry | Done |
| Reserved domain repos exist | Done |
| CI on template / smoketest | Done |
| .NET 10 standard | Done (2026-05-17) |

`novolis-smoketest` validates **org bootstrap only** (`Novolis.TemplateSmokeTest`). It is **not** the Frank migration publish gate.

## Migration readiness gate

| Step | Status |
|------|--------|
| [frank-naming-and-structure.md](frank-naming-and-structure.md) signed off | Done (2026-05-17) |
| Trusted publishing on `novolis-messaging` | Configure per [nuget-setup.md](nuget-setup.md#migration-gate-novolis-messaging) |
| Ship `Novolis.Messaging.Channels` `0.1.0-preview.1` | After pilot extract + release |
| Registry entry for pilot package | Pending first publish |

### Sign-off (migration gate)

```text
Migration publish gate opened: YYYY-MM-DD — Novolis.Messaging.Channels 0.1.0-preview.1 from novolis-messaging (trusted publishing).
```

## Non-blocking follow-ups

- Branch rulesets on all org repos
- Registry PR flow sign-off for all packages
- Maintainer runbook for per-repo trusted publishing policies
