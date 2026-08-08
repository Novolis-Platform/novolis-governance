# Markdown and PDF policy

**Indisputable rule:** Novolis does **not** take dependencies on **Markdig** or **QuestPDF**. Markdown parsing/HTML and prose PDF export use Novolis-owned stacks only.

## Allowed

| Concern | Package / path |
| --- | --- |
| Markdown parse + fluent + HTML | `Novolis.Markup.Markdown` (`MarkdownDocument.Parse`, `MarkdownToHtmlConverter`) |
| Markdown → paged model | `Novolis.Markup.Markdown.Documents` |
| Prose / book / report PDF | `Novolis.Documents` + `Novolis.Documents.Layout` + `Novolis.Documents.Skia` |
| Themed MD→PDF CLI | `Novolis.Tools.MarkdownPdf` (`novolis-mdpdf`) |
| Score / freeform drawing PDF | SkiaSharp in the owning library (e.g. `Novolis.Audio.Midi`) — **not** QuestPDF |

## Forbidden

- `PackageReference` / `PackageVersion` for `Markdig` or `QuestPDF` (any version)
- `using Markdig` / `using QuestPDF` in product or test code
- Routing books or reports through a third-party PDF layout engine
- Replacing Markdig with a different third-party Markdown parser (grow `Novolis.Markup.Markdown` instead)

## Why

- **License:** QuestPDF Community eligibility is not acceptable org-wide.
- **Ownership:** One-column trade/report PDFs are a first-class Novolis island (`novolis-documents`), not a QuestPDF clone.
- **Consistency:** Studio preview, manuscript print, and tools share one Markdown engine.

## Validation

```powershell
pwsh -File d:\novolis\novolis-governance\scripts\verify-banned-packages.ps1
```

See also: [nuget-only-policy.md](nuget-only-policy.md), [library-boundaries.md](library-boundaries.md), [novolis-documents design](https://github.com/Novolis-Platform/novolis-documents/blob/main/docs/design.md).
