# Wave 5 — CodeGen (Reflection subset)

**Target repo:** [novolis-codegen](https://github.com/Novolis-Platform/novolis-codegen)  
**Naming:** [frank-naming-and-structure.md](../frank-naming-and-structure.md)

## Scope (in)

| Frank | Novolis |
|-------|---------|
| `Frank.Reflection` | `Novolis.CodeGen.Reflection` |
| `Frank.Reflection.Dump` | `Novolis.CodeGen.Reflection.Dump` |
| `Frank.Reflection.Mermaid` | `Novolis.CodeGen.Reflection.ClassDiagram` |
| `TypeExtensionsTests`, `DumpExtensionsTests` | TUnit in `tests/Novolis.CodeGen.*.Tests` |

## Out of scope (defer)

- `Frank.Reflection.Roslyn`, `RoslynQuoter`, `Frank.BuildTasks.MarkdownDocGenerator`
- Roslyn/doc/solution analyzer tests
- `Frank.Markdown` dependency chain

## Dependencies

- `Novolis.CodeGen.Reflection.Dump` → `Novolis.CodeGen.Reflection`
- `Novolis.CodeGen.Reflection.ClassDiagram` → `Novolis.CodeGen.Reflection`
- Dump: `Humanizer.Core`, `VarDump`, `Microsoft.CodeAnalysis.CSharp` (central `4.14.0`)
- Tests: TUnit only ([naming.md](../naming.md))

## Done when

- Three packages build on `net10.0`
- Reflection + Dump + Mermaid tests pass
- `Novolis.Testing.TUnit` references `Novolis.CodeGen.Reflection.Dump` (no duplicated Dump sources)
- No `Frank.*` in production code

## Release

`0.1.0-preview.1` per facet
