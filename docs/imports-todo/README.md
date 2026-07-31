# Imports TODO — detail appendices

> **Canonical plan:** [platform-import-plan.md](../platform-import-plan.md) — phases, status, dependencies.  
> Files here are **appendices only** (what / why / how). Do not maintain parallel P0/P1 priority tables.

Actionable detail for **what to add** to Novolis platform libraries from local checkouts.

| Source root | Role |
|-------------|------|
| **`D:\frankrepos`** | **Primary migration source** (Frank.\* — extract/rebuild into `novolis-*`) |
| **`D:\github`** | Mostly duplicate clones of `frankrepos` + extra Frank repos; same migration rules |
| **`D:\repos`** | Frank **products/patterns** + **third-party reference** (inspiration only unless Frank-owned utility) |
| **`D:\dotnetrepos`** | **Third-party upstream** (Bedrock, aspnetcore, roslyn-sdk, …) — **ideas only**, not copy sources |

**Policy:** Third-party code is **not** vendored into Novolis. Borrow **patterns, APIs, test ideas**; use **NuGet** or reimplement minimal slices. See [third-party-inspiration-policy.md](third-party-inspiration-policy.md).

Cross-check [frank-inventory.md](../frank-inventory.md). In-repo completion items: [internal-novolis-audit/](internal-novolis-audit/).

---

## `D:\frankrepos` (migration)

| Doc | Phase (master plan) |
|-----|---------------------|
| [frankrepos-catalog.md](frankrepos-catalog.md) | Reference |
| [frank-mapping.md](frank-mapping.md) | **1** — done → `novolis-mapping` |
| [gameengine-assets-mesh-import.md](gameengine-assets-mesh-import.md) | **1** — done → `Novolis.Raylib.Loaders` |
| [gameengine-input.md](gameengine-input.md) | **1** — done → `Novolis.Raylib.Input` |
| [frank-scheduling-cronjobs.md](frank-scheduling-cronjobs.md) | **2** — done → `novolis-scheduling` |
| [frank-messaging-facade.md](frank-messaging-facade.md) | **2** — done → `Novolis.Messaging.Abstractions` |
| [gameengine-audio.md](gameengine-audio.md) | **2** — done → `novolis-audio` stub |
| [gameengine-2d-scene-rendering.md](gameengine-2d-scene-rendering.md) | **cancelled** — see `Novolis.Rendering.TwoD` |
| [frank-workflow-engine.md](frank-workflow-engine.md) | **4** |
| [frank-entityframeworkcore.md](frank-entityframeworkcore.md) | **4** |
| [frank-codegen-devtools.md](frank-codegen-devtools.md) | **4** |
| [frank-ml-remainder.md](frank-ml-remainder.md) | **4** audit |
| [frank-networking-caching.md](frank-networking-caching.md) | Defer |
| [frank-repos-explicit-skip.md](frank-repos-explicit-skip.md) | Skip |

---

## `D:\github` + `D:\repos` (mine — pieces)

| Doc | Phase |
|-----|-------|
| [fleetcommander-patterns-for-platform.md](fleetcommander-patterns-for-platform.md) | **done** + **3** product adoption |
| [star-conflicts-revolt-patterns.md](star-conflicts-revolt-patterns.md) | **3** |
| [github-frank-mine-extra.md](github-frank-mine-extra.md) | **5** maintainer tools |
| [agent-contracts-novolis-governance.md](agent-contracts-novolis-governance.md) | **5** — done |
| [workflows-and-release-ci.md](workflows-and-release-ci.md) | **5** — reusable workflow in governance |

---

## Third-party — inspiration only

| Doc | Source |
|-----|--------|
| [third-party-inspiration-policy.md](third-party-inspiration-policy.md) | Rules |
| [repos-third-party-catalog.md](repos-third-party-catalog.md) | `D:\repos` clones (skip list + borrowable bits) |
| [bedrockframework-transports-inspiration.md](bedrockframework-transports-inspiration.md) | `D:\dotnetrepos\BedrockFramework` (**implemented:** Tcp middleware + `MemoryTcpTransport`) |
| [dotnetrepos-platform-reference.md](dotnetrepos-platform-reference.md) | aspnetcore, efcore, roslyn-sdk, semantic-kernel |

---

## Related research

- [Awesome-LLM-3D → Novolis](../research-radar/awesome-llm-3d.md) — research radar (Adopt / Adapter / Skip) for 3D-LLM papers; scene agent actions for spatial tools.

## Conventions

- **PackageReference only** across Novolis repos; no `ProjectReference` into `D:\frankrepos`, `D:\github`, `D:\repos`, or `D:\dotnetrepos`.
- Stack: [library-boundaries.md](../library-boundaries.md).
- **Skip real duplicates** (already in Novolis, or upstream consumed via NuGet).

## Execution order

See [platform-import-plan.md](../platform-import-plan.md#implementation-order).
