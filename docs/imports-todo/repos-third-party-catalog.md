# `D:\repos` — catalog (third-party + mine)

Scanned 2026-05-25. See [third-party-inspiration-policy.md](third-party-inspiration-policy.md).

## Mine (Frank) — pieces, not whole repos

| Directory | Purpose | Novolis | Doc |
|-----------|---------|---------|-----|
| **FleetCommander** | WEGO tactics sim, replay, SignalR | Patterns | [fleetcommander-patterns-for-platform.md](fleetcommander-patterns-for-platform.md) |
| **agent-contracts-standard** | ACS v0.1 | Governance | [agent-contracts-novolis-governance.md](agent-contracts-novolis-governance.md) |
| **Workflows** | GitHub Actions | CI reference | [workflows-and-release-ci.md](workflows-and-release-ci.md) |
| **ReleaseOrchistrator** | Release gates | CI reference | [workflows-and-release-ci.md](workflows-and-release-ci.md) |
| **Frank.Libraries** | Legacy shared libs | Audit vs storage/ML | [frank-ml-remainder.md](frank-ml-remainder.md) + frankrepos |
| **Frank.Apps.Ocr**, **Frank.Blazor.*** | Blazor utilities | Apps / markup | [github-frank-mine-extra.md](github-frank-mine-extra.md) |
| **RayTracer** | CPU ray tracer (Frank) | **Skip** lib; inspiration for tests | See below |
| **RoboSharp** | Compiler teaching (Avalonia) | Inspiration for codegen pedagogy | See below |
| **treffly**, **rebellion2** | Products (Aspire / Unity) | Skip platform | |
| **books**, **frankhaugen.github.io** | Content | Skip | |
| **Generated** | UBL generated output | Skip — artifact | |
| **packages** | Empty | Delete locally | |

### RayTracer (mine) — inspiration only

- **Path:** `D:\repos\RayTracer`
- **Borrow:** ray–primitive tests, camera ray generation sanity checks — compare with `Novolis.Math.Geometry` + CPU path tracer.
- **Skip:** `Frank.CrossPlatformWindow` host; full tracer → `novolis-rendering` owns lane.

### RoboSharp (mine) — inspiration only

- **Borrow:** staged compiler pipeline UX (lexer → IL → run), diagnostic presentation — for **docs/tutorials**, not `Novolis.CodeGen.Bindings` implementation.

---

## Third-party — skip duplicate

| Directory | Upstream | Why skip | Inspiration (if any) |
|-----------|----------|----------|------------------------|
| **bullet3** | bulletphysics | Novolis physics is .NET force-first | Broadphase concepts for native future |
| **ravendb** | ravendb | Not in platform storage plan | Embedded DB patterns |
| **raylib** | raysan5 | `novolis-raylib` + native packages | API manifest reference |
| **Raylib-CSharp** | MrScautHD / fork | Superseded by novolis-raylib codegen | `LibraryImport` layout ideas |
| **MonoGame** | MonoGame | Not Novolis render lane | Packaging/content pipeline |
| **roslyn-sdk** | dotnet | Use NuGet analyzers SDK | Analyzer test harness layout |
| **wpf** | dotnet/wpf | Off-brand desktop | — |
| **UblSharp** | UblSharp | Use NuGet if needed | XSD model patterns |
| **XmlSchemaClassGenerator** | mganss / fork | Use NuGet or codegen spike | Schema→C# options |
| **markdig.wpf** | archived | Dead | — |
| **labelImg** | tzutalin | Deprecated | — |
| **NeoLoader** | — | Unrelated C++ | — |
| **mdk2** | malforge | Space Engineers specific | — |
| **xod.core** | fork | Treffly-specific storage | — |
| **SharpCraft** | Acueres | MonoGame game | Voxel mesh ideas only |
| **ExperimentWithCppSharp** | local spike | Superseded by binding codegen | Archive |
| **Github-Explorer** | mine utility | Dev tool | Skip platform |

---

## Third-party — consume via NuGet only (never vendor)

| Directory | Use when |
|-----------|----------|
| **roslyn-sdk** | Authoring analyzers/source generators — reference samples on disk |
| **UblSharp** / **XmlSchemaClassGenerator** | Finance/XML lane — add PackageReference in product repo |

---

## `D:\github` vs `D:\frankrepos`

- Prefer **`D:\frankrepos`** as migration source path (same remotes, fewer extras).
- Use **`D:\github`** for repos **not** cloned to frankrepos — see [github-frank-mine-extra.md](github-frank-mine-extra.md).
