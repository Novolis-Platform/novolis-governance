# Wave 8 — Frank.ML neural foundation

**Target repo:** [novolis-machinelearning](https://github.com/Novolis-Platform/novolis-machinelearning)  
**Source:** [frankhaugen/Frank.ML](https://github.com/frankhaugen/Frank.ML) (private; personal repo stays active)  
**Naming:** [frank-naming-and-structure.md](../frank-naming-and-structure.md)

## Scope (in)

| Frank | Novolis |
|-------|---------|
| `Frank.ML.Foundation.Core` | `Novolis.MachineLearning.Core` |
| `Frank.ML.Foundation.Neural.Abstractions` | `Novolis.MachineLearning.Neural.Abstractions` |
| `Frank.ML.Foundation.Neural.Implementation` | `Novolis.MachineLearning.Neural` |
| `Frank.ML.Foundation.Core.Tests` | `Novolis.MachineLearning.Core.Tests` |
| `Frank.ML.Foundation.Neural.Tests` | `Novolis.MachineLearning.Neural.Tests` |

## Out of scope (wave 8)

- `Frank.ML.Foundation.AutoMl` (Microsoft.ML) — later wave
- `Frank.ML.Domain.*`, `Frank.ML.Presentation.*`, `Frank.ML.App.*`, Aspire host

## Dependencies

- `System.IO.Abstractions` only (no `Frank.*`)
- TUnit for tests

## Publishing note

NuGet packages are public on Novolis-Platform; Frank.ML may remain private on GitHub.

## Done when

- Three packages build and tests pass on `net10.0`
- Registry entries added
- Frank.ML README partial-migration block (no archive)
