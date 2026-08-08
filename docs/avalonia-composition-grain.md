# Avalonia composition grain

Authoring and tool hosts compose Avalonia packages in this order. Do not invert it.

```text
Layout shell  →  Controls atoms  →  domain chrome panels  →  app host (session + jobs)
```

| Layer | Owns | Must not own |
|-------|------|----------------|
| `Novolis.Avalonia.Layout` | Shells and regions (analyzer, authoring Wide/Narrow) | Export pipelines, workspace open, menus |
| `Novolis.Avalonia.Controls` | Reusable interaction atoms (lists, dialogs, job rows) | Whole products (publish+TTS+SCM+doctor in one control) |
| Domain chrome (e.g. `Novolis.Avalonia.Manuscript`) | Composable panes bound to library DTOs | Workspace I/O, export orchestration |
| Apps (`novolis-apps`) | Session, platform I/O, job registration, shell placement | Reimplemented domain algorithms |

## Control grain checklist

Reject or split a control when:

1. **Too specific** — embeds multiple product jobs (publish + TTS + SCM + doctor) that hosts cannot omit.
2. **Not specific enough** — generic panel with no typed contracts (`ChapterRef`, `BookSelection`, `JobHandle`).
3. **App-as-control** — opens workspaces, owns menus, or runs export pipelines inside a package.

## Adaptive shells

`AuthoringWorkspace` (Layout) exposes the same region vocabulary for desktop (Wide: nav | primary | context) and mobile (Narrow: stacked page host). Product hosts differ by which jobs they register, not by inventing a second chrome tree.

## Related

- [library-vs-cli.md](library-vs-cli.md)
- Author tooling brief: workspace canvas `author-tooling-first-principles`
