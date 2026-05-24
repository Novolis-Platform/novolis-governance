# Math.Arrays — optional `Array2D` helpers (Frank.Collections)

## What

Evaluate porting **2D array utilities** from [Frank.Collections](https://github.com/frankhaugen/Frank.Collections) into `Novolis.Math.Arrays`:

- `Array2D<T>` indexing helpers
- Observable list patterns — **out of scope** (not math)
- JSON serialization helpers — **out of scope** unless Storage wants them

Frank inventory verdict: **Defer** — “27 facts; low strategic fit” unless a consumer demands it.

## Why

- `DenseGrid<T>` already covers volumetric XZ/Y grids for Simulation occupancy.
- Some GameEngine tests used `Array2D` for letter grids; Arrays facet may need rectangular 2D buffers distinct from 3D dense grids.
- Premature port adds API surface without a dogfood driver.

## How

1. **Demand check**
   - Grep dogfood/templates for 2D grid needs not served by `DenseGrid<byte>`.
2. **If justified**
   - Add `Array2D<T>` struct or class in `Novolis.Math.Arrays` with same naming conventions (no `*2D` suffix on type name — use `Array2D` or `MatrixGrid` per [naming.md](../naming.md)).
   - Port only tests that assert real behavior (bounds, wrap, clone).
3. **If not justified**
   - Close this TODO; link to Frank.Collections for apps that want it privately.

## Acceptance

- Either closed as “no demand” or shipped with tests and README section in Arrays package.
- No dependency from Math to Frank.* packages.
