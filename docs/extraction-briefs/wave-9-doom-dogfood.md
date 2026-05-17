# Wave 9 — Doom-lite dogfood (3D FPS demo)

**Target repos:** [novolis-math](https://github.com/Novolis-Platform/novolis-math), [novolis-raylib](https://github.com/Novolis-Platform/novolis-raylib), [novolis-physics](https://github.com/Novolis-Platform/novolis-physics) (phase 2), [novolis-dogfooding](https://github.com/Novolis-Platform/novolis-dogfooding)  
**Source inspiration:** [Frank.GameEngine](https://github.com/frankhaugen/Frank.GameEngine) `FpsCameraState` (redesigned, not copied)  
**Acceptance app:** `novolis-dogfooding/apps/DoomLite3D`

## Scope (in)

| Area | Novolis home | Notes |
|------|--------------|-------|
| First-person yaw/pitch camera | `Novolis.Math.Geometry.FirstPersonCamera` | Renderer-agnostic; no Frank types |
| Grid wall collision (XZ) | `Novolis.Math.Geometry.GridCollision2D` | Uses `Novolis.Math.Arrays.DenseGrid<byte>` |
| 3D billboards + floor plane | `Novolis.Raylib` codegen (`World.DrawBillboard*`, `DrawPlane`) | Manifest + facade |
| Jam texture/billboard helpers | `Novolis.Raylib.Game.RayGameContext` | `LoadTexture`, `DrawBillboard` |
| Single-level demo game | `novolis-dogfooding/apps/DoomLite3D` | Dogfoods all of the above |
| Room mesh from wall grid (phase 2) | `Novolis.Physics.Collision.Simple.RoomMeshBuilder` | Optional BVH dogfood |

## Out of scope

- `Frank.GameEngine.Rendering.*` (per [gameengine-reference-policy.md](../gameengine-reference-policy.md))
- Classic 2.5D raycaster, WAD loader, multiplayer, audio bindings
- `GameObject`, `Scene`, `Scene2D`, `Sprite2D` engine graph

## Dependencies

- `Novolis.Math.Geometry` → `Novolis.Math.Arrays` (for `DenseGrid<byte>` in collision)
- Dogfood app → `Novolis.Raylib`, `Novolis.Math.Arrays`, `Novolis.Math.Geometry`
- Phase 2: `Novolis.Physics` + math arrays

## Assets

- Kenney [Tiny Dungeon](https://kenney.nl/assets/tiny-dungeon) (CC0) — vendored subset under `apps/DoomLite3D/Assets/` with `CREDITS.md`
- No id Software Doom/Wolfenstein art

## Done when

- `dotnet build` / `dotnet run --project apps/DoomLite3D` from `novolis-dogfooding`
- New math APIs have TUnit tests
- Raylib billboards/plane in generated `World` + `RayGameContext`
- `CREDITS.md` lists every external file and source URL

## Related

- [wave-7-gameengine-math.md](wave-7-gameengine-math.md)
- [wave-7b-raylib-obj.md](wave-7b-raylib-obj.md)
