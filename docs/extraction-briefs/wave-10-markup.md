# Wave 10 — Markup (Markdown + Mermaid)

**Target repo:** [novolis-markup](https://github.com/Novolis-Platform/novolis-markup)  
**Naming:** [frank-naming-and-structure.md](../frank-naming-and-structure.md)

## Scope (in)

| Frank | Novolis |
|-------|---------|
| `Frank.Markdown` | `Novolis.Markup.Markdown` |
| `Frank.Mermaid` | `Novolis.Markup.Mermaid` |
| Frank test projects | TUnit in `tests/Novolis.Markup.*.Tests` |

## Out of scope

- `Frank.Reflection.Mermaid` — lives in `novolis-codegen` as `Novolis.CodeGen.Reflection.Mermaid`
- `Frank.Blazor.Mermaid`, `Frank.MarkdownEditor` (apps/UI)
- `Frank.Mermaid.Docs` sample (drop or README-only examples)

## Dependencies

- Independent packages; no cross-`ProjectReference` between Markdown and Mermaid
- Tests: TUnit + FluentAssertions only ([naming.md](../naming.md))

## Done when

- Both packages build on `net10.0`
- All ported tests pass
- No `Frank.*` in production code
- Registry entries for both packages
- Personal `Frank.Markdown` and `Frank.Mermaid` archived with sunset README

## Release

`0.1.0-preview.1` per facet
