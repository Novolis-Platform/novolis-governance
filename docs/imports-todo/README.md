# Imports TODO — platform libraries

Actionable backlog for **adding or consolidating** capabilities across Novolis stack repos. Each document is self-contained: **what** to import or wire, **why** it matters, and **how** to implement without violating [library-boundaries.md](../library-boundaries.md) or [nuget-only-policy.md](../nuget-only-policy.md).

**Source review (2026-05-25):** [math_libs BCL refactor plan](https://github.com/Novolis-Platform/novolis-governance/blob/main/docs/imports-todo/math-bcl-refactor-publish-wave.md), live code under `novolis-math`, `novolis-physics`, `novolis-rendering`, `novolis-simulation`, `novolis-codegen`, `novolis-raylib`, and governance extraction briefs.

## Index

| Doc | Repo(s) | Priority |
|-----|---------|----------|
| [math-bcl-refactor-publish-wave.md](math-bcl-refactor-publish-wave.md) | math, physics, rendering, simulation, dogfooding | **P0** — finish in-flight refactor |
| [rendering-viewbasis-ray-generation.md](rendering-viewbasis-ray-generation.md) | rendering, math | **P1** — dedupe host ray math |
| [ilgpu-bvh-slab-parity.md](ilgpu-bvh-slab-parity.md) | rendering, math | **P1** — GPU/host intersection parity |
| [rigidtransform-and-obsolete-transform.md](rigidtransform-and-obsolete-transform.md) | math, templates | **P2** — complete pose API migration |
| [physics-numerics-package-sunset.md](physics-numerics-package-sunset.md) | physics, simulation | **P1** — retire duplicate numerics |
| [governance-docs-stale-references.md](governance-docs-stale-references.md) | governance, physics, rendering | **P1** — docs match shipped API |
| [simulation-viewpose-to-rendering-bridge.md](simulation-viewpose-to-rendering-bridge.md) | simulation, rendering, apps | **P2** — standardize observer → trace |
| [codegen-bindings-backlog.md](codegen-bindings-backlog.md) | codegen, raylib | **P2** — post–Phase 4 enhancements |
| [raylib-obj-helpers-wave7b.md](raylib-obj-helpers-wave7b.md) | raylib, math | **P3** — when asset lane needs OBJ |
| [math-arrays-array2d-helpers.md](math-arrays-array2d-helpers.md) | math | **P3** — optional Frank.Collections port |
| [scheduling-cronjobs-repo.md](scheduling-cronjobs-repo.md) | TBD (`novolis-scheduling`?) | **P3** — Frank.CronJobs extract |

## Conventions

- **PackageReference only** across repos; publish Math/Physics/Rendering bumps before consumer PRs.
- **No forbidden names** in new public API (`Ray3`, `Vector3d`, `Vector2`, …).
- Prefer **Math owns structure**, **Physics owns response**, **Simulation owns observers**, **Rendering owns framebuffer production**, **apps own glue**.
