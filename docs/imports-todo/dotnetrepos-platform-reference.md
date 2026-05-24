# `D:\dotnetrepos` — platform reference (third-party)

**Policy:** [third-party-inspiration-policy.md](third-party-inspiration-policy.md) — **no copies** into `novolis-*`.

## Catalog

| Directory | Owner | Novolis relationship | Verdict |
|-----------|-------|------------------------|---------|
| **BedrockFramework** | David Fowler | Frank.BedrockSlim / `Novolis.Transports.Tcp` already shipped | [bedrockframework-transports-inspiration.md](bedrockframework-transports-inspiration.md) |
| **aspnetcore** | Microsoft | Platform framework | **Reference only** — Kestrel, Connections.Abstractions |
| **efcore** | Microsoft | Data access | **Reference only** — if `novolis-data` EF facet proceeds |
| **runtime** | Microsoft | .NET runtime source | **Skip** — use installed SDK |
| **roslyn-sdk** | Microsoft | Same as `D:\repos\roslyn-sdk` | Analyzer/generator samples |
| **semantic-kernel** | Microsoft | LLM orchestration | **Skip platform** — apps may use NuGet `Microsoft.SemanticKernel` |

---

## BedrockFramework (detail)

See dedicated doc. **Not a migration source** — Tcp stack already exists.

**Borrowable slices (reimplement):**

- Connection middleware pipeline
- In-memory transport for tests
- Protocol reader/writer framing for future WireFish/binary protocols

---

## aspnetcore / efcore

### What

Full framework source trees for debugging and API discovery.

### Why not import

- Novolis targets **net10.0** and **PackageReference** to Microsoft.* packages.
- Vendoring creates impossible merge burden.

### How to use locally

- Jump-to-definition spikes when designing `Novolis.Transports.Http`, Aspire hosting, EF repositories.
- **Pieces:** `IConnectionListener`, hosted service patterns, `DbContext` pooling — document in ADRs, implement in Novolis naming.

---

## semantic-kernel

### What

Microsoft agent/LLM plugin orchestration SDK.

### Why skip platform

- Orthogonal to math/physics/simulation/rendering.
- Heavy dependency and release cadence unrelated to Novolis core.

### How

- **Dogfood / SCR apps** may add `Microsoft.SemanticKernel` via PackageReference.
- **Inspiration:** plugin registry pattern for future `novolis-commands` agent hooks — doc only.

---

## roslyn-sdk

### What

Templates and samples for analyzers, source generators, Syntax Visualizer.

### How

- Already aligned with `novolis-codegen` and `novolis-analyzers`.
- **Borrow:** test project layout for generated code parity ([internal-novolis-audit/codegen-bindings-backlog.md](internal-novolis-audit/codegen-bindings-backlog.md)).

---

## Acceptance

No `ProjectReference` from any `novolis-*` csproj into `D:\dotnetrepos\*`.
