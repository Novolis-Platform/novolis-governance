# Frank.GameEngine reference policy

Governs how [Frank.GameEngine](https://github.com/frankhaugen/Frank.GameEngine) relates to Novolis graphics and simulation repos.

## Decision (locked)

- **Primary graphics path:** [novolis-raylib](https://github.com/Novolis-Platform/novolis-raylib) → `Novolis.Raylib.*` per [raylib ecosystem spec](https://github.com/Novolis-Platform/.github/blob/main/plans/raylib-package-ecosystem.md).
- **Frank.GameEngine:** **active selective mining** — no bulk migration; personal repo stays **unarchived**.

## Rationale

| Factor | Frank.GameEngine | Novolis.Raylib |
|--------|------------------|----------------|
| Graphics coupling | Multiple renderers (RayLib, MonoGame, Experimental) | Single focused Raylib stack |
| Packaging | 11+ engine packages, 0.3.x releases | Curated aggregate + facets |
| Strategic fit | General engine (ECS-adjacent) | Platform infra + progressive complexity |
| Overlap | `Frank.GameEngine.Rendering.RayLib` duplicates raylib binding work | Canonical for Novolis games |

## Do not migrate

| Frank package / area | Reason |
|---------------------|--------|
| `Frank.GameEngine.Rendering.RayLib` | Superseded by `Novolis.Raylib` |
| `Frank.GameEngine.Rendering.MonoGame` | Out of scope unless Novolis adds MonoGame lane |
| `Frank.GameEngine.Rendering.Experimental` | Unstable |
| `Frank.GameEngine.Core` | Orchestrates rendering stack — rebuild under Novolis if needed |
| Samples / AppHost | Stay on personal repo |

## Migrated (wave 7)

| Frank source | Novolis package | Repo |
|--------------|-----------------|------|
| `Frank.GameEngine.Primitives/SubPrimitives/*` | `Novolis.Math.Arrays` | `novolis-math` |
| Geometry subset (Polygon, TriangleMesh, transforms, cameras, …) | `Novolis.Math.Geometry` | `novolis-math` |
| Dogfood-grown occupancy / view controllers | `Novolis.Simulation.*` | `novolis-simulation` (see [simulation-layer-policy.md](simulation-layer-policy.md)) |

Brief: [extraction-briefs/wave-7-gameengine-math.md](extraction-briefs/wave-7-gameengine-math.md)

## May mine later (with issue + review)

Renderer-agnostic modules may inform **`novolis-physics`**, **`novolis-raylib`**, or **`novolis-math`** only if:

1. No dependency on `Frank.GameEngine.Rendering.*`
2. Clear Novolis API redesign (not copy-paste)
3. Tests ported or rewritten
4. Documented in an extraction brief

| Module | Candidate Novolis home | Condition |
|--------|------------------------|-----------|
| `Frank.GameEngine.Physics` | `novolis-physics` or game2D facet | Scene/`GameObject` model — redesign required |
| `Frank.GameEngine.Assets` (`ObjHelper`) | `novolis-raylib` | Wave 7b after geometry ships |
| `Frank.GameEngine.Input` | `Novolis.Raylib` or hosting | Prefer Raylib input path first |
| `Frank.GameEngine.Audio` | Defer | Platform-specific |
| `GameObject`, `Scene`, `Scene2D` | Stay in Frank.GameEngine | Engine graph, not math |

## Personal repo README (partial migration — do not archive)

```markdown
> **Partially on Novolis:** `Novolis.Math.Arrays` and `Novolis.Math.Geometry` live in [novolis-math](https://github.com/Novolis-Platform/novolis-math).
> Graphics: use [Novolis.Raylib](https://github.com/Novolis-Platform/novolis-raylib). This repo remains the home for samples, engine core, and unmigrated code.
```

## Related

- [frank-inventory.md](frank-inventory.md)
- [Novolis Raylib package ecosystem](https://github.com/Novolis-Platform/.github/blob/main/plans/raylib/raylib-ecosystem-specs.md)
