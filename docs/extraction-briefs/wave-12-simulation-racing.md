# Wave 12 — Frank.ML racing sim → `Novolis.Simulation.Racing`

**Target repo:** [novolis-simulation](https://github.com/Novolis-Platform/novolis-simulation)  
**Source:** [frankhaugen/Frank.ML](https://github.com/frankhaugen/Frank.ML) `Frank.ML.Domain.Racing` (sim subset)  
**Naming:** [frank-naming-and-structure.md](../frank-naming-and-structure.md)

## Scope (in)

| Frank | Novolis |
|-------|---------|
| `Frank.ML.Domain.Racing` (tracks, race loop, sensors, rewards, controllers except neural) | `Novolis.Simulation.Racing` |
| Sim tests (`Frank.ML.Domain.Racing.Tests`, minus trainer tests) | `Novolis.Simulation.Racing.Tests` |

## Composition (not in simulation repo)

| Frank | Novolis |
|-------|---------|
| `EvolutionaryRacingTrainer`, `NeuralRaceCarController` | `novolis-dogfooding/apps/NeuralRacing` |
| Trainer tests | `novolis-dogfooding/apps/NeuralRacing.Tests` |

## Dependencies

- `Novolis.Simulation.Racing`: BCL only (no `Novolis.MachineLearning.*`)
- Dogfood app: `PackageReference` to `Novolis.Simulation.Racing` + `Novolis.MachineLearning.Neural`

## Notes

- Transitional `NOV2002` suppression for `Vector2` until XZ `Vector3` migration.
- No `MachineLearning.Racing` package — ML repo stays building-block only.

## Done when

- `Novolis.Simulation.Racing` builds; sim tests pass in `novolis-simulation` CI
- Dogfood `NeuralRacing` runs evolution demo against packaged/local feed
- Registry entry `novolis-simulation-racing.json` added
