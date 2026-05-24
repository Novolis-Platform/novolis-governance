# Physics — sunset `Novolis.Physics.Numerics`

## What

Retire the **`Novolis.Physics.Numerics`** package: obsolete forwards (`Vector3d`, `Quaterniond`, `Ray3d`, `Sphere3d`, `Capsule3d`, `AxisAlignedBox3d`) that duplicate BCL + Math Geometry.

**Current state (2026-05-25):**

- Implementation is only `ObsoleteNumericsForwards.cs` with implicit conversions to `System.Numerics` / Math types.
- **No production `.cs` outside the package** uses `Vector3d` / `Ray3d` (physics code migrated).
- **Stale docs:** package README still says “Use `Ray3`” and lists `Ray3`/`Sphere3` in related packages.
- **Project references remain:** `Novolis.Physics.Abstractions`, `Novolis.Physics.Orbits`, and others still `ProjectReference` Numerics in csproj restore graphs.
- **`novolis-simulation/Directory.Packages.props`** pins `Novolis.Physics.Numerics` though simulation source does not use it.

## Why

- [library-boundaries.md](../library-boundaries.md): **BCL first, always** — custom `Vector3d` types are forbidden for new stack code.
- Keeping the package with wrong README actively steers contributors to forbidden names (`Ray3`).
- Extra package reference edges slow restore and confuse dependency graphs.

## How

### Phase A — Stop the bleeding (non-breaking)

1. Fix `novolis-physics/src/Novolis.Physics.Numerics/README.md`:
   - Examples use `Ray`, `Sphere`, `Vector3`.
   - Mark package **deprecated** with target removal version.
2. Update `ObsoleteNumericsForwards` messages: point to `Ray` / `Sphere`, not `Ray3`.
3. Remove `Novolis.Physics.Numerics` from `novolis-simulation/Directory.Packages.props` if unused.
4. Replace `ProjectReference` to Numerics in physics projects with direct Math.Geometry / BCL only (Abstractions should not need Numerics).

### Phase B — Remove package (breaking, one wave)

1. Delete `Novolis.Physics.Numerics` project from solution.
2. Remove package from registry / pack scripts.
3. Major or minor bump on affected Physics packages; release notes: “Numerics removed — use System.Numerics + Novolis.Math.Geometry.”
4. Grep consumers across org for `PackageReference Include="Novolis.Physics.Numerics"`.

### Phase C — Governance

- Update [inertial-frame-stack-spec.md](../inertial-frame-stack-spec.md) examples (`AxisAlignedBox3d` → `AxisAlignedBox` or document double-precision as future **optional** facet, not Numerics shims).

## Acceptance

- Physics solution builds with **zero** references to `Novolis.Physics.Numerics`.
- README and governance docs contain no “use Ray3” guidance for new code.
- GPR/no longer publishes `Novolis.Physics.Numerics` (or publishes empty metapackage with hard error — prefer delete).
