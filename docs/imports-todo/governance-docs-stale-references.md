# Governance and package docs — align with shipped Math API

## What

Refresh documentation that still describes **pre–BCL refactor** or **pre–Topology** shapes so agents and humans do not reintroduce forbidden patterns.

| Artifact | Issue |
|----------|--------|
| [simulation-layer-policy.md](../simulation-layer-policy.md) | Says “future `Novolis.Math.Topology`” — package exists |
| [.cursor/rules/platform-library-boundaries.mdc](../../.cursor/rules/platform-library-boundaries.mdc) | Quick table still lists `Ray3` under Math |
| [inertial-frame-stack-spec.md](../inertial-frame-stack-spec.md) | `Vector3d`, `AxisAlignedBox3d`, `Bounds3d` naming |
| [novolis-physics/.../Numerics/README.md](https://github.com/Novolis-Platform/novolis-physics/blob/main/src/Novolis.Physics.Numerics/README.md) | `Ray3` in examples |
| [novolis-rendering/docs/roadmap-raytracing.md](https://github.com/Novolis-Platform/novolis-rendering/blob/main/docs/roadmap-raytracing.md) | `BvhNode` in `CompiledScene` sketch |
| [novolis-rendering/docs/materials-and-backends.md](https://github.com/Novolis-Platform/novolis-rendering/blob/main/docs/materials-and-backends.md) | `BvhNode` in type table |
| Packed artifact README under `artifacts/nuget-packages-pack/novolis.math.geometry/` | Historical `Ray3` sample (regenerate on pack) |

## Why

- Documentation is treated as policy by Cursor agents; stale `Ray3` examples directly violate [library-boundaries.md](../library-boundaries.md).
- Roadmap diagrams that mention `BvhNode` obscure that **`TriangleBvhNode`** in Math is canonical.
- Inertial-frame spec is long-range; it should not contradict the BCL-first rule without an explicit “double precision facet” decision.

## How

1. **simulation-layer-policy.md** — list `Novolis.Math.Topology` as current facet; link to Topology README.
2. **platform-library-boundaries.mdc** — replace `Ray3` with `Ray` in Math row.
3. **inertial-frame-stack-spec.md** — add banner: “Numerics naming superseded by BCL-first policy”; replace examples with `Vector3` / `AxisAlignedBox` or mark section **Draft / not implemented**.
4. **Physics Numerics README** — handled in [physics-numerics-package-sunset.md](physics-numerics-package-sunset.md).
5. **Rendering docs** — replace `BvhNode` with `TriangleBvhNode`; note compile uses Math builder.
6. **Republish** — after doc edits, repack Math Geometry so GPR README matches repo.

No code changes required for acceptance of this doc-only wave except repack if README is packed from repo.

## Acceptance

- `rg 'Ray3|Sphere3|AxisAlignedBox3'` under `novolis-governance/docs` only hits “forbidden” / migration tables, not “use this type” examples.
- Agent rules and simulation policy mention Topology as shipped.
