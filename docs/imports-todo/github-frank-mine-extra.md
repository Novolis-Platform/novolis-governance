# `D:\github` — Frank repos not in `D:\frankrepos`

**Context:** `D:\github` has ~123 clones; ~82 names exist only on GitHub path vs `D:\frankrepos`. Most Frank.* duplicates are the same migration as [frankrepos-catalog.md](frankrepos-catalog.md). This doc covers **extra mine repos** worth a dedicated import note.

## Duplicate rule

If the repo exists under `D:\frankrepos`, use the `frankrepos` imports-todo doc — **do not** re-document here.

## Extra mine repos (candidates)

| Repo (`D:\github`) | What | Novolis target | Verdict |
|--------------------|------|----------------|---------|
| **Frank.DependenciesExplorer** | NuGet dependency graph explorer (tool + library) | `novolis-governance/scripts` or `novolis-install` | **P2** — devtool; see below |
| **Frank.AzureDevOps** | Azure DevOps helpers | `novolis-codegen` / devtools | **P3** — spike with GitKit |
| **Frank.Devops.WorkItemCreator** | ADO work items | Devtools / skip | **P3** |
| **Frank.Brreg** | Norwegian business registry API | Product-only | **Skip** platform |
| **Frank.Blazor.Mermaid** | Blazor Mermaid tag helper | `novolis-markup` or app | **P2** if Blazor lane opens |
| **Frank.Apps.Ocr** | Blazor OCR wrapper | Dogfood / skip | **Skip** |
| **Frank.CSharp1BR**, **Frank.EnterpriseFizzBuzz**, **Frank.FizzBuzzJazzFuzz** | Katas | Skip | |
| **Frank.FileToByteArray** | Tiny utility | Inline in consumer or skip | **Skip** |
| **Frank.HaveIBeenPwned** | May overlap `novolis-security` | Audit vs `Novolis.Security.HaveIBeenPwned` | **Skip duplicate** |
| **FleetCommander** | See dedicated doc | Patterns only | [fleetcommander-patterns-for-platform.md](fleetcommander-patterns-for-platform.md) |
| **dotnet-chat-app**, **DotnetBlackJack**, **2d-topdown-experiment** | Sample apps | `novolis-dogfooding` inspiration | **Apps only** |
| **DotnetRepoTemplate** | Template | Align with `novolis-template-dotnet` | **Merge ideas** |
| **frank-docfx-publish** | DocFX publish | `novolis-governance` docs CI | **P3** |
| **class-from-dataset**, **find-a-friend**, **echoes**, **Alone**, **AssetPlusPlus** | Products/experiments | Skip platform | |

## Frank.DependenciesExplorer — detail

### What

Library + tool using `NuGet.ProjectModel` to print transitive dependency trees.

### Why

- Useful for **GPR migration** and `verify-nuget-only` audits across 22 repos.
- Not a game/stack feature — belongs in governance/devtools.

### How

1. Port to `novolis-governance/scripts` as `Explore-PackageGraph.ps1` **or** thin `Novolis.Install.Dependencies` tool.
2. No runtime dependency from platform libs.
3. Prefer referencing **NuGet package** `Frank.DependenciesExplorer` from maintainer docs until Novolis-owned tool exists.

## Acceptance

- No duplicate migration brief for repos already listed in `frankrepos-catalog.md`.
- DependenciesExplorer called out in [maintainer-guide.md](../maintainer-guide.md) or governance scripts README.
