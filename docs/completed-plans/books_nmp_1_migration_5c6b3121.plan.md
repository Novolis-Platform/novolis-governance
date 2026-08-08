---
name: Books NMP/1 migration
overview: Migrate `frankhaugen/books` from legacy `content/` layout to NMP/1 on latest `main`, update books build/CI/tools in the same change set, and extend the Novolis.Manuscript workspace façade plus Books apps so Studio/Mobile keep opening the repo after the cutover.
todos:
  - id: sync-main
    content: Park WIP; reset books to origin/main; branch nmp1-content-migration; baseline build.ps1
    status: completed
  - id: reshape-tree
    content: Add manuscript.yaml + universe/subject; move series/books to src/Fiction|NonFiction; flatten books/; rename Chapters/References
    status: completed
  - id: normalize-meta
    content: Strip renderer/structural book.yaml fields; add series order; convert callouts to YAML front matter
    status: completed
  - id: books-tools-ci
    content: Retarget compile-*, book-tool, run-ci, books-writer, docs/rules to NMP paths; keep build.ps1 green
    status: completed
  - id: manuscript-facade
    content: Extend Novolis.Manuscript TryOpen/catalog projection for NMP; tests; publish GPR
    status: completed
  - id: apps-cutover
    content: BooksMobile ContentPrefix src/; Studio open messaging; ProjectRef build smoke
    status: completed
  - id: verify-matrix
    content: Protocol doctor + build.ps1 + run-ci + app builds; confirm no content/ leftovers
    status: completed
isProject: false
---

# Books repo → NMP/1 migration (buildable on latest main)

Source of truth for gaps: [books-nmp1-compatibility.canvas.tsx](C:\Users\frank\.cursor\projects\d-novolis\canvases\books-nmp1-compatibility.canvas.tsx) + [PROTOCOL.md](d:\novolis\novolis-manuscript\src\Novolis.Manuscript.Protocol\PROTOCOL.md).

## Locked decisions (defaults)

| Decision | Choice |
|----------|--------|
| Cutover | **Hard-cut** `content/` → NMP `src/` on books `main` (no dual-tree mirror) |
| Universe id | `galactic-confederation` for all current fiction series (`the-calypso-cycle`, `gunny-butler`) |
| Standalone book | `content/books/intro-to-programming` → `src/NonFiction/software-engineering/intro-to-programming/` |
| Chapter renumber | **Keep** existing integer prefixes (`001-…`); do not mass-renumber to 10/20/30 gaps in this PR |
| Order authority | Filename prefix only after cutover; drop `chapter_order_from_heading` / booktools-as-order |
| App compatibility | Extend `Novolis.Manuscript` to open NMP workspaces and project into existing `SeriesInfo`/`BookInfo` catalog; apps switch sparse prefix to `src/` |
| Git base | Work only on **latest `origin/main`** after parking local WIP |

```mermaid
flowchart LR
  sync[Sync books to origin/main]
  tree[Reshape tree + markers]
  meta[book.yaml + chapter FM]
  tools[Update books tools/CI/docs]
  facade[Manuscript facade opens NMP]
  apps[Apps ContentPrefix + open]
  verify[build.ps1 + Protocol doctor + app build]

  sync --> tree --> meta --> tools
  tools --> facade --> apps --> verify
```

## Phase 0 — Sync to latest main (non-negotiable)

Local checkout is **behind `origin/main` by 2 commits** and has dirty chapter files:

- `content/series/the-calypso-cycle/books/infinite-brutality-infinite-compassion/chapters/023-dave-at-the-door.md`
- `content/series/the-calypso-cycle/books/personage/chapters/01-whale-watching.md`

Steps:

1. `git fetch origin main` in `D:\repos\books`
2. Stash or commit WIP on a throwaway branch (do **not** mix WIP into the migration PR unless intentional)
3. `git switch main && git reset --hard origin/main` (or fast-forward merge once clean)
4. Create branch `nmp1-content-migration` from that tip
5. Confirm green baseline before moves:  
   `pwsh -File D:\repos\books\build.ps1`  
   and/or `dotnet run -c Release --file D:\repos\books\tools\ci\run-ci.cs`

## Phase 1 — Filesystem reshape (books)

Target tree (abbrev.):

```text
manuscript.yaml
src/
  Fiction/
    galactic-confederation/
      universe.yaml
      the-calypso-cycle/
        series.yaml
        References/          # from content/series/.../references
        calypso/
          book.yaml
          Chapters/          # from .../books/calypso/chapters
        personage/
        infinite-brutality-infinite-compassion/
      gunny-butler/
        series.yaml
        References/
        the-exchange-student/
          book.yaml
          Chapters/
  NonFiction/
    software-engineering/
      subject.yaml
      intro-to-programming/
        book.yaml
        Chapters/
```

Concrete moves:

1. Add root [`manuscript.yaml`](d:\novolis\novolis-manuscript\src\Novolis.Manuscript.Protocol\PROTOCOL.md) (`protocol: novolis.manuscript`, `version: 1`, defaults authors/language/rights).
2. Create `src/Fiction/galactic-confederation/universe.yaml` (title Galactic Confederation; short description from existing lore).
3. For each series under `content/series/<id>/`:
   - Move to `src/Fiction/galactic-confederation/<id>/`
   - Flatten: `books/<book>/` → `<id>/<book>/` (delete empty `books/` container)
   - Rename `chapters` → `Chapters`, `references` → `References`, `appendices` → `Appendices`, `assets` → `Assets` (use `git mv` twice on Windows if case-only rename)
   - Keep existing `series.yaml`; ensure it only carries title/description/`defaults` (no path-duplicating ids)
4. Move `content/books/intro-to-programming` → `src/NonFiction/software-engineering/intro-to-programming/`; add `subject.yaml`.
5. Delete empty `content/` once nothing remains that tools still need (after Phase 3).
6. Update `.gitattributes` / LFS patterns if they hardcode `content/**` paths.

**Inventory today:** Calypso 149 chapters, IBIC 127, personage 2, gunny 1, intro-to-programming standalone; **0** decimal-named chapter files — good for filename-only order.

## Phase 2 — Metadata normalization (books)

### book.yaml

Per book under NMP:

- Keep: `title`, `subtitle`, `author`/`authors`, `language`, `rights`, word targets, extension bags that are still content
- Add: integer `order:` for series books (calypso=1, personage=2, IBIC=3 or match existing series intent; gunny book=1)
- Remove: `series:`, `chapter_order_from_heading`, `debug_mode` (move debug override to compile CLI / app settings only — already partially supported in [`compile-book.cs`](D:\repos\books\tools\dev\compile-book.cs))

### Chapter metadata

- Convert Calypso-style callouts (`> [!date]`, `[!pov]`, …) → YAML front matter via a one-shot tool under `tools/dev/` (e.g. `migrate-callouts-to-frontmatter.cs`), dry-run then apply
- Leave H1 titles as-is initially; order comes from filename only
- Keep `00-frontmatter.md` / `*-frontmatter.md` under `Chapters/` (prefix still sorts first)

### series.yaml / universe.yaml / subject.yaml

- Titles + optional `defaults` only; no renderer flags

## Phase 3 — Keep books buildable (tools / CI / docs)

Hard-cut breaks every hardcoded `content/` + `chapters/` path. Update in the **same books PR**:

| Area | Files (representative) | Change |
|------|------------------------|--------|
| Full build | [`build.ps1`](D:\repos\books\build.ps1), [`tools/dev/compile-book.cs`](D:\repos\books\tools\dev\compile-book.cs), `compile-reference.cs`, `compile-metrics.cs` | Discover under `src/Fiction/**` and `src/NonFiction/**`; require `Chapters/`; default sort = **numeric filename** (drop metadata-order as default) |
| book-tool | [`tools/dev/book-tool.cs`](D:\repos\books\tools\dev\book-tool.cs) | Resolve NMP book paths; chapter dir `Chapters`; prefer calling into / aligning with `Novolis.Manuscript.IO` later |
| CI | [`tools/ci/run-ci.cs`](D:\repos\books\tools\ci\run-ci.cs), [`.github/workflows/build-books.yml`](D:\repos\books\.github\workflows\build-books.yml) | Path globs `src/**/Chapters`; ASCII scan; staging invariants |
| Local writer | [`tools/apps/books-writer`](D:\repos\books\tools\apps\books-writer) | Workspace detection via `manuscript.yaml`; path joins for series/books |
| Docs / agent rules | `docs/**`, `.cursor/rules/**`, `AGENTS.md`, playbooks | Replace `content/series/...` examples with NMP paths |
| Out/audio | Manifests under `out/` | Paths already series/book keyed; verify compile outputs still match; regenerate if compile path changes |

**Buildability gate for books PR merge:**

1. `pwsh -File D:\repos\books\build.ps1` exits 0  
2. `dotnet run -c Release --file D:\repos\books\tools\ci\run-ci.cs` exits 0 (or CI-equivalent subset used on PRs)  
3. New smoke: `dotnet run` / small script that `Novolis.Manuscript.Protocol.ManuscriptWorkspace.Open(repoRoot).Read()` succeeds and doctor is clean for structural codes (add PackageReference to Protocol in a `tools/ci` probe, or `dotnet` script with GPR)

## Phase 4 — Novolis.Manuscript façade (so apps stay buildable)

Today Studio/Mobile use [`Novolis.Manuscript.ManuscriptWorkspace.TryOpen`](d:\novolis\novolis-manuscript\src\Novolis.Manuscript\ManuscriptWorkspace.cs) looking for `content/series|books` + [`ManuscriptCatalog`](d:\novolis\novolis-manuscript\src\Novolis.Manuscript\ManuscriptCatalog.cs).

After hard-cut that fails. In **novolis-manuscript** (publish to GPR before/with apps bump):

1. Extend `ManuscriptWorkspace.TryOpen` / open pipeline:
   - If `manuscript.yaml` found → read via `Novolis.Manuscript.Protocol`, project snapshot → existing `SeriesInfo` / `BookInfo` / `ChapterInfo` (and standalone NonFiction books)
   - Else keep legacy `content/` detection for any leftover trees
2. Project chapter paths to real `Chapters/*.md` files; sort by filename prefix
3. Doctor: prefer Protocol diagnostics for NMP trees; keep legacy doctor for `content/`
4. Unit tests: fixture with minimal NMP tree + open/catalog assertions
5. Publish `Novolis.Manuscript` (+ Protocol already published); bump apps float restore

Optional: thin helper on `Novolis.Manuscript.IO` for path resolution used by book-tool later — not required for first green.

## Phase 5 — Apps / dogfood (coordinated)

In **novolis-apps** (and dogfood smoke if needed), after façade is on GPR (or ProjectRef locally):

1. [`BooksMobileOptions.DefaultContentPrefix`](d:\novolis\novolis-apps\src\BooksMobile\BooksMobile\BooksMobileOptions.cs): `content/` → `src/` (still sparse; skip Assets as today)
2. Studio open messaging: expect `manuscript.yaml` / NMP, not only `content/`
3. Ensure PackageReferences already point at `Novolis.Manuscript*` (done); bump if pinned
4. ProjectRef build:  
   `dotnet build d:\novolis\novolis-apps\src\BooksWriterStudio\BooksWriterStudio.csproj -p:NovolisUseProjectReferences=true`  
   `dotnet build d:\novolis\novolis-apps\src\BooksMobile\BooksMobile\BooksMobile.csproj -p:NovolisUseProjectReferences=true`
5. Manual smoke: open Calypso chapter list after pointing at migrated books root

## Phase 6 — Verification matrix

| Check | Pass criteria |
|-------|----------------|
| Git base | Branch from `origin/main` tip; no accidental WIP |
| Protocol open | `Open(booksRoot).Read()` sees both series + NonFiction book |
| Filename order | Calypso chapter list matches numeric prefix order |
| books build | `build.ps1` OK |
| books CI | `run-ci` / workflow OK |
| Apps | Studio + Mobile build; open NMP root |
| nuget-only | No local feeds introduced |
| No leftover `content/` | Or documented temporary exception only if a tool still needs it |

## Explicit non-goals (this plan)

- Mass renumber chapters to gapped 10/20/30  
- Export.Html/Docx/Epub  
- Deep Studio/Mobile UI redesign  
- Migrating hosts into `novolis-manuscript`  
- Deleting `book-tool` (update paths; optional later wrap of `Manuscript.IO`)

## PR / merge sequence

1. **books** PR: tree + metadata + tools/docs/CI (must stay green alone via updated tools)  
2. **novolis-manuscript** PR: façade opens NMP → catalog (publish GPR)  
3. **novolis-apps** PR: `src/` sparse prefix + open copy; restore new Manuscript package  

Do not merge books hard-cut to `main` until (2) is published **or** apps are updated in lockstep with ProjectRef — otherwise Mobile/Studio against published packages cannot open the repo.

