# Library vs executable hosts

Domain behavior lives in **libraries**. Executable hosts are shallow compositions over those libraries, and their publishing home is determined by audience and lifecycle.

| Kind | Owns | Examples |
|------|------|----------|
| Library | Algorithms, invariants, chapter-aware ops, DTOs | `Novolis.Manuscript`, `Manuscript.Metrics`, `Manuscript.Editorial`, `Export.Pdf`, `Export.Audio`, `Manuscript.IO` |
| Tool | Argv, exit codes, path glue, CI orchestration for .NET developers | `novolis-manuscript`, `novolis-coverage`, `novolis-docs` in `novolis-tools` |
| Utility | One small technical executable, with optional tiny UI | NDJSON explorer, ADB utility, WireFish viewer in `novolis-utilities` |
| Product app | Human session + Layout composition | BooksWriterStudio, BooksMobile |
| Lab | Temporary integration host, smoke, benchmark, or walkthrough | `novolis-lab` |

## Rules

1. Ascii cleanup, metrics, character slices, surgery, doctor, editorial, and export pipelines are **library APIs** first.
2. Tools map `--series` / `--book` / flags onto those APIs. They do not reimplement normalize/metrics/print.
3. Utilities map technical files, devices, or wire protocols onto the same APIs. They do not become a second product UI.
4. Studio and Mobile call the **same libraries in-process**. Prefer compute APIs that do not require disk or `Console`.
5. Content-repo one-offs (Calypso lore, starsystems) may stay in labs or private repository tools; do not drag them into product chrome.
6. Domain tool hosts do not live beside their libraries. `novolis-tools` is the sole publisher for `PackAsTool` commands.

## Related

- [avalonia-composition-grain.md](avalonia-composition-grain.md)
- [contribution-policy.md](contribution-policy.md)
