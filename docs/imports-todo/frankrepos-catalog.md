# `D:\frankrepos` — repository catalog

Full inventory of local Frank repos (2026-05-25) and recommended Novolis disposition.

## Already migrated (code in `d:\novolis`)

| `D:\frankrepos` | Novolis repo | Notes |
|-----------------|--------------|-------|
| `Frank.Channels.DependencyInjection` | `novolis-messaging` | `Novolis.Messaging.Channels` |
| `Frank.PulseFlow` | `novolis-messaging` | `Novolis.Messaging` |
| `Frank.Testing` | `novolis-testing` | TUnit, Testcontainers, … |
| `Frank.BedrockSlim` | `novolis-transports` | Tcp Server/Client |
| `Frank.Http` | `novolis-transports` | Http facets |
| `Frank.DataStorage` (subset) | `novolis-storage` | Json, Sqlite, Abstractions |
| `Frank.Security` | `novolis-security` | Secrets, hashing, HIBP |
| `Frank.Analyzers` (subset) | `novolis-analyzers` | AutoMapper, CodeLength |
| `Frank.Reflection` (subset) | `novolis-codegen` | Reflection, Dump, Mermaid |
| `Frank.Templates` | `novolis-templates` | Merged with template-dotnet |
| `Frank.GameEngine.Primitives` (subset) | `novolis-math` | Arrays, Geometry, Topology |
| `Frank.ML` Foundation Neural + AutoMl | `novolis-machinelearning` | |
| `Frank.ML.Domain.Racing` (sim) | `novolis-simulation` | `Novolis.Simulation.Racing` |
| `Frank.WireFish` | `novolis-transports` | `Novolis.Transports.WireFish` |
| `Frank.Markdown` / `Frank.Mermaid` | `novolis-markup` | Wave 10 |
| `Frank.SimpleInstaller` | `novolis-install` | Rebuild ideas only |

## Import candidates (documented in this folder)

| Repo | Packable focus | Target |
|------|----------------|--------|
| `Frank.GameEngine` | Assets, Input, Audio, 2D, Core | See `gameengine-*.md` |
| `Frank.Mapping` | Mapping + analyzers | [frank-mapping.md](frank-mapping.md) |
| `Frank.Messaging` | Abstractions + Channels provider | [frank-messaging-facade.md](frank-messaging-facade.md) |
| `Frank.CronJobs` | Cron + scheduler | [frank-scheduling-cronjobs.md](frank-scheduling-cronjobs.md) |
| `Frank.WorkflowEngine` | Workflow DI | [frank-workflow-engine.md](frank-workflow-engine.md) |
| `Frank.EntityFrameworkCore` | Repositories, Audit | [frank-entityframeworkcore.md](frank-entityframeworkcore.md) |
| `Frank.Blazor.JsInteropGenerator` | Roslyn | [frank-codegen-devtools.md](frank-codegen-devtools.md) |
| `Frank.SolutionManager` | Solution tooling | [frank-codegen-devtools.md](frank-codegen-devtools.md) |
| `Frank.GitKit` | Git/Azure DevOps | [frank-codegen-devtools.md](frank-codegen-devtools.md) |
| `Frank.ML` (remainder) | Legacy, MlPipeline, Presentation | [frank-ml-remainder.md](frank-ml-remainder.md) |
| `Frank.Networking` | TCP helpers, IRC | [frank-networking-caching.md](frank-networking-caching.md) |
| `Frank.UmbrellaCache` | Distributed cache | [frank-networking-caching.md](frank-networking-caching.md) |
| `Frank.LanguageDetector` | Language ID | [frank-networking-caching.md](frank-networking-caching.md) |

## Explicit skip (see [frank-repos-explicit-skip.md](frank-repos-explicit-skip.md))

`Frank.Wpf`, `Frank.CrossPlatformWindow`, `Frank.HttpDude`, `Frank.Brewery`, `Frank.Logbook`, `Frank.IRC`, `Frank.Finance.Documents.Ubl`, `Frank.TorrentClient`, `Frank.ServiceBusExplorer` (EtherRipple), `Frank.Apps`, `Frank.XsdCodeGeneration` (author dead-end), `Frank.Libraries` (monolith — decompose only if needed).

## Not present locally

| Name | Inventory note |
|------|----------------|
| `Frank.Libraries` | GitHub monolith; catalog only |
| `Frank.Collections` | `Array2D` — defer to [internal-novolis-audit/math-arrays-array2d-helpers.md](internal-novolis-audit/math-arrays-array2d-helpers.md) |

## `Frank.GameEngine` project map

| Project | Import? |
|---------|---------|
| `Frank.GameEngine.Primitives` | **No** (3D math → `novolis-math` done) |
| `Frank.GameEngine.Physics` | **No** (`novolis-physics` supersedes) |
| `Frank.GameEngine.Rendering` | **Partial** (headless exporters only if needed) |
| `Frank.GameEngine.Rendering.RayLib` | **No** (`novolis-raylib` active lane) |
| `Frank.GameEngine.Rendering.MonoGame` | **Defer** (template exists) |
| `Frank.GameEngine.Assets` | **Yes** → [gameengine-assets-mesh-import.md](gameengine-assets-mesh-import.md) |
| `Frank.GameEngine.Input` | **Yes** → [gameengine-input.md](gameengine-input.md) |
| `Frank.GameEngine.Audio` | **Yes** → [gameengine-audio.md](gameengine-audio.md) |
| `Frank.GameEngine.Core` | **Maybe** → [gameengine-core-composition.md](gameengine-core-composition.md) |
| `Frank.GameEngine.Generators.AssetsGenerator` | **With Assets** | Roslyn `AdditionalFiles` helpers |
