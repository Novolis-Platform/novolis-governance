# CAD capability inventory (generic CAD + Calypso generator)

Inventory for extracting Calypso-neutral CAD into shared Novolis packages.
CalypsoCad remains the freighter generator + CLI + thin host.

## Package ownership

| Capability | Package / host | Status |
| --- | --- | --- |
| CadDocument / CadEntity / .cadjson | `Novolis.Cad.Primitives` | Exists |
| Scene bridge / .nov3djson | `Novolis.Cad.SceneBridge` | Exists |
| Mesh evaluation / phys export | `Novolis.Cad.Evaluation` | Exists |
| Building-oriented blueprint export | `Novolis.Cad.Blueprint` | Export package (JSON + validate + smart HTML) |
| Semantic hierarchy (assemblies/parts/refs) | `Novolis.Cad.Hierarchy` | Extracted from Calypso |
| Inherit / Visible / Hidden | `Novolis.Cad.Visibility` | Extracted from Calypso |
| Orthographic / section drawing | `Novolis.Cad.Drawing` | Extracted from Calypso |
| Model generator contract | `Novolis.Cad.Generation` | New (`ICadModelGenerator`) |
| Document session / commands / editor UI | `Novolis.Avalonia.Cad` | Exists (`CadDocumentSession`, `CadSessionService`, `CadEditorSurface`) |
| Generic CAD Studio host | `novolis-apps/CadStudio` | Exists |
| Calypso lock / steel / fab / acceptance | `novolis-lab/.../CalypsoCad` | Domain-only |

## Host strategy

- **CadStudio** — generic CAD product (no Calypso types).
- **CalypsoCad** — thin composition: Avalonia.Cad services + Calypso `ICadModelGenerator` + Calypso overlays/CLI.
- Interactive editing targets `CadEditorSurface` / `CadModelRenderer`.
- Calypso Silk headless exporters remain Calypso tooling, not the generic viewport kernel.

## Gaps filled by this refactor

1. Hierarchy + visibility were Calypso-local → `Novolis.Cad.Hierarchy` / `.Visibility`.
2. Universal drawing was Calypso-local → `Novolis.Cad.Drawing` (Calypso templates stay in lab).
3. No `ICadModelGenerator` → `Novolis.Cad.Generation`.
4. Process globals `CadDocumentAdapter.Active` / `HullGeometry.Active` → session / generation context.
5. Avalonia.Cad lacked Inherit/Visible/Hidden UI → hierarchy tree controls on the session.

## Non-goals

- Redesign Calypso hull / frames / knuckles.
- Second document format or second command bus.
- Avalonia inside generators.
- Silk.NET outside `novolis-silk` composition.
