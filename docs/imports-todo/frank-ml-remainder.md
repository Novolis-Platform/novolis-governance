# Import: `Frank.ML` remainder (post-foundation)

**Source:** `D:\frankrepos\Frank.ML`

## What is already in Novolis

| Frank | Novolis |
|-------|---------|
| `Frank.ML.Foundation.Neural.*` | `novolis-machinelearning` |
| `Frank.ML.Foundation.AutoMl` | `novolis-machinelearning` |
| `Frank.ML.Foundation.Core` | Partial / evaluate |
| `Frank.ML.Domain.Racing` (simulation) | `novolis-simulation` (`Novolis.Simulation.Racing`) |

## What remains on disk

| Project | Suggestion |
|---------|------------|
| `Frank.ML.Domain.Legacy` | **Defer** — uses `Frank.Mapping`, `Frank.Libraries.Csv/Json`; mine algorithms only |
| `Frank.ML.Domain.MlPipeline` | **Partial** — pipeline abstractions → `novolis-machinelearning` if generic |
| `Frank.ML.Domain.MlAssets` | **App/private** — asset bundles stay out of platform |
| `Frank.ML.Presentation.*` (Avalonia, ConsoleSpectre, Adapter) | **Apps** — `novolis-dogfooding` or private; not platform |
| `Frank.ML.App.*`, Aspire host | **Skip** platform — product apps |
| Tests / Playwright | Port patterns to `Novolis.Testing` only |

## Why

- [wave-8-machinelearning-neural.md](../extraction-briefs/wave-8-machinelearning-neural.md) scoped **building blocks**, not domain apps.
- [library-boundaries.md](../library-boundaries.md): NN evolution on racing lives in **apps** (e.g. NeuralRacing), not `Novolis.MachineLearning.*`.
- Legacy domain would pull **Mapping** and **Libraries** monolith — import Mapping first ([frank-mapping.md](frank-mapping.md)).

## How

1. Finish [frank-mapping.md](frank-mapping.md).
2. Audit `Domain.MlPipeline` for types that are truly framework vs product.
3. Port only **packable, domain-agnostic** libraries; leave Avalonia/Web/CLI in Frank.ML or dogfooding.
4. Add partial-migration block to Frank.ML README (per [frank-partial-migration.md](../frank-partial-migration.md)).

## Acceptance

- No `Frank.Libraries.*` PackageReference in `novolis-machinelearning` production code.
- Racing sim stays in Simulation; ML training glue stays in apps.
