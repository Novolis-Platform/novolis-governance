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

## Wave 8b (follow-up — absorbed)

| Frank | Novolis |
|-------|---------|
| `Frank.ML.Foundation.AutoMl` | `Novolis.MachineLearning.AutoMl` |
| `Frank.ML.Domain.MlPipeline` (`MetricsExtensions`) | `Novolis.MachineLearning.AutoMl.Extensions` |

## Racing sim (not in machinelearning repo)

| Frank | Novolis |
|-------|---------|
| `Frank.ML.Domain.Racing` (sim) | `Novolis.Simulation.Racing` in `novolis-simulation` |
| `Frank.ML.Domain.Racing.Tests` (sim) | `Novolis.Simulation.Racing.Tests` |
| `Frank.ML.Domain.Racing` (trainer + neural controller) | `novolis-dogfooding/apps/NeuralRacing` (composition only) |
| Trainer tests | `novolis-dogfooding/apps/NeuralRacing.Tests` |

## Out of scope

- `Frank.ML.Domain.Legacy`, `Frank.ML.Domain.MlAssets` (sample datasets / zipped models)
- `Frank.ML.Presentation.*`, `Frank.ML.App.*`, Aspire host

## Dependencies

- `System.IO.Abstractions` only (no `Frank.*`)
- TUnit for tests

## Publishing note

NuGet packages are public on Novolis-Platform; Frank.ML may remain private on GitHub.

## Done when

- Three packages build and tests pass on `net10.0`
- Registry entries added
- Frank.ML README partial-migration block (no archive)
