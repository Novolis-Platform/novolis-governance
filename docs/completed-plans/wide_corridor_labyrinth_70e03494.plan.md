---
name: Wide corridor labyrinth
overview: Replace post-carve dilation (which merges the maze into one room) with a logical-graph maze rasterized to exactly 2-cell-wide corridors, preserving labyrinth topology on a 35×35 grid.
todos:
  - id: remove-dilation
    content: Remove WidenCorridors and its call from MazeGenerator
    status: completed
  - id: logical-maze
    content: Add 11x11 logical recursive backtracker with calm-room hook
    status: completed
  - id: rasterize-2wide
    content: Rasterize logical edges to 2-cell-wide physical corridors on 35x35 grid
    status: completed
  - id: verify-playtest
    content: Build and spot-check F1 mazes are labyrinthine with 2-wide halls
    status: completed
isProject: false
---

# Fix labyrinth: 2-cell-wide corridors (no dilation)

## Root cause

[`WidenCorridors`](d:\novolis\novolis-dogfooding\apps\DoomLite3D\Game\MazeGenerator.cs) runs **morphological dilation** on every floor cell with `halfWidth = 2` (5×5 Chebyshev). On a 35×35 maze with many 1-cell passages and junctions, overlapping expansions erase walls and produce **one open floor blob**.

```mermaid
flowchart LR
  DFS[1-cell DFS maze] --> Dilate[WidenCorridors r=2]
  Dilate --> Blob[Single open region]
```

**Fix:** delete dilation; generate **2-cell-wide corridors in the carve step** via coarse logical nodes + deterministic rasterization.

## Corridor width semantics

- [`LevelMap.WallHeight`](d:\novolis\novolis-dogfooding\apps\DoomLite3D\Game\LevelMap.cs) = `3f` (vertical).
- Corridors will be **2 grid cells wide** (`2 × CellSize` = 2m world), i.e. two “tiles” side by side — wide enough for combat/movement without flooding the map.
- Walls remain **at least 1 cell** between parallel corridors after rasterization.

## Algorithm: logical maze + rasterize

Keep physical **`Size = 35`** (odd, 1-cell border at `0` and `34`).

| Layer | Size | Role |
|-------|------|------|
| Logical nodes | `11 × 11` | Recursive backtracker (perfect maze) |
| Physical cells | `35 × 35` | `nodePx = 1 + ix * 3`, `nodePz = 1 + iz * 3` |

**Spacing 3** = 2 floor cells (corridor) + 1 wall column between node columns.

### 1. Logical backtracker (unchanged idea, new grid)

- `bool[,] connected` or wall grid on `LogicalSize = 11`.
- Standard recursive backtracker between `(ix, iz)` neighbors (step 1 in logical space).
- Calm spawn: carve logical nodes `(0,0)`..`(2,2)` or keep physical 7×7 calm room **before** maze carve (only on physical grid at `(1,1)`..`(7,7)`), then start DFS from logical node `(2, 2)` eastward.

### 2. Rasterize to physical `byte[,] walls`

Helpers in [`MazeGenerator.cs`](d:\novolis\novolis-dogfooding\apps\DoomLite3D\Game\MazeGenerator.cs):

- **`CarveNodeBlock(walls, px, pz)`** — clear 2×2: `(px,pz)`, `(px+1,pz)`, `(px,pz+1)`, `(px+1,pz+1)`.
- **`CarveLinkEast(walls, px, pz)`** — clear `(px+2, pz..pz+1)` and `(px+3, pz..pz+1)` when logical edge to `ix+1` exists. *(Adjust offsets so gap between node blocks is exactly 2 cells.)*
- **`CarveLinkSouth(walls, px, pz)`** — symmetric for `iz+1`.

Only clear link cells when the logical maze has that edge; walls elsewhere stay `1`.

### 3. Remove `WidenCorridors`

Delete the method and the call after DFS. No post-processing dilation.

### 4. Calm spawn + connector

- Physical 7×7 floor at `(1,1)` (unchanged feel).
- Connector east from calm room into first logical node block at `(10, 4)` or aligned to grid: ensure spawn center `(4,4)` connects to node at `(10,4)` via 2-wide east corridor matching raster rules.

### 5. Diameter / enemies

- Keep `MaxDiameter = 58`, `MaxEnemies = 22`, `CalmExclusionRadius = 8`.
- `ComputeMaxDistance` unchanged (runs on physical floor cells).
- Enemy placement unchanged.

## Files touched

| File | Change |
|------|--------|
| [`MazeGenerator.cs`](d:\novolis\novolis-dogfooding\apps\DoomLite3D\Game\MazeGenerator.cs) | Logical maze + 2-cell rasterize; remove `WidenCorridors` |

No changes to [`GridCollision2D`](d:\novolis\novolis-math\src\Novolis.Math.Geometry\GridCollision2D.cs), [`EnemySystem`](d:\novolis\novolis-dogfooding\apps\DoomLite3D\Game\EnemySystem.cs), or LOS (already implemented).

## Verification

```bash
dotnet build novolis-dogfooding/apps/DoomLite3D/DoomLite3D.csproj
dotnet run --project novolis-dogfooding/apps/DoomLite3D/DoomLite3D.csproj
```

Manual: F1 several times — map should be a **maze** (dead ends, turns), not one hall; corridors visibly **2 cells** wide; calm 7×7 spawn still clear; enemies/LOS/collision unchanged.

