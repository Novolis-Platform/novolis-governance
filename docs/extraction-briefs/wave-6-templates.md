# Wave 6 — Templates merge

**Target repo:** [novolis-templates](https://github.com/Novolis-Platform/novolis-templates)  
**Naming:** [frank-naming-and-structure.md](../frank-naming-and-structure.md)

## Scope (in)

| Frank | Novolis |
|-------|---------|
| `Frank.Templates` (umbrella pack) | `Novolis.Templates` |
| 7 template packs (see below) | `content/Novolis.Templates.*` |

**Packs:** GitHubSolution, Microservice, MonoGame, NoXaml.App, NoXaml.Solution, SemanticKernel, TestContainerTemplate.

## Out of scope

- `Frank.Templates.NugetSolution` — overlaps [novolis-template-dotnet](https://github.com/Novolis-Platform/novolis-template-dotnet)
- NuGet publish (deferred)
- Separate NuGet package per template (Frank used one meta pack)

## Merge policy vs novolis-template-dotnet

- `novolis-template-dotnet`: org library/solution bootstrap scaffold
- `Novolis.Templates`: product/solution templates (`dotnet new` packs)
- Do not port NugetSolution; document install paths in README

## Short names

| Frank `shortName` | Novolis `shortName` |
|-------------------|---------------------|
| `frankmicroservice` | `novolismicroservice` |
| `frankmonogame` | `novolismonogame` |
| `githubsln` | `novolis-githubsln` |
| `noxamlapp` | `novolis-noxamlapp` |
| `noxamlsln` | `novolis-noxamlsln` |
| `semantic-kernel` | `novolis-semantic-kernel` |
| `testcontainers-module` | `novolis-testcontainers-module` (identity `Novolis.Testcontainers.Module.CSharp`) |

## TUnit in template tests

Migrate in-template test projects (Microservice, MonoGame, NoXaml.Solution) from xUnit to TUnit per [naming.md](../naming.md). No `Frank.Testing.*` package references.

## Done when

- `dotnet pack` produces `Novolis.Templates` `0.1.0-preview.1`
- `dotnet new install` + Microservice and SemanticKernel templates instantiate and build; Testcontainers scaffold instantiates
- No `Frank.*` in packed content; no xUnit in template test csprojs

## Release

`0.1.0-preview.1`
