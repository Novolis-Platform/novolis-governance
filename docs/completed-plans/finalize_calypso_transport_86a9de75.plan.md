---
name: Finalize Calypso transport
overview: Lock CalypsoCad to the RevE/RevG + Chapter 16 canon (65×20×12 m), complete the missing room/opening/shaft inventory from book references, and push the renderer from abstract grey boxes to a readable three-deck space transport with lore-accurate interior cues.
todos:
  - id: canon-and-rooms
    content: Complete RevG/Ch16 room inventory + partitions; arrayInstance cabins/berths; stairs/elev shafts
    status: completed
  - id: cargo-openings
    content: Single hollow cargo void + armored door, aft ramp, catwalk; full door/hatch opening set with hostWallId
    status: completed
  - id: opening-derivation
    content: Derive wall baseline splits from openings before writing .cadjson
    status: completed
  - id: renderer-ship-pass
    content: Polygon floors, zone props (bridge/galley/cabin/lounge/eng/airlock/cargo), orbit exterior gunmetal + nacelles
    status: completed
  - id: headless-tour
    content: Headless multi-space tour exports + README canon/checklist
    status: completed
isProject: false
---

# Finalize Calypso transport (RevE / RevG)

## Canon lock (from book sources)

Prefer **Chapter 16 / `calypso-manuscript-facts.md`** over conflicting drawings. Finalize against:

- Hull: **65 × 20 × 12 m**, hold **22 × 19 × 9 m**, registry ST-7749-63325116
- Decks: **−1 utilities**, **0 ops/crew**, **+1 passengers**
- Dual corridors per deck → bow convergence → aft armored hold door
- Materials: gunmetal riveted/faceted steel exterior; industrial lining + deck plate interior

**Out of scope this pass:** RevF ~90 m / C40 stretch, 160 m legacy, maritime PKG-04 (diesel/aluminum). Raylib `World` has no `DrawTriangle3D` yet — keep immediate-mode cubes/lines/planes; denser faceting, not a mesh pipeline.

Primary references:

- [calypso-deckplans_revG.svg](D:/repos/books/content/series/the-calypso-cycle/references/ships/calypso/assets/images/calypso-deckplans_revG.svg) (+ `_detail` / `_details_extended`)
- [calypso-manuscript-facts.md](D:/repos/books/content/series/the-calypso-cycle/references/ships/calypso/calypso-manuscript-facts.md)
- [cargo-systems.md](D:/repos/books/content/series/the-calypso-cycle/references/cargo/cargo-systems.md)
- Ch. 3 / 5 / 16 walkthrough prose

```mermaid
flowchart LR
  refs["RevG SVG + Ch16 facts"] --> gen["CalypsoRevGGenerator"]
  gen --> cad[".cadjson wall/space/opening/hooks"]
  cad --> derive["Opening cut + shaft weld"]
  derive --> render["CalypsoRenderer ship pass"]
  render --> png["Headless tour PNGs"]
```

## Phase 1 — Complete the RevG program in the generator

Update [CalypsoRevGGenerator.cs](d:/novolis/novolis-dogfooding/apps/cad/CalypsoCad/Generation/CalypsoRevGGenerator.cs):

1. **Every room gets partitions** — today many spaces are floor-only. Emit `AddRectWalls` (or polygon walls) for all habitable spaces on −1/0/+1.
2. **Individual cabins via `arrayInstance`** — replace blob `Crew Cabins (5)` / `Berths (10)` with prototype cabin (~1.92×7.2 m) + array placement; derive explicit walls/spaces for render. Add bunk/wet-unit props hooks.
3. **Vertical circulation** — Stairs + Elev as continuous shafts spanning decks −1→+1 (one `space` per deck with shared footprint + hooks `StairsCore` / `ElevCore`; walls form a shaft).
4. **Cargo as one hollow volume** — single multi-deck void (keep `flags.hollow`), plus:
   - armored bulkhead + `opening` hatch on Deck 0
   - aft ramp `openingType: ramp` (4×3 m clear)
   - fore catwalk (~3 m into hold) as thin walkway boxes on decks 0/+1
5. **Openings everywhere that matter** — not just Bridge Door:
   - cabin doors onto corridors
   - airlock outer/inner hatches
   - galley/infirmary/engineering doors
   - armored cargo door
6. **Lore hooks** (camera targets): `OwnerLock`, `ArmoryCrossing`, `GalleyGrowthChart`, `PhotoWallBridge`, `AftRamp`, `AirlockPort`, `AirlockStarboard`.
7. **Exterior hull** — keep faceted RevG outer loop; optionally add side nacelle/engine-pod boxes from overview (gunmetal) so orbit reads as a transport, not a shoe box.

Keep toolkit ops real where cheap: cabin `arrayInstance` expands to walls/spaces; openings store `hostWallId` and derivation splits wall baselines around footprints.

## Phase 2 — Derivation: openings actually cut walls

Add a small derive step in the generator (or `CadDocumentStore` post-process) before write:

- For each `opening` with `hostWallId` (or nearest wall by footprint), split the host wall baseline into two segments with a gap = opening width.
- Persist cut walls in `.cadjson` so the renderer stops relying on proximity hacks alone.
- Mark connected spaces via opening `properties` (`connects: [spaceA, spaceB]`) for later enclosure checks.

## Phase 3 — Renderer: full-ship atmosphere pass

Update [CalypsoRenderer.cs](d:/novolis/novolis-dogfooding/apps/cad/CalypsoCad/Services/CalypsoRenderer.cs):

1. **Polygon floors** — triangulate/fill from `space.points` via fan of small cubes or `DrawPlane` tiles inside the footprint AABB clipped to edges (no more pure AABB “bridge box”).
2. **Zone props** (selected interior):
   - Bridge: viewport + consoles + helm + photo-wall strip + owner-lock floor marker
   - Galley: counter/sink block + growth-chart hook marker
   - Infirmary: medbed slab
   - Cabins/berths: bunk stack + locker + wet unit
   - Lounge: bar counter + overhead screen slab
   - Engineering: bus/plant racks
   - Airlocks: bench + suit-hook posts
   - Cargo void: gantry + tie-down cleats + catwalk
3. **Orbit exterior** — hull walls solid gunmetal; hide candy zone floors or keep as very dim deck plates; show nacelle pods; emphasize hold aft.
4. **Interior lighting** — keep industrial palette; ceiling modules + cyan console glow; emergency edge strips in corridors.
5. **Hook camera** — already wired; ensure new lore hooks land usable eye positions.

## Phase 4 — UI / headless verification tour

Update [HeadlessPngExporter.cs](d:/novolis/novolis-dogfooding/apps/cad/CalypsoCad/Services/HeadlessPngExporter.cs) + [MainWindow.cs](d:/novolis/novolis-dogfooding/apps/cad/CalypsoCad/MainWindow.cs):

Export a fixed tour set:

- plan deck −1 / 0 / +1
- orbit exterior
- interior: Bridge, Crossing Hallway, Crew Cabin #1, Galley, Cargo Void, Passenger Lounge, Airlock Port

Update [README.md](d:/novolis/novolis-dogfooding/apps/cad/CalypsoCad/README.md) with canon lock note + tour checklist.

## Done when

- RevG room list matches Chapter 16 spine (no missing stairs/elev shafts, airlocks, armored hold access, aft ramp).
- Cabins/berths are individual spaces, not one blob.
- Doors/hatches create visible wall gaps.
- Cargo reads as enclosed-yet-hollow with catwalk/gantry.
- Bridge / galley / lounge / eng interiors have recognizable props (not empty grey rooms).
- Headless tour PNGs under `%LocalAppData%\Novolis\CalypsoCad\generated\exports\` look like a three-deck freighter, not abstract sculpture.

