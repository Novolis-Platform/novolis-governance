# ILGPU / Vulkan — BVH slab parity with `Novolis.Math.Geometry`

## What

Align **device-side** BVH traversal numerics with the **host-tested** implementation in Math:

| Component | Status (2026-05-25) |
|-----------|---------------------|
| CPU `PathTracerEngine` | Uses `BvhRaycast` + `AxisAlignedBox.RayInterval` + `GeometryConstants` |
| `IlgpuPathTracerKernels.RaySlabIntersect` | Private duplicate; hard-coded `1e-15f` parallel epsilon |
| `IlgpuPathTracerKernels` triangle test | `Float3` Möller–Trumbore (expected on device) |
| `GpuBvhNode.From(TriangleBvhNode)` | Layout adapter only — keep |

**Import options (pick one per milestone):**

1. **Documented parity contract** — comments + ILGPU unit test comparing host `AxisAlignedBox.RayInterval` results to kernel slab for a grid of rays/boxes.
2. **Shared constants** — copy `GeometryConstants.RayParallelEpsilon` into ILGPU as `const` with same literal (no runtime dep on Math in kernels).
3. **Long-term** — shared-source file included in both Math and ILGPU projects (only if maintenance cost is justified).

## Why

- Shadow and primary rays that disagree between CPU fallback and ILGPU backend produce “works in CPU, wrong on GPU” bugs that are expensive to debug.
- Math already owns BVH structure; governance says Physics/Rendering must not fork slab tests silently.
- Vulkan path currently delegates to CPU-backed surface in tests; ILGPU is the path that still carries duplicate slab logic.

## How

1. **Short term (recommended)**
   - In `IlgpuPathTracerKernels`, set parallel epsilon to `1e-15f` via named constant matching `GeometryConstants.RayParallelEpsilon`.
   - Add test in `Novolis.Rendering.Unit` (Backends.Igpu): for N random boxes/rays, host `AxisAlignedBox.RayInterval` matches a small C# port of `RaySlabIntersect` logic (or invoke CPU reference and compare bool + tEnter/tExit).
2. **Medium term**
   - Add `/// <remarks>` on `RaySlabIntersect` citing Math as authority; link to `BvhRaycastTests` / `AxisAlignedBox_RayInterval_HitsUnitCubeFace`.
3. **Do not**
   - Reference `Novolis.Math.Geometry` from ILGPU kernel assemblies if it pulls disallowed types into device compilation — keep `Float3` on device.

## Acceptance

- Documented epsilon source of truth is `GeometryConstants`.
- At least one automated parity test between host slab and ILGPU slab helper.
- No second public `RaySlabIntersect` in Rendering.Runtime.
