# Math BCL refactor — publish wave and consumer sweep

## What

Complete the coordinated refactor started in the math BCL plan:

- Ship **`Novolis.Math.Topology`** on GPR (`2026.1.*`) alongside updated **Arrays** and **Geometry**.
- Confirm all stack consumers use **`Ray`**, **`Sphere`**, **`AxisAlignedBox`** (no `*3` public names).
- Verify shared **`BvhRaycast`**, **`AxisAlignedBox.RayInterval`**, **`TriangleBvhBuilder`** are the only BVH/slab/triangle paths on CPU (Physics + Rendering CPU backend).

**Already landed in repo (audit 2026-05-25):**

- Topology project extracted; Geometry references it.
- `BvhStaticWorld` delegates to `TriangleBvh` / `TriangleBvhBuilder` (no local `BvhNode` copy).
- `PathTracerEngine` uses `BvhRaycast.Traverse` + `TriangleRay.TryHit`.
- `CompiledScene` stores `TriangleBvhNode` (no duplicate `BvhNode.cs`).

**Still open:**

- Cross-repo **`Directory.Packages.props`** pins do not list `Novolis.Math.Topology` explicitly (transitive via Geometry is fine; add pin only where a project references polygon APIs directly).
- **`verify-nuget-only.ps1`** + full **`dotnet test`** on Math, Physics, Rendering solutions after pack.
- Release notes: breaking rename table, Topology install guidance.

## Why

- Agents and consumers read governance/docs that forbid `Ray3`; shipped packages and stale READMEs must match or migrations stall.
- Duplicate BVH/slab code was a source of shadow-ray and physics/render drift; centralizing in Geometry is only valuable if every consumer is on the new packages.
- NuGet-only policy requires a **publish-before-bump** order; partial waves leave ProjectReference temptation.

## How

1. **Math repo**
   - `dotnet build` / `dotnet test` on `Novolis.Math.slnx`.
   - Pack `Novolis.Math.Arrays`, `Novolis.Math.Topology`, `Novolis.Math.Geometry` to local feed or GPR.
2. **Governance gate**
   - `pwsh -File novolis-governance/scripts/verify-nuget-only.ps1` (exit 0).
3. **Consumers** (bump `Novolis.Math.Geometry` to published version; add `Novolis.Math.Topology` only if direct polygon use):
   - `novolis-physics/Directory.Packages.props`
   - `novolis-rendering/Directory.Packages.props`
   - `novolis-simulation/Directory.Packages.props`
   - `novolis-dogfooding/Directory.Packages.props`
   - MonoGame template content if it references `Polygon` without Geometry transitively.
4. **Build matrix**
   - `novolis-physics` slnx
   - `novolis-rendering` slnx
   - `novolis-simulation` slnx
   - Dogfood apps: DoomLite3D, RaytraceHello, SilkTrace*, BouncingBall, ArtillerySimulator.
5. **Docs**
   - Refresh any packed README still showing `Ray3` under `artifacts/nuget-packages-pack/` after repack.

**Breaking-change policy:** Do **not** add a public `Ray3` obsolete alias. List renames in release notes only.

## Acceptance

- Zero `Ray3` / `Sphere3` / `AxisAlignedBox3` in consumer `.cs` (except obsolete `Ray3d` shim package — see [physics-numerics-package-sunset.md](physics-numerics-package-sunset.md)).
- Physics raycast and Rendering CPU path trace share Math BVH traversal tests (existing `BvhRaycastTests` green).
- All consumers restore/build with **PackageReference only**.
