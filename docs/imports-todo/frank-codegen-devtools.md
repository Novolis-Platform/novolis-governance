# Import: Frank codegen / devtools repos

**Sources under `D:\frankrepos`:**

| Repo | Packable | Notes |
|------|----------|-------|
| `Frank.Blazor.JsInteropGenerator` | `Frank.Blazor.JsInteropGenerator` | Roslyn + Esprima JS interop codegen |
| `Frank.SolutionManager` | `Frank.SolutionManager` (+ tool exe) | `.sln` / project manipulation |
| `Frank.GitKit` | `Frank.GitKit` | Git + GitHub + Azure DevOps helpers |
| `Frank.XsdCodeGeneration` | `Frank.XsdCodeGeneration` | Legacy Roslyn Syntax spike — historical reference only |

## What (per repo)

### Blazor JsInteropGenerator

Generates C# interop from JavaScript — same **lane** as `Novolis.CodeGen.Bindings` (Roslyn emit, parity tests).

### SolutionManager

Automates solution structure — useful for **template-dotnet**, codegen pipeline, and governance scripts.

### GitKit

Repository operations for CI and devtools; depends on **Reflection** subset.

### XsdCodeGeneration

Author-marked dead-end spike. **Do not** port as-is. The **schema-agnostic** XSD → Roslyn emitter lives in **`novolis-codegen`** (`Novolis.CodeGen.Xml` + `Novolis.CodeGen.Xsd`). UBL/Peppol **product** packages remain in **`novolis-xsd`**.

## Why

- Wave 5 ported Reflection **subset** but not these specialized generators.
- Binding codegen proves pipeline; SchemaGraph → SyntaxFactory is the second consumer of Roslyn emit culture.
- UBL is the acceptance suite for the generic emitter, not the home of the IR.

## How

### Target

**`novolis-codegen`** — facets:

| Novolis package | Source / role |
|-----------------|--------|
| `Novolis.CodeGen.JsInterop` | Blazor generator (rename; Blazor optional in name) |
| `Novolis.CodeGen.SolutionManager` | SolutionManager |
| `Novolis.CodeGen.Git` or `novolis-devtools` | GitKit |
| `Novolis.CodeGen.Xml` | XmlSchemaSet load + SchemaGraph IR |
| `Novolis.CodeGen.Xsd` | IR → SyntaxFactory profiles (Wire / Lean) |

**`novolis-xsd`** — product:

| Novolis package | Role |
|-----------------|------|
| `Novolis.Xsd.Generator` / `.Tool` | Host + UBL normalize; consumes CodeGen.Xml/Xsd |
| `Novolis.Xsd.Ubl` / `.Ubl.Validation` / `.Ubl.Lean` | Pre-generated Wire + Lean |
| `Novolis.Xsd.Peppol` | SBDH envelope + Peppol helpers |

### Port steps

1. **SolutionManager** first — dogfood in `novolis-governance/scripts` or template generator.
2. **JsInterop** — port with T1-style comparer if golden files exist.
3. **GitKit** — after Reflection on GPR; narrow public API.
4. **Xml/Xsd** — implement in `novolis-codegen`; dogfood via `novolis-xsd` UBL gates.

## Acceptance

- `Novolis.CodeGen.Xml` + `.Xsd` published to GitHub Packages and used by `novolis-xsd`.
- `novolis-xsd` packages restore from nuget.org + GitHub Packages only.
- Coverage ≥ 85% line on Xml/Xsd assemblies; nuget-only green.
