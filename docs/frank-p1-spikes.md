# P1 spike notes (Frank.\*)

Spike date: 2026-05-17. Method: shallow clone, project/package enumeration, release tags, Frank dependency grep, test counts.

## Frank.CronJobs — conditional extract

- **Packages:** `Frank.CronJobs`, `Frank.CronJobs.Cron` (standalone cron parser)
- **Deps:** `Frank.Reflection`, `Frank.Testing.Logging`
- **Tests:** 3 test files, 0 `[Fact]` in quick scan — **high migration risk**
- **Differentiation:** DI-first `AddCronJob<T>(expression)` + `IScheduleMaintainer` for runtime schedule changes
- **Verdict:** Extract only if scheduling is a Novolis product goal; prefer **rebuild** with tests on `net10.0`. Name: `Novolis.Scheduling` (new repo or hosting extension — **governance decision needed**)
- **Re-score:** 11 → hold at P1 until scheduling domain approved

## Frank.Reflection — partial extract

- **Packages (6):** `Frank.Reflection`, `Dump`, `Mermaid`, `Roslyn`, `RoslynQuoter`, `Frank.BuildTasks.MarkdownDocGenerator`
- **Deps:** `Frank.Markdown`, `Frank.Testing.*`
- **Tests:** 18 facts
- **Verdict:** Wave 5 — migrate **Reflection + Dump + Mermaid** to `novolis-codegen`; defer Roslyn quoter/build tasks unless doc-gen is prioritized
- **Re-score:** 12 — stays P1 partial

## Frank.Analyzers — partial extract

- **Packages (8):** analyzers + source generators including **CppInteropts** (ClangSharp — heavy)
- **Tests:** 9 facts
- **Verdict:** `novolis-analyzers` gets **AutoMapper** + **CodeLength**; `novolis-codegen` gets **Localization** + **AdditionalFiles** if needed; **skip CppInteropts** unless native interop lane exists
- **Re-score:** 11 — P1 partial

## Frank.Templates — merge

- **Packages:** 14 template packs (Microservice, MonoGame, NoXaml, NugetSolution, SemanticKernel, Testcontainers, …)
- **Deps:** `Frank.Testing` in template test projects
- **Verdict:** Merge into `novolis-templates` policy; **do not duplicate** `novolis-template-dotnet` — templates install via `dotnet new` with Novolis branding
- **Re-score:** 11 — P1 merge, not raw extract

## Frank.Markdown — wave 10

- **Packages:** 1 (`Frank.Markdown`)
- **Tests:** 38 facts (strongest test story in P1 set)
- **Verdict:** **`novolis-markup`** with `Novolis.Markup.Markdown`; archive personal repo after preview
- **Re-score:** 10 — wave 10 extract

## Frank.Mermaid — wave 10

- **Packages:** 1 (`Frank.Mermaid`)
- **Tests:** flowchart, pie, timeline, git graph, xy chart
- **Verdict:** **`novolis-markup`** with `Novolis.Markup.Mermaid`; distinct from `Novolis.CodeGen.Reflection.Mermaid`
- **Re-score:** 9 — wave 10 extract

## Frank.Networking — defer

- **Packages:** `Frank.Networking`, `Frank.Networking.Irc`
- **Releases:** none
- **Tests:** 2 facts
- **Verdict:** Ambitious README (HTTP, FTP, …) vs thin delivery — audit after Bedrock+Http land; maybe extract IRC only
- **Re-score:** 9 — P1 → borderline P2

## Frank.Collections — defer

- **Packages:** 1
- **Tests:** 27 facts
- **Verdict:** `Array2D` + `ObservableList` — niche; map to `novolis-math` only if math repo needs collections
- **Re-score:** 9 — P1 defer

## Frank.ML — skip

- **Visibility:** private
- **Description:** learning ML project
- **Verdict:** **P3** — do not migrate unless deliberately opened as `novolis-machinelearning`
- **Re-score:** 6

## P1 outcomes summary

| Repo | Post-spike tier | Next action |
|------|-----------------|-------------|
| CronJobs | P1 | Governance: scheduling domain yes/no |
| Reflection | P1 partial | Wave 5 brief |
| Analyzers | P1 partial | Wave 5 brief |
| Templates | P1 merge | Template policy doc + wave 6 |
| Markdown | Wave 10 | `novolis-markup` |
| Mermaid | Wave 10 | `novolis-markup` |
| Networking | P2 defer | Revisit after transports wave 2 |
| Collections | P2 defer | Optional math adjunct |
| Frank.ML | P3 | None |
