# Avalonia composition grain

Authoring and tool hosts compose Avalonia packages in this order. Do not invert it.

```text
Layout shell  →  Controls atoms (+ Controls.Sketch)  →  domain chrome panels  →  app host (session + jobs)
```

| Layer | Owns | Must not own |
|-------|------|----------------|
| `Novolis.Avalonia.Layout` | Shells and regions (analyzer, authoring Wide/Narrow) | Export pipelines, workspace open, menus |
| `Novolis.Avalonia.Controls` | Reusable interaction atoms (lists, dialogs, job rows, sortable grids, hex/detail) | Whole products; transport-bound chrome; sketch engine |
| `Novolis.Avalonia.Controls.Sketch` | SketchControl + document model (Controls sub-library) | App hosts / product chrome |
| Domain chrome (e.g. `Manuscript`, `Git`, `Torrent`, `Cad`, `Cad.Ship`, `StarMap`) | Composable panes bound to library DTOs | Workspace I/O, export orchestration |
| Apps (`novolis-apps`) | Session, platform I/O, job registration, shell placement | Reimplemented domain algorithms |

## Control grain checklist

Reject or split a control when:

1. **Too specific** — embeds multiple product jobs (publish + TTS + SCM + doctor) that hosts cannot omit.
2. **Not specific enough** — generic panel with no typed contracts (`ChapterRef`, `BookSelection`, `JobHandle`).
3. **App-as-control** — opens workspaces, owns menus, or runs export pipelines inside a package.

Ship/freighter CAD belongs in `Novolis.Avalonia.Cad.Ship` (or the product host), not core `Novolis.Avalonia.Cad`. Snapshot “git log” UI for workspace timelines belongs in the dogfood host if needed — there is no `Novolis.Avalonia.Timeline` package.

## Adaptive shells

`AuthoringWorkspace` (Layout) exposes the same region vocabulary for desktop (Wide: nav | primary | context) and mobile (Narrow: stacked page host). Product hosts differ by which jobs they register, not by inventing a second chrome tree.

## Related

- [library-vs-cli.md](library-vs-cli.md)
- Author tooling brief: workspace canvas `author-tooling-first-principles`
