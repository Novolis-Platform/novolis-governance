# Import: Frank codegen / devtools repos

**Sources under `D:\frankrepos`:**

| Repo | Packable | Notes |
|------|----------|-------|
| `Frank.Blazor.JsInteropGenerator` | `Frank.Blazor.JsInteropGenerator` | Roslyn + Esprima JS interop codegen |
| `Frank.SolutionManager` | `Frank.SolutionManager` (+ tool exe) | `.sln` / project manipulation |
| `Frank.GitKit` | `Frank.GitKit` | Git + GitHub + Azure DevOps helpers |
| `Frank.XsdCodeGeneration` | `Frank.XsdCodeGeneration` | XSD → C# (author marked dead-end) |

## What (per repo)

### Blazor JsInteropGenerator

Generates C# interop from JavaScript — same **lane** as `Novolis.CodeGen.Bindings` (Roslyn emit, parity tests).

### SolutionManager

Automates solution structure — useful for **template-dotnet**, codegen pipeline, and governance scripts.

### GitKit

Repository operations for CI and devtools; depends on **Reflection** subset.

### XsdCodeGeneration

Legacy XSD tooling — spike only if finance/UBL lane revives.

## Why

- Wave 5 ported Reflection **subset** but not these specialized generators.
- Binding codegen ([internal-novolis-audit/codegen-bindings-backlog.md](internal-novolis-audit/codegen-bindings-backlog.md)) proves pipeline; second consumer validates generality.
- SolutionManager reduces manual slnx maintenance across 22+ repos.

## How

### Target

**`novolis-codegen`** (preferred) — new facets:

| Novolis package | Source |
|-----------------|--------|
| `Novolis.CodeGen.JsInterop` | Blazor generator (rename; Blazor optional in name) |
| `Novolis.CodeGen.SolutionManager` | SolutionManager |
| `Novolis.CodeGen.Git` or `novolis-devtools` | GitKit |

Keep **XSD** as spike doc only unless requirement appears.

### Port steps

1. **SolutionManager** first — dogfood in `novolis-governance/scripts` or template generator.
2. **JsInterop** — port with T1-style comparer if golden files exist.
3. **GitKit** — after Reflection on GPR; narrow public API.
4. Skip XSD unless linked from [frank-repos-explicit-skip.md](frank-repos-explicit-skip.md) finance decision.

## Acceptance

- At least one tool published and used by a Novolis repo workflow (not only ported).
