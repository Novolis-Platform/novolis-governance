# Import: `Frank.Messaging` → `novolis-messaging`

**Source:** `D:\frankrepos\Frank.Messaging`

## What

| Project | Role |
|---------|------|
| `Frank.Messaging.Abstractions` | Core messaging contracts |
| `Frank.Messaging` | Facade / composition |
| `Frank.Messaging.Provider.Channels` | Channels-backed provider |
| `Frank.Messaging.Tests` | Tests |

**Dependencies (Frank):** `Frank.Reflection`, `Frank.Channels.DependencyInjection` — latter **already** `Novolis.Messaging.Channels`.

## Why

- Wave 0 migrated **Channels** and **PulseFlow** but not the **Messaging abstraction layer** that sits above raw channels.
- Apps may want `IMessageBus`-style API without PulseFlow-specific types.
- Completes messaging story before WorkflowEngine (which uses Channels + DI patterns).

## How

### Target

Extend **`novolis-messaging`** (no new repo):

- `Novolis.Messaging.Abstractions` (if not redundant with existing)
- `Novolis.Messaging.Provider.Channels` or merge into existing Channels package

### Port steps

1. Diff Frank abstractions vs current `Novolis.Messaging` / `Novolis.Messaging.Channels` — avoid duplicate types.
2. Port only **net-new** contracts and adapter; depend on published `Novolis.Messaging.Channels`.
3. Replace `Frank.Reflection` with `Novolis.CodeGen.Reflection` subset **only if** actually used in production code.
4. TUnit + Testcontainers as needed.
5. GPR publish; update `frank-inventory.md`.

### Blockers

- Messaging pilot NuGet gate ([nuget-setup.md](../nuget-setup.md)).

## Acceptance

- `Frank.Messaging` scenarios covered by Novolis packages.
- WorkflowEngine dependency can target Novolis instead of Frank.
