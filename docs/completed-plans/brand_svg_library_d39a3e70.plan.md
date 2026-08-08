---
name: brand svg library
overview: Refactor the current single-file C# brand generator into a deliberate in-file library design and proof of concept for a future SVG/imaging repository. Keep everything in `generate-pixel-outlines.cs` for now, but organize it as if it were already the new library API.
todos:
  - id: design-single-file-library
    content: Restructure the file-based app into clear in-file library sections and APIs.
    status: completed
  - id: model-brand-assets
    content: Model logo shapes, lockup variants, overlays, icons, and social assets as reusable recipes.
    status: completed
  - id: generate-brand-outputs
    content: Generate all current and new brand SVG outputs from the single-file library design.
    status: completed
  - id: document-extraction-template
    content: Document the single-file API as the template for the future SVG/imaging repo.
    status: completed
isProject: false
---

# Brand SVG Single-File Library Prototype

## Goal

Turn the current one-file generator at [`d:/novolis/.github/brand/generate-pixel-outlines.cs`](d:/novolis/.github/brand/generate-pixel-outlines.cs) into a clean single-file library design. It should remain a file-based C# app for now, but internally read like the prototype API for a future `novolis-svg` / `novolis-imaging` repository.

The immediate target is not a multi-project extraction. The immediate target is a strong proof of concept:

- A reusable SVG model and path DSL.
- A brand asset pipeline expressed as recipes.
- Multiple output variants generated from the same shape source.
- A clear template for the future reusable libraries.

## Proposed Structure

Keep the implementation in [`d:/novolis/.github/brand/generate-pixel-outlines.cs`](d:/novolis/.github/brand/generate-pixel-outlines.cs), but reorganize the file into library-like sections:

- App/CLI entry point: parses requested outputs and writes files.
- SVG core: `Vec`, path commands, document builder, gradients, text, image references, overlays.
- Geometry helpers: arcs, sectors, point labels, shape bounds, simple transforms.
- Brand model: canonical Novolis shapes `upper`, `lower`, `n`, `n_left`, `n_right`, `star`.
- Asset recipes: full lockup, mark-only, overlay, per-shape SVGs, icon/social templates.
- Optional image bridge: SVG-to-PNG command wrapper or interface placeholder, not a hard dependency yet.

## Refactor Steps

1. Restructure the file into a library-style layout:
   - Keep top-level app code very small.
   - Move reusable primitives into clearly named static/record types.
   - Keep Novolis logo coordinates isolated from SVG serialization.

2. Refine the SVG core API:
   - `Vec`
   - `VectorPath`
   - `SvgShape`
   - `SvgDocument`
   - `SvgGradient`
   - overlay/control-point helpers
   - escaping and attribute writing

3. Model Novolis brand assets as recipes:
   - Keep the six shape names exactly: `upper`, `lower`, `n`, `n_left`, `n_right`, `star`.
   - Define gradients once.
   - Define the wordmark/tagline once.
   - Define canvas/viewBox presets once.
   - Preserve the current full logo and overlay output.

4. Add output variants from the same model:
   - Full lockup: `logo-brand-transparent.svg`.
   - Feedback overlay: `logo-brand-transparent-overlay.svg`.
   - Mark-only SVG: no wordmark/tagline.
   - Per-shape SVGs: one output each for `upper`, `lower`, `n`, `n_left`, `n_right`, `star`.
   - Icon/social SVG templates: square icon, social card, transparent mark.

5. Keep PNG rendering as a library boundary:
   - Do not bake a renderer into the SVG core API yet.
   - Provide an adapter method/command shape such as `RenderSvgToPng(...)`.
   - For now it can shell out to the existing renderer command.
   - Later it can become a real package abstraction in the new repo.

6. Update docs in [`d:/novolis/.github/brand/README.md`](d:/novolis/.github/brand/README.md):
   - Document the single-file library sections.
   - Document generated outputs and shape names.
   - Document which parts are the template for future extraction.

7. Add lightweight regression checks:
   - Verify generated SVG contains exactly the expected shape names.
   - Verify `overlay` exposes numbered labels like `n:1`, `star:4`.
   - Verify full SVG, overlay SVG, and mark-only SVG render with the current renderer command.

## Later Extraction

Once the single-file library API feels right, create a new repo/package using this file as the template. Candidate repo directions:

- `novolis-svg`: SVG model, path DSL, document writer, gradients, text, overlays.
- `novolis-imaging`: SVG-to-PNG, raster export presets, social-card/icon generation.
- Or a single `novolis-branding`/`novolis-graphics` repo if the split feels premature.

The future extraction should keep brand-specific logo coordinates outside the generic SVG library. The generic library should know how to write shapes and render assets; the brand app should define the Novolis logo.
