# Frank.GameEngine reference policy

Governs how [Frank.GameEngine](https://github.com/frankhaugen/Frank.GameEngine) relates to Novolis graphics and simulation repos.

## Decision (locked)

- **Primary graphics path:** [novolis-raylib](https://github.com/Novolis-Platform/novolis-raylib) → `Novolis.Raylib.*` per [raylib ecosystem spec](https://github.com/Novolis-Platform/.github/blob/main/plans/raylib-package-ecosystem.md).
- **Frank.GameEngine:** **reference / archive** — no bulk migration into Novolis.

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
| Samples / AppHost | Reference only |

## May mine (with issue + review)

Renderer-agnostic modules may inform **`novolis-physics`** or future simulation repos **only** if:

1. No dependency on `Frank.GameEngine.Rendering.*`
2. Clear Novolis API redesign (not copy-paste)
3. Tests ported or rewritten
4. Documented in a `novolis-physics` or `novolis-math` extraction issue

| Module | Candidate Novolis home | Condition |
|--------|------------------------|-----------|
| `Frank.GameEngine.Physics` | `novolis-physics` | Abstract collision/integrator only |
| `Frank.GameEngine.Primitives` | `novolis-math` | Vectors/types without engine coupling |
| `Frank.GameEngine.Input` | `Novolis.Raylib` or hosting | Prefer Raylib input path first |
| `Frank.GameEngine.Audio` | Defer | Platform-specific |

## Frank.GameEngine inventory (reference)

- **SDK:** 10.0.203
- **Packable projects:** 11
- **Latest release:** 0.3
- **Test projects:** 3 (32 test files; sparse xUnit Fact count in scan)
- **Samples:** Pong, Hello2D, FPS, Battleship, BouncingBall + Aspire AppHost

## Old repo sunset (when mining completes)

Leave [frankhaugen/Frank.GameEngine](https://github.com/frankhaugen/Frank.GameEngine) archived with README banner:

```markdown
> Superseded for graphics by [Novolis.Raylib](https://github.com/Novolis-Platform/novolis-raylib).
> Novolis does not maintain a drop-in replacement for Frank.GameEngine.
```

## Related

- [frank-inventory.md](frank-inventory.md)
- [Novolis Raylib package ecosystem](https://github.com/Novolis-Platform/.github/blob/main/plans/raylib/raylib-ecosystem-specs.md)
