# Third-party inspiration policy

Applies to **`D:\repos`**, **`D:\dotnetrepos`**, and non-Frank trees under **`D:\github`**.

## What

Rules for using external repositories when planning Novolis work.

## Why

- Novolis is **NuGet-first** and **license-clean**; copying David Fowler’s Bedrock or Microsoft’s aspnetcore into `novolis-*` is not viable.
- Third-party trees on disk are **reference checkouts** for reading and spike code, not migration sources.
- Frank-owned repos under `D:\repos` may still be **products** (FleetCommander) — migrate **patterns**, not whole repos.

## How

| Allowed | Forbidden |
|---------|-----------|
| Read upstream; note API shapes, test layouts, protocol framing | `ProjectReference` or subtree copy into `novolis-*` |
| Reimplement a **small** slice with Novolis naming and tests | Ship upstream LICENSE mixed into platform packages without review |
| Depend on **published NuGet** (Bedrock.Framework, Roslyn, UblSharp, …) | Fork vendored code “because it’s on D:\” |
| Document “inspiration only” in imports-todo | Claim parity with upstream without maintenance plan |

### “Mine” vs third-party

| Label | Meaning |
|-------|---------|
| **Mine (Frank)** | `frankhaugen/*`, `Frank.*`, FleetCommander, agent-contracts-standard, Workflows — may extract **pieces** into Novolis |
| **Third-party** | bullet3, raylib, ravendb, MonoGame, BedrockFramework, semantic-kernel, wpf, … — **inspiration only** |

### When a third-party item becomes Novolis work

1. Write a short imports-todo doc (what slice, why, how).
2. Prefer **NuGet** dependency in the consuming repo if license and versioning fit.
3. If reimplementing: new code in correct `novolis-*` repo, TUnit tests, no file-for-file port.

## Acceptance

Every third-party row in [repos-third-party-catalog.md](repos-third-party-catalog.md) or [dotnetrepos-platform-reference.md](dotnetrepos-platform-reference.md) states **Skip** or **Inspiration: …** explicitly.
