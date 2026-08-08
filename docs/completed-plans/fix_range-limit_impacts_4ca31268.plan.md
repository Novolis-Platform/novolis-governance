---
name: Fix range-limit impacts
overview: Range-limit stops currently record impact at the in-air point where the trajectory crosses the map box (e.g. Y≈2428 m at X=2500), producing impossible "Beyond range" sky impacts. Fix by removing vertical BVH walls, projecting edge impacts onto terrain, and clarifying HUD.
todos:
  - id: project-ground
    content: Add TerrainWorld.ProjectOntoTerrainSurface; use in all BeyondRange impact paths
    status: completed
  - id: remove-walls
    content: Remove vertical wall triangles from BVH; keep gold boundary draw only
    status: completed
  - id: preview-hud
    content: BallisticArcPreview ground endpoint at edge; HUD Range limit (map edge) wording
    status: completed
  - id: validate-build
    content: Release build; verify high-angle shot shows ground Y at map edge
    status: completed
isProject: false
---

# Fix unrealistic range-limit impacts

## What you are seeing

Your HUD: **46.5° elev**, **560 m/s**, **TOF 6.4 s**, impact at **(2500, 2428, 906)**, **Beyond range**.

That is physically consistent with the **current code**, but wrong for an artillery demo:

```mermaid
sequenceDiagram
  participant Gun
  participant Traj as Trajectory
  participant Box as XZ_box_exit
  Gun->>Traj: Fire +X at high quadrant
  Traj->>Box: Crosses X=2500 after ~6.4s still ascending
  Note over Traj: Y ≈ 2400 m (not ground)
  Box->>Traj: TrySegmentLeavesRange records air point
  Traj->>HUD: Beyond range at altitude 2428 m
```

At 46.5°, vertical velocity is still **up** after 6.4 s; horizontal travel reaches the **2.5 km** east edge while the round is thousands of meters above the hills (~20–45 m). [`TryRangeOrGroundHit`](d:\novolis\novolis-dogfooding\apps\ArtillerySimulator\Game\ProjectileRun.cs) records `boundaryHit` **as-is** (line 153–156), so impact Y stays at flight altitude.

Vertical **BVH walls** in [`TerrainWorld.AddRangeWalls`](d:\novolis\novolis-dogfooding\apps\ArtillerySimulator\Game\TerrainWorld.cs) (450 m tall) can also register mesh hits in the air if the segment test does not run first — redundant and confusing.

---

## Fix strategy

### 1. Ground-projected range limit (core)

Add on [`TerrainWorld`](d:\novolis\novolis-dogfooding\apps\ArtillerySimulator\Game\TerrainWorld.cs):

```csharp
public Vector3 ProjectOntoTerrainSurface(Vector3 p, float surfaceEpsilon = 0.05f)
{
  var x = Math.Clamp(p.X, 0f, ExtentMeters);
  var z = Math.Clamp(p.Z, 0f, ExtentMeters);
  var y = SampleHeight(x, z) + surfaceEpsilon;
  return new Vector3(x, y, z);
}
```

Use everywhere a range limit is recorded ([`ProjectileRun`](d:\novolis\novolis-dogfooding\apps\ArtillerySimulator\Game\ProjectileRun.cs)):

- `TryRangeOrGroundHit` — after `TrySegmentLeavesRange`, replace `boundaryHit` with `terrain.ProjectOntoTerrainSurface(boundaryHit)`
- `TryTerrainHit` — boundary branch (lines 217–222)
- `TryFallbackContact` — OOB endpoint: clamp + project before `RecordImpact`

Rename reason in HUD copy only (keep enum `BeyondRange` or add `RangeLimit` alias): show **"Range limit (map edge)"** instead of bare **"Beyond range"**.

### 2. Remove vertical walls from collision mesh

In [`TerrainWorld.BuildMeshes`](d:\novolis\novolis-dogfooding\apps\ArtillerySimulator\Game\TerrainWorld.cs):

- **Delete** `AddRangeWalls` call and method (or stop adding wall triangles to BVH).
- Keep the **gold wire rectangle** (`DrawRangeBoundary`) as the visual limit only.
- Terrain + heightfield + **logical** XZ segment exit remain the collision story.

This prevents `TerrainMesh` hits on invisible walls in the sky.

### 3. HUD clarity ([`SimulationHud.cs`](d:\novolis\novolis-dogfooding\apps\ArtillerySimulator\Game\SimulationHud.cs))

- Impact line: `Range limit (map edge)` when `Reason == BeyondRange`.
- Coordinates line: label **ground impact** — values should show Y ≈ terrain height (tens of m), not thousands.
- Optional second stat: `Max ord {apex} m` deferred (out of scope unless easy from trail max Y).

### 4. Aim preview ([`BallisticArcPreview.cs`](d:\novolis\novolis-dogfooding\apps\ArtillerySimulator\Game\BallisticArcPreview.cs))

When preview crosses the box, add a final point at `ProjectOntoTerrainSurface(boundaryHit)` so the ghost arc ends on the ground at the edge, not in the air.

### 5. Optional tuning (only if still frustrating after fix)

If many shots still end at the east edge before descending, bump [`SimulationUnits.ExtentMeters`](d:\novolis\novolis-dogfooding\apps\ArtillerySimulator\Game\SimulationUnits.cs) from **2500 → 4000** (keep 128×128 collision). **Not required** for the correctness fix; mention in validation.

---

## Validation

| Scenario | Expected after fix |
|----------|-------------------|
| 46.5°, standard charge, +X | Impacted at **X≈2500**, **Y≈20–50 m** (terrain), **Range limit** label; not Y≈2400 m |
| 45°, hills, in-bounds landing | Normal terrain impact, no range label |
| HUD coords | `(2500, ~30, ~900)` style — plausible ground hit |

Build Release, manual fire once.

---

## Files to change

| File | Change |
|------|--------|
| [`TerrainWorld.cs`](d:\novolis\novolis-dogfooding\apps\ArtillerySimulator\Game\TerrainWorld.cs) | `ProjectOntoTerrainSurface`; remove wall tris from BVH |
| [`ProjectileRun.cs`](d:\novolis\novolis-dogfooding\apps\ArtillerySimulator\Game\ProjectileRun.cs) | Project all range-limit impacts onto ground |
| [`BallisticArcPreview.cs`](d:\novolis\novolis-dogfooding\apps\ArtillerySimulator\Game\BallisticArcPreview.cs) | Preview endpoint on ground at edge |
| [`SimulationHud.cs`](d:\novolis\novolis-dogfooding\apps\ArtillerySimulator\Game\SimulationHud.cs) | Clearer range-limit wording |

No physics library changes.

