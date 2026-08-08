# Library vs CLI / tool apps

Domain behavior lives in **libraries**. CLIs and file-based tools are **shallow hosts**.

| Kind | Owns | Examples |
|------|------|----------|
| Library | Algorithms, invariants, chapter-aware ops, DTOs | `Novolis.Manuscript`, `Manuscript.Metrics`, `Manuscript.Editorial`, `Export.Pdf`, `Export.Audio`, `Manuscript.IO` |
| CLI / tool app | Argv, exit codes, path glue, CI orchestration | `Novolis.Manuscript.Cli`, books `tools/*` shims, `run-ci` |
| Product app | Human session + Layout composition | BooksWriterStudio, BooksMobile |

## Rules

1. Ascii cleanup, metrics, character slices, surgery, doctor, editorial, and export pipelines are **library APIs** first.
2. CLIs map `--series` / `--book` / flags onto those APIs. They do not reimplement normalize/metrics/print.
3. Studio and Mobile call the **same libraries in-process**. Prefer compute APIs that do not require disk or `Console`.
4. Content-repo one-offs (Calypso lore, starsystems) may stay in books; do not drag them into product chrome.

## Related

- [avalonia-composition-grain.md](avalonia-composition-grain.md)
- [contribution-policy.md](contribution-policy.md)
