# Imports TODO — local repo scan

Actionable backlog for **what to add** to Novolis platform libraries from local checkouts. Each doc: **what**, **why**, **how**, and **provenance**.

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

| Doc | Priority |
|-----|----------|
| [frankrepos-catalog.md](frankrepos-catalog.md) | Reference |
| [gameengine-assets-mesh-import.md](gameengine-assets-mesh-import.md) | **P0** |
| [gameengine-input.md](gameengine-input.md) | **P0** |
| [frank-mapping.md](frank-mapping.md) | **P0** |
| [gameengine-audio.md](gameengine-audio.md) | **P1** |
| [gameengine-2d-scene-rendering.md](gameengine-2d-scene-rendering.md) | **P1** |
| [frank-messaging-facade.md](frank-messaging-facade.md) | **P1** |
| [frank-scheduling-cronjobs.md](frank-scheduling-cronjobs.md) | **P1** |
| [frank-workflow-engine.md](frank-workflow-engine.md) | **P2** |
| [frank-entityframeworkcore.md](frank-entityframeworkcore.md) | **P2** |
| [frank-codegen-devtools.md](frank-codegen-devtools.md) | **P2** |
| [frank-ml-remainder.md](frank-ml-remainder.md) | **P2** |
| [frank-networking-caching.md](frank-networking-caching.md) | **P3** |
| [frank-repos-explicit-skip.md](frank-repos-explicit-skip.md) | Skip |

---

## `D:\github` + `D:\repos` (mine — pieces)

| Doc | Priority |
|-----|----------|
| [star-conflicts-revolt-patterns.md](star-conflicts-revolt-patterns.md) | **P1** — SCR on `D:\github` (event sourcing; not in frankrepos) |
| [github-frank-mine-extra.md](github-frank-mine-extra.md) | **P1** — repos on GitHub not in `frankrepos` |
| [fleetcommander-patterns-for-platform.md](fleetcommander-patterns-for-platform.md) | **P1** — WEGO replay (**implemented:** `Novolis.Simulation.Replay`) |
| [agent-contracts-novolis-governance.md](agent-contracts-novolis-governance.md) | **P1** — ACS alignment |
| [workflows-and-release-ci.md](workflows-and-release-ci.md) | **P2** — reusable Actions |

---

## Third-party — inspiration only

| Doc | Source |
|-----|--------|
| [third-party-inspiration-policy.md](third-party-inspiration-policy.md) | Rules |
| [repos-third-party-catalog.md](repos-third-party-catalog.md) | `D:\repos` clones (skip list + borrowable bits) |
| [bedrockframework-transports-inspiration.md](bedrockframework-transports-inspiration.md) | `D:\dotnetrepos\BedrockFramework` (**implemented:** Tcp middleware + `MemoryTcpTransport`) |
| [dotnetrepos-platform-reference.md](dotnetrepos-platform-reference.md) | aspnetcore, efcore, roslyn-sdk, semantic-kernel |

---

## Conventions

- **PackageReference only** across Novolis repos; no `ProjectReference` into `D:\frankrepos`, `D:\github`, `D:\repos`, or `D:\dotnetrepos`.
- Stack: [library-boundaries.md](../library-boundaries.md).
- **Skip real duplicates** (already in Novolis, or upstream consumed via NuGet).

## Suggested order

```text
Frank migration (frankrepos): Mapping → Cron → Messaging → GameEngine Assets/Input
Parallel: ACS governance + FleetCommander replay spike → Simulation facet
Transports: Bedrock inspiration review (no fork) after Tcp GPR stable
```
