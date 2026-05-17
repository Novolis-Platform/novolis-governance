# Wave 5 — Analyzers (subset)

**Target repo:** [novolis-analyzers](https://github.com/Novolis-Platform/novolis-analyzers)  
**Naming:** [frank-naming-and-structure.md](../frank-naming-and-structure.md)

## Scope (in)

| Frank | Novolis |
|-------|---------|
| `Frank.Analyzers.AutoMapper` | `Novolis.Analyzers.AutoMapper` |
| `Frank.Analyzers.CodeLength` | `Novolis.Analyzers.CodeLength` |
| `AutomapperAnalyzerTests` (may stay skipped) | TUnit in `tests/Novolis.Analyzers.Tests` |
| New CodeLength smoke tests | TUnit — Frank had none |

## Out of scope (defer)

- CppInteropts, BlankAnalyzer, XUnit/Localization source generators
- `AdditionalFiles`, `Refactoring.AutoProperties`

## Packaging

- Pack analyzer DLL to `analyzers/dotnet/cs`
- Test projects reference analyzers with `OutputItemType="Analyzer"` and `ReferenceOutputAssembly="false"`
- Consumer tests use `Microsoft.CodeAnalysis.CSharp.Analyzer.Testing` (no xUnit testing packages)

## Diagnostic IDs

Keep Frank `FRANK####` IDs for AutoMapper stability in this wave; CodeLength uses `FRANK4001`/`FRANK4002` style from source. Rebrand to `NOVL####` in a follow-up if desired.

## Done when

- Both analyzer packages build and pack on `net10.0`
- CodeLength has at least one passing TUnit smoke test
- AutoMapper tests compile (skipped OK)
- No `Frank.*` in production code

## Release

`0.1.0-preview.1` per facet
