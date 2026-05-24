# Math — adopt `RigidTransform`, remove obsolete `Transform`

## What

Finish the pose-helper migration from the math BCL plan:

- **`RigidTransform`** — shipped (`Position`, `Rotation`, `UniformScale`, `ToMatrix4x4`, `TransformPoint`/`TransformDirection`).
- **`Transform`** (mutable class) — marked `[Obsolete("Use RigidTransform")]` but **no callers** outside its own file (2026-05-25).
- **MonoGame template `Transform`** — separate concept (`Novolis.Templates.MonoGame` `ITransform`); not the same type; do not conflate.

**Work:**

1. Delete or internalize `Novolis.Math.Geometry.Transform` after one release if no package consumers reference it.
2. Use `RigidTransform` in mesh/scene code paths that still use mutable transform fields (grep `Transform` in math + rendering compile).
3. Document `RigidTransform` in Geometry README quick start (one example).

## Why

- Mutable transform classes fight determinism and copy semantics expected in Physics/Simulation/Replay.
- `RigidTransform` is the BCL-aligned replacement; keeping obsolete `Transform` confuses agents reading obsolete attributes.
- Templates should demonstrate current API for new games.

## How

1. **Audit**
   - `rg "Novolis\.Math\.Geometry\.Transform"` across workspace (exclude MonoGame template namespace).
   - Check packed NuGet samples and `artifacts/` READMEs.
2. **Migrate callers** (if any appear after package publish)
   - Replace `new Transform(...)` with `new RigidTransform(...)`; prefer `readonly` fields.
3. **Remove type**
   - Delete `Transform.cs` in Geometry; bump **minor** package version; note breaking change in release notes.
4. **Templates**
   - If template scaffolds reference Math `Transform`, switch to `RigidTransform` or clarify template-local `Transform` is not Math.

## Acceptance

- No public `Transform` class in `Novolis.Math.Geometry`.
- README shows `RigidTransform` example.
- Stack builds with analyzers green.
