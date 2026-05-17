# Frank.* → Novolis naming and structure

**Status:** Signed off 2026-05-17 (maintainer execution).  
**Blocks:** extraction briefs and `migrate-frank-slice.ps1` until this doc is updated for new packages.

Authoritative mapping for extract/rebuild migrations. Package IDs, folder paths, namespaces, and public API names must match this document.

Related: [naming.md](naming.md), [frank-inventory.md](frank-inventory.md), [frank-migration-runbook.md](frank-migration-runbook.md).

## Sign-off

| Role | Date | Notes |
|------|------|-------|
| Migration execution | 2026-05-17 | Defaults below applied for P0 pilot + waves 0–2; storage wave 3 subset |

## Repo ↔ domain (reserved — do not rename)

| GitHub repo | Domain | Frank sources (P0) | Layout |
|-------------|--------|-------------------|--------|
| `novolis-messaging` | Messaging | Channels.DI, PulseFlow | Multi-package |
| `novolis-testing` | Testing | Frank.Testing (5 publishable facets) | Multi-package |
| `novolis-transports` | Transports | BedrockSlim, Http, WireFish | Multi-package |
| `novolis-storage` | Storage | DataStorage subset | Multi-package |
| `novolis-security` | Security | Cryptography, HIBP | Multi-package |
| `novolis-codegen` | CodeGen | Reflection subset | Multi-package |
| `novolis-analyzers` | Analyzers | AutoMapper, CodeLength | Multi-package |
| `novolis-templates` | Templates | Frank.Templates (7 packs) | Single template NuGet pack |
| `novolis-math` | Math | GameEngine Primitives subset | Multi-package |
| `novolis-machinelearning` | MachineLearning | Frank.ML neural foundation | Multi-package |
| `novolis-markup` | Markup | Frank.Markdown, Frank.Mermaid | Multi-package |

## Structural rule (Frank → Novolis)

Frank uses **project folders at repo root**. Novolis uses:

```text
novolis-<domain>/
  src/Novolis.<Domain>.<Facet>/
  tests/Novolis.<Domain>.<Facet>.Tests/
  samples/                    (when Frank had Samples/)
  Novolis.<Domain>.slnx
  .novolis/packages.json
  Directory.Build.props
  Directory.Packages.props
  global.json
```

On extract: **move** projects into `src/` / `tests/`; do not preserve Frank flat root layout.

## NuGet package naming (P0 — resolved)

| Frank package / project | Novolis `PackageId` | Repo folder |
|-------------------------|---------------------|-------------|
| `Frank.Channels.DependencyInjection` | `Novolis.Messaging.Channels` | `src/Novolis.Messaging.Channels/` |
| `Frank.PulseFlow` | `Novolis.Messaging` | `src/Novolis.Messaging/` |
| `Frank.BedrockSlim.Server` | `Novolis.Transports.Tcp.Server` | `src/Novolis.Transports.Tcp.Server/` |
| `Frank.BedrockSlim.Client` | `Novolis.Transports.Tcp.Client` | `src/Novolis.Transports.Tcp.Client/` |
| `Frank.BedrockSlim.Cryptography` | *(deferred)* | — |
| `Frank.Http` | `Novolis.Transports.Http` | `src/Novolis.Transports.Http/` |
| `Frank.Http.Abstractions` | `Novolis.Transports.Http.Abstractions` | `src/Novolis.Transports.Http.Abstractions/` |
| `Frank.Http.Authentication` | `Novolis.Transports.Http.Authentication` | `src/Novolis.Transports.Http.Authentication/` |
| `Frank.Http.Extensions` | `Novolis.Transports.Http.Extensions` | `src/Novolis.Transports.Http.Extensions/` |
| `Frank.Testing.TestOutputExtensions` | **`Novolis.Testing.TUnit`** | `src/Novolis.Testing.TUnit/` |
| `Frank.Testing.Logging` | `Novolis.Testing.Logging` | `src/Novolis.Testing.Logging/` |
| `Frank.Testing.TestBases` | `Novolis.Testing.TestBases` | `src/Novolis.Testing.TestBases/` |
| `Frank.Testing.Testcontainers` | `Novolis.Testing.Testcontainers` | `src/Novolis.Testing.Testcontainers/` |
| `Frank.Testing.TestServer` | `Novolis.Testing.TestServer` | `src/Novolis.Testing.TestServer/` |
| `Frank.DataStorage.Abstractions` | `Novolis.Storage.Abstractions` | `src/Novolis.Storage.Abstractions/` |
| `Frank.DataStorage.Core` | *(do not port)* | — |
| `Frank.DataStorage` (meta) | *(do not port)* | — |
| `Frank.DataStorage.Json` | `Novolis.Storage.Json` | `src/Novolis.Storage.Json/` |
| `Frank.DataStorage.Sqlite` | `Novolis.Storage.Sqlite` | `src/Novolis.Storage.Sqlite/` |
| `Frank.Security.Cryptography` (generation) | `Novolis.Security.Secrets` | `src/Novolis.Security.Secrets/` |
| `Frank.Security.Cryptography` (hashing) | `Novolis.Security.PasswordHashing` | `src/Novolis.Security.PasswordHashing/` |
| `Frank.Security.Cryptography` (string AES) | `Novolis.Security.Encryption` | `src/Novolis.Security.Encryption/` |
| `Frank.Security.HaveIBeenPwned` | `Novolis.Security.HaveIBeenPwned` | `src/Novolis.Security.HaveIBeenPwned/` |
| `Frank.Security.Resources` | `Novolis.Security.WordLists` *(internal)* | `src/Novolis.Security.WordLists/` |
| `Frank.Reflection` | `Novolis.CodeGen.Reflection` | `src/Novolis.CodeGen.Reflection/` |
| `Frank.Reflection.Dump` | `Novolis.CodeGen.Reflection.Dump` | `src/Novolis.CodeGen.Reflection.Dump/` |
| `Frank.Reflection.Mermaid` | `Novolis.CodeGen.Reflection.ClassDiagram` | `src/Novolis.CodeGen.Reflection.ClassDiagram/` |
| `Frank.Analyzers.AutoMapper` | `Novolis.Analyzers.AutoMapper` | `src/Novolis.Analyzers.AutoMapper/` |
| `Frank.Analyzers.CodeLength` | `Novolis.Analyzers.CodeLength` | `src/Novolis.Analyzers.CodeLength/` |
| `Frank.Templates` | `Novolis.Templates` | `src/Novolis.Templates/` (`PackageType=Template`) |
| `Frank.GameEngine.Primitives/SubPrimitives` | `Novolis.Math.Arrays` | `src/Novolis.Math.Arrays/` |
| `Frank.GameEngine.Primitives` (geometry subset) | `Novolis.Math.Geometry` | `src/Novolis.Math.Geometry/` |
| `Frank.ML.Foundation.Core` | `Novolis.MachineLearning.Core` | `src/Novolis.MachineLearning.Core/` |
| `Frank.ML.Foundation.Neural.Abstractions` | `Novolis.MachineLearning.Neural.Abstractions` | `src/Novolis.MachineLearning.Neural.Abstractions/` |
| `Frank.ML.Foundation.Neural.Implementation` | `Novolis.MachineLearning.Neural` | `src/Novolis.MachineLearning.Neural/` |
| `Frank.WireFish` | `Novolis.Transports.WireFish` | `src/Novolis.Transports.WireFish/` |
| `Frank.Markdown` | `Novolis.Markup.Markdown` | `src/Novolis.Markup.Markdown/` |
| `Frank.Mermaid` | `Novolis.Markup.Mermaid` | `src/Novolis.Markup.Mermaid/` |

**Facet decisions:**

- Messaging DI: facet name **`Channels`**, not `DependencyInjection`.
- Testing output helpers: **`Novolis.Testing.TUnit`** — extensions on TUnit `TestContext` ([naming.md](naming.md): TUnit only, no xUnit).
- Bedrock: drop “BedrockSlim”; use **`Tcp`** segment.
- Storage: explicit packages only; no meta `Novolis.Storage` umbrella in wave 3.

## Namespace and assembly rules

| Rule | Convention |
|------|------------|
| Root namespace | Matches `PackageId` (e.g. `Novolis.Messaging.Channels`) |
| Internal types | `Novolis.<Domain>.Internal` (e.g. `Novolis.Messaging.Internal`) |
| Test namespaces | **Per-facet:** `Novolis.Messaging.Channels.Tests`, `Novolis.Messaging.Tests`, etc. |
| Assembly name | Default = `PackageId` |
| Legacy `Frank.*` | Must not appear in production Novolis code |

## Public API vocabulary (PulseFlow — keep Frank terms)

| Frank | Novolis | Decision |
|-------|---------|----------|
| `IPulse` | `IPulse` | Keep (product term) |
| `IConduit` | `IConduit` | Keep |
| `IFlow` | `IFlow` | Keep |
| `Nexus` / `PulseNexus` | Internal only | `Novolis.Messaging.Internal` |
| `AddPulseFlow()` | `AddPulseFlow()` | Keep in `Novolis.Messaging` |
| Product docs | “PulseFlow” | OK in README; package ID is `Novolis.Messaging` |

## Public API vocabulary (Tcp / Bedrock)

| Frank | Novolis |
|-------|---------|
| `IConnectionProcessor` | Keep |
| `UseTcpConnectionHandler<T>` etc. | Align with `Novolis.Transports.Tcp.Server` namespace |

## Frank.* dependency removal (P0)

| Former dep | Replacement |
|------------|-------------|
| `Frank.Channels.DependencyInjection` | `Novolis.Messaging.Channels` project reference |
| `Frank.Reflection` / `Frank.Reflection.Dump` | `Novolis.CodeGen.Reflection` / `Novolis.CodeGen.Reflection.Dump` (TUnit references Dump package) |
| `Frank.Testing.*` | `Novolis.Testing.*` package references |
| `Frank.DataStorage.Abstractions` → Reflection package | Remove unused package reference |

## `.novolis/packages.json` templates

### `novolis-messaging`

```json
{
  "packages": {
    "Novolis.Messaging.Channels": {
      "project": "src/Novolis.Messaging.Channels/Novolis.Messaging.Channels.csproj",
      "paths": [
        "src/Novolis.Messaging.Channels/**",
        "tests/Novolis.Messaging.Channels.Tests/**",
        "Directory.Build.props",
        "Directory.Packages.props",
        "global.json",
        "Novolis.Messaging.slnx"
      ]
    },
    "Novolis.Messaging": {
      "project": "src/Novolis.Messaging/Novolis.Messaging.csproj",
      "paths": [
        "src/Novolis.Messaging/**",
        "tests/Novolis.Messaging.Tests/**",
        "Directory.Build.props",
        "Directory.Packages.props",
        "global.json",
        "Novolis.Messaging.slnx"
      ]
    }
  }
}
```

### `novolis-testing`

Entries: `Novolis.Testing.TUnit`, `.Logging`, `.TestBases`, `.Testcontainers`, `.TestServer` — each with matching `src/` + `tests/` paths and shared build files.

### `novolis-transports`

Entries: `Novolis.Transports.Tcp.Server`, `.Tcp.Client`, `.Http`, `.Http.Abstractions`, `.Http.Authentication`, `.Http.Extensions`, `.WireFish`.

### `novolis-storage` (wave 3)

Entries: `Novolis.Storage.Abstractions`, `.Json`, `.Sqlite`.

### `novolis-security` (wave 4)

Entries: `Novolis.Security.Secrets`, `.PasswordHashing`, `.Encryption`, `.HaveIBeenPwned`.

### `novolis-codegen` (wave 5)

Entries: `Novolis.CodeGen.Reflection`, `.Reflection.Dump`, `.Reflection.ClassDiagram`.

### `novolis-analyzers` (wave 5)

Entries: `Novolis.Analyzers.AutoMapper`, `.CodeLength`.

### `novolis-templates` (wave 6)

Entry: `Novolis.Templates` — paths include `src/Novolis.Templates/content/**`, `Novolis.Templates.slnx`.

### `novolis-markup` (wave 10)

Entries: `Novolis.Markup.Markdown`, `Novolis.Markup.Mermaid`.

## Solution and dependency graph

| Repo | Solution | Package references |
|------|----------|-------------------|
| `novolis-messaging` | `Novolis.Messaging.slnx` | `Novolis.Messaging` → `Novolis.Messaging.Channels` |
| `novolis-testing` | `Novolis.Testing.slnx` | Facets independent; tests may reference multiple facets |
| `novolis-transports` | `Novolis.Transports.slnx` | Http facets → Abstractions; Tcp Server/Client independent |
| `novolis-storage` | `Novolis.Storage.slnx` | Json/Sqlite → Abstractions |
| `novolis-security` | `Novolis.Security.slnx` | Independent facets |
| `novolis-codegen` | `Novolis.CodeGen.slnx` | Dump/Mermaid → Reflection |
| `novolis-analyzers` | `Novolis.Analyzers.slnx` | Independent analyzer packages |
| `novolis-testing` | `Novolis.Testing.slnx` | `Novolis.Testing.TUnit` → `Novolis.CodeGen.Reflection.Dump` |
| `novolis-math` | `Novolis.Math.slnx` | Geometry independent; Arrays has no deps |
| `novolis-machinelearning` | `Novolis.MachineLearning.slnx` | Neural → Abstractions; Core independent |
| `novolis-markup` | `Novolis.Markup.slnx` | Markdown and Mermaid independent |

## Namespace replacement table (automation)

Use [scripts/migrate-frank-slice.ps1](../scripts/migrate-frank-slice.ps1) with these replacements (longest match first):

| From | To |
|------|-----|
| `Frank.Templates.TestContainerTemplate` | `Novolis.Templates.TestContainerTemplate` |
| `Frank.Templates.NoXaml.Solution` | `Novolis.Templates.NoXaml.Solution` |
| `Frank.Templates.NoXaml.App` | `Novolis.Templates.NoXaml.App` |
| `Frank.Templates.SemanticKernel` | `Novolis.Templates.SemanticKernel` |
| `Frank.Templates.GitHubSolution` | `Novolis.Templates.GitHubSolution` |
| `Frank.Templates.Microservice` | `Novolis.Templates.Microservice` |
| `Frank.Templates.MonoGame` | `Novolis.Templates.MonoGame` |
| `Frank.Templates` | `Novolis.Templates` |
| `Frank.Reflection.Mermaid` | `Novolis.CodeGen.Reflection.ClassDiagram` |
| `Frank.Reflection.Dump` | `Novolis.CodeGen.Reflection.Dump` |
| `Frank.Reflection` | `Novolis.CodeGen.Reflection` |
| `Frank.Analyzers.AutoMapper` | `Novolis.Analyzers.AutoMapper` |
| `Frank.Analyzers.CodeLength` | `Novolis.Analyzers.CodeLength` |
| `Frank.Channels.DependencyInjection` | `Novolis.Messaging.Channels` |
| `Frank.PulseFlow.Internal` | `Novolis.Messaging.Internal` |
| `Frank.PulseFlow` | `Novolis.Messaging` |
| `Frank.Testing.TestOutputExtensions` | `Novolis.Testing.TUnit` |
| `Frank.Testing.TestBases` | `Novolis.Testing.TestBases` |
| `Frank.Testing.Testcontainers` | `Novolis.Testing.Testcontainers` |
| `Frank.Testing.TestServer` | `Novolis.Testing.TestServer` |
| `Frank.Testing.Logging` | `Novolis.Testing.Logging` |
| `Frank.Testing` | `Novolis.Testing` |
| `Frank.BedrockSlim.Server` | `Novolis.Transports.Tcp.Server` |
| `Frank.BedrockSlim.Client` | `Novolis.Transports.Tcp.Client` |
| `Frank.BedrockSlim` | `Novolis.Transports.Tcp` |
| `Frank.Http.Abstractions` | `Novolis.Transports.Http.Abstractions` |
| `Frank.Http.Authentication` | `Novolis.Transports.Http.Authentication` |
| `Frank.Http.Extensions` | `Novolis.Transports.Http.Extensions` |
| `Frank.Http` | `Novolis.Transports.Http` |
| `Frank.DataStorage.Abstractions` | `Novolis.Storage.Abstractions` |
| `Frank.DataStorage.Json` | `Novolis.Storage.Json` |
| `Frank.DataStorage.Sqlite` | `Novolis.Storage.Sqlite` |
| `Frank.DataStorage` | `Novolis.Storage` |
| `Frank.Security.HaveIBeenPwned` | `Novolis.Security.HaveIBeenPwned` |
| `Frank.Security.Cryptography` | `Novolis.Security.Secrets` / `.PasswordHashing` / `.Encryption` |
| `Frank.Security` | `Novolis.Security` |
| `Frank.ML.Foundation.Neural.Implementation` | `Novolis.MachineLearning.Neural` |
| `Frank.ML.Foundation.Neural.Abstractions` | `Novolis.MachineLearning.Neural.Abstractions` |
| `Frank.ML.Foundation.Core` | `Novolis.MachineLearning.Core` |
| `Frank.GameEngine.Primitives.SubPrimitives` | `Novolis.Math.Arrays` |
| `Frank.GameEngine.Primitives` | `Novolis.Math.Geometry` |
| `Frank.Markdown` | `Novolis.Markup.Markdown` |
| `Frank.Mermaid` | `Novolis.Markup.Mermaid` |

## Preview versioning

| Package | First preview |
|---------|----------------|
| `Novolis.Messaging.Channels` | `0.1.0-preview.1` |
| `Novolis.Messaging` | `0.1.0-preview.1` |
| Other P0 facets | `0.1.0-preview.1` unless noted in wave brief |

## Migration publish gate (not org bootstrap)

First **migration** trusted-publish validation: **`Novolis-Platform/novolis-messaging`**, workflow `release.yml`, environment `nuget.org`, package **`Novolis.Messaging.Channels`** `0.1.0-preview.1`.

`novolis-smoketest` remains org bootstrap / template CI only.
