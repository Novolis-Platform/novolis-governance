# Platform import — Phase 4 backlog

Tracked in [platform-import-plan.md](platform-import-plan.md). **Do not start** until Phase 1–2 packages are on GPR (`2026.1.*`).

| Wave | Repo | Frank source | Blockers |
|------|------|--------------|----------|
| 4.1 | `novolis-workflow-engine` | `Frank.WorkflowEngine` | `novolis-mapping`, `novolis-scheduling`, messaging facade (`novolis-workflows` = GitHub Actions only) |
| 4.2 | `novolis-data` EF facet | `Frank.EntityFrameworkCore` | Testing GPR |
| 4.3 | Codegen devtools | `Frank.SolutionManager`, `GitKit`, `Blazor.JsInteropGenerator` | [frank-codegen-devtools.md](imports-todo/frank-codegen-devtools.md) |
| 4.4 | ML remainder | `Frank.ML` apps/domain | **Audit:** presentation stays in apps; domain in `novolis-machinelearning` + `novolis-simulation` only |

## ML remainder audit (2026-05-25)

- **Keep in platform:** neural foundation (`novolis-machinelearning`), racing sim (`Novolis.Simulation.Racing`).
- **Apps only:** Blazor dashboards, training UI, dataset browsers from `Frank.ML` presentation projects.
- **Skip:** duplicate AutoML hosts already covered by machinelearning repo scope.
