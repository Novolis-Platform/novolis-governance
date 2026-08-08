---
name: Roslyn XSD CodeGen spine
overview: Build a first-principles SchemaGraph → Roslyn SyntaxFactory XSD emitter in novolis-codegen (Novolis.CodeGen.Xml + .Xsd), consume it from novolis-xsd for Wire/Lean UBL profiles, and treat full UBL 2.1 as the acceptance suite—with explicit unit/integration/coverage and GitHub Packages publish gates at every phase.
todos:
  - id: p0-scaffold
    content: "Phase 0: Governance docs + scaffold Novolis.CodeGen.Xml/.Xsd; build + verify-nuget-only"
    status: completed
  - id: p1-schema-graph
    content: "Phase 1: SchemaGraph IR + unit tests; coverage ≥85%; publish CodeGen.Xml to GPR"
    status: completed
  - id: p2-wire-roslyn
    content: "Phase 2: WireXmlSerializerProfile SyntaxFactory emit; Invoice G0/G1; publish CodeGen.Xsd"
    status: completed
  - id: p3-full-ubl-wire
    content: "Phase 3: UBL normalize + full Roslyn Wire regen; IUblDocument; validate/publish Ubl packages"
    status: completed
  - id: p4-lean-mutation
    content: "Phase 4: LeanRecordsProfile + Novolis.Xsd.Ubl.Lean StripEmbedded; heap/mapper tests; publish Lean"
    status: completed
  - id: p5-retire-xscg
    content: "Phase 5: Remove XSCG engine; platform map regen; coverage + GPR final validation"
    status: completed
isProject: false
---

# Roslyn-first XSD emit (CodeGen spine + UBL crucible)

Derived from [ubl-roslyn-codegen-xsd](C:\Users\frank\.cursor\projects\d-novolis\canvases\ubl-roslyn-codegen-xsd.canvas.tsx) and [ubl-poco-mutation-layer](C:\Users\frank\.cursor\projects\d-novolis\canvases\ubl-poco-mutation-layer.canvas.tsx). Supersedes the earlier “keep XSD out of codegen” note **only** for a **schema-agnostic** emitter; UBL/Peppol **product** packages remain in [`novolis-xsd`](d:\novolis\novolis-xsd).

## Locked decisions

- **IR + Roslyn emit** live in `novolis-codegen`: `Novolis.CodeGen.Xml` (load + SchemaGraph) and `Novolis.CodeGen.Xsd` (profiles → `CompilationUnitSyntax`).
- **Product** stays in `novolis-xsd`: `Novolis.Xsd.Generator` becomes a thin host; add `Novolis.Xsd.Ubl.Lean`; keep XSCG as `--engine xscg` until Gate G1, then remove.
- **Wire** = XmlSerializer-friendly `partial class` + interfaces/bases. **Lean** = records + no `byte[]` embeddings (StripEmbedded / Detach later).
- **Emit** is SyntaxFactory-first (not CodeDom, not string templates). Formatting via existing [`RoslynEmitWriter`](d:\novolis\novolis-codegen\src\Novolis.CodeGen.Bindings.Roslyn) patterns or a sibling “write syntax tree” helper that still uses the Roslyn formatter.
- **Coverage** uses platform standard: `dotnet test --coverage` (no Coverlet package) + [`get-coverage-report.ps1`](d:\novolis\novolis-governance\scripts\get-coverage-report.ps1). Phase gates enforce **line ≥ 85%** on new CodeGen.Xml/Xsd assemblies (exclude `Generated/` outputs).
- **Publish validation** = merge to `main` triggers [`dotnet-merge-publish.yml`](d:\novolis\novolis-codegen\.github\workflows\merge.yml) / novolis-xsd equivalent; each phase ends with GPR restore smoke of the new package versions (nuget.org + github only).

```mermaid
flowchart TB
  xsdFiles[XSD files] --> xmlPkg[Novolis.CodeGen.Xml]
  xmlPkg --> graph[SchemaGraph IR]
  graph --> norm[Normalize filters]
  norm --> xsdPkg[Novolis.CodeGen.Xsd]
  xsdPkg --> wireProf[Wire profile]
  xsdPkg --> leanProf[Lean profile]
  wireProf --> syntax[CompilationUnitSyntax]
  leanProf --> syntax
  syntax --> fmt[Roslyn format write]
  fmt --> ublWire[Novolis.Xsd.Ubl]
  fmt --> ublLean[Novolis.Xsd.Ubl.Lean]
  host[novolis-xsd tools/XsdGen] --> xsdPkg
```

## Repo / package layout

### novolis-codegen (new)

| Path | Role |
|------|------|
| [`src/Novolis.CodeGen.Xml/`](d:\novolis\novolis-codegen\src) | `SchemaSetLoader`, `SchemaGraph`, particles/refs/facets, binary facet tagging |
| [`src/Novolis.CodeGen.Xsd/`](d:\novolis\novolis-codegen\src) | `IEmitProfile`, `WireXmlSerializerProfile`, `LeanRecordsProfile`, SyntaxFactory emitters |
| [`tests/Novolis.CodeGen.Unit/Xml/`](d:\novolis\novolis-codegen\tests) + `Xsd/` | TUnit tests for IR + emit |
| [`tests/Novolis.CodeGen.Unit/Fixtures/Schemas/`](d:\novolis\novolis-codegen\tests) | Tiny XSDs (SBDH-sized + synthetic) for unit speed |
| Update [`.novolis/packages.json`](d:\novolis\novolis-codegen\.novolis), [`Novolis.CodeGen.slnx`](d:\novolis\novolis-codegen), [`Directory.Packages.props`](d:\novolis\novolis-codegen\Directory.Packages.props) (`Microsoft.CodeAnalysis.CSharp`) |

### novolis-xsd (evolve)

| Path | Role |
|------|------|
| [`src/Novolis.Xsd.Generator/`](d:\novolis\novolis-xsd\src\Novolis.Xsd.Generator) | Host + UBL normalize (BaseDocument, NoSignatures filter); `--engine roslyn\|xscg` |
| [`src/Novolis.Xsd.Ubl.Lean/`](d:\novolis\novolis-xsd\src) | Pre-generated lean Invoice/CreditNote + mappers |
| [`tools/XsdGen/`](d:\novolis\novolis-xsd\tools\XsdGen) | CLI: `ubl`, `ubl-lean`, engine flag |
| [`tests/Novolis.Xsd.Unit/`](d:\novolis\novolis-xsd\tests\Novolis.Xsd.Unit) | Gates G0–G5: round-trip, validate, lean heap, dual-engine |

### Governance docs

- Update [`frank-codegen-devtools.md`](d:\novolis\novolis-governance\docs\imports-todo\frank-codegen-devtools.md): XSD **generic** emitter → `novolis-codegen`; UBL product → `novolis-xsd`.
- Add row to [`frank-naming-and-structure.md`](d:\novolis\novolis-governance\docs\frank-naming-and-structure.md) for `Novolis.CodeGen.Xml` / `.Xsd`.
- Regen Platform map: `pwsh -File d:\novolis\novolis-governance\build\Generate-Platform-Slnx.ps1`.

---

## Phase 0 — Governance + scaffolding (Validation: docs + empty packages build)

1. Doc updates (codegen + naming).
2. Create packable `Novolis.CodeGen.Xml` and `Novolis.CodeGen.Xsd` with READMEs, XML docs, CPM package refs.
3. Wire into `Novolis.CodeGen.slnx` + `.novolis/packages.json`.
4. **Validate:** `dotnet build` both; `pwsh -File d:\novolis\novolis-governance\scripts\verify-nuget-only.ps1`; no local feeds.

---

## Phase 1 — SchemaGraph IR (Validation: unit + coverage ≥ 85% Xml)

### Implement in `Novolis.CodeGen.Xml`

- Reuse/port load rules from [`SchemaSetLoader`](d:\novolis\novolis-xsd\src\Novolis.Xsd.Generator\SchemaSetLoader.cs) (DTD parse, clear `schemaLocation` before compile).
- Build immutable IR:
  - `SchemaTypeId`, `ComplexTypeNode`, `SimpleTypeNode`, `ElementDecl`, `AttributeDecl`, `Particle` (sequence/choice/all)
  - `BinaryFacet` on base64/`BinaryObject`-like types
  - `DocumentRoot` detection (element with no inbound refs / maindoc heuristic configurable)
- Graph builder walks compiled `XmlSchemaSet` once; deterministic ordering for stable emit.

### Tests (`tests/Novolis.CodeGen.Unit/Xml/`)

| Test | Asserts |
|------|---------|
| LoadTinySchema | Fixture XSD → graph non-empty |
| ComplexSequence | Particles preserve order/cardinality |
| BinaryFacetTagged | base64Binary / BinaryObject marked |
| DedupeIncludes | UBL-style shared imports → single type id |
| DeterministicOrder | Two builds → identical type id sequences |

### Coverage / publish gate P1

```powershell
dotnet test d:\novolis\novolis-codegen\tests\Novolis.CodeGen.Unit\Novolis.CodeGen.Unit.csproj --coverage --coverage-output-format cobertura
pwsh -File d:\novolis\novolis-governance\scripts\get-coverage-report.ps1 -Include novolis-codegen -LineThreshold 85
```

- Merge + CI publish `Novolis.CodeGen.Xml` to GPR.
- Smoke: `dotnet add package Novolis.CodeGen.Xml --version 2026.1.*` in a throwaway restore (nuget.org + github only).

---

## Phase 2 — Roslyn Wire emitter (Validation: compile emitted C# + Invoice round-trip)

### Implement in `Novolis.CodeGen.Xsd`

- `IEmitProfile` + `WireXmlSerializerProfile`:
  - `partial class`, Xml attributes, public get/set, `Collection<>` or `List<>` (match current UBL choice: `Collection<>`)
  - Emit `interface` per complex type (`I{Name}`) and document root `IUblDocument`-style hook via options
  - File-scoped namespaces, nullable enable, no DebuggerStepThrough unless profile asks
- `SyntaxEmitWriter`: `CompilationUnitSyntax` → formatted text (Roslyn `Formatter` / AdhocWorkspace); optional hooks aligned with Bindings.Roslyn.
- **Do not** use CodeDom.

### Tiny fixture emit tests

| Test | Asserts |
|------|---------|
| EmitCompiles | Roslyn compilation of emitted CU succeeds against net10.0 refs |
| XmlRoundTripTiny | Serialize/deserialize fixture instance |
| InterfaceEmitted | Syntax tree contains `InterfaceDeclarationSyntax` |
| NoTrailingSemicolonDefect | Properties are valid C# (regression vs CodeDom) |

### UBL Invoice-only subgraph (novolis-xsd)

- Tool: `--engine roslyn --scope invoice` loads Invoice + transitive common types into graph (or filter graph to Invoice closure).
- Emit into a temp or `Generated.Roslyn/` for comparison.
- **Gate G0:** XSCG Invoice still round-trips ([`UblRoundTripTests`](d:\novolis\novolis-xsd\tests\Novolis.Xsd.Unit\Ubl\UblRoundTripTests.cs)).
- **Gate G1 (narrow):** Roslyn-emitted InvoiceType deserializes `UBL-Invoice-2.1-Example.xml` and re-serializes without throw.

### Coverage / publish gate P2

- Line ≥ 85% on `Novolis.CodeGen.Xsd` (exclude nothing except test fixtures).
- Publish `Novolis.CodeGen.Xsd` + bumped `Novolis.CodeGen.Xml` to GPR.
- novolis-xsd ProjectRef/PackageReference to published versions; CI green.

---

## Phase 3 — UBL normalize + full Wire Roslyn (Validation: full package build + schema validate)

### UBL-specific normalize (novolis-xsd, not CodeGen)

- Port/fix [`UblBaseDocumentVisitor`](d:\novolis\novolis-xsd\src\Novolis.Xsd.Generator\Visitors) to operate on **SchemaGraph** (or pre-graph XmlSchemaSet then rebuild graph).
- Filters: `NoSignatures` (drop XmlDsig/XAdES namespaces), optional CBC flatten.
- Default tool path: `--engine roslyn` generates full `Novolis.Xsd.Ubl/Generated`.

### Tests

| Test | Asserts |
|------|---------|
| FullUblBuilds | `dotnet build` Novolis.Xsd.Ubl after regen |
| OasisInvoiceValidate | [`UblSchemaValidator`](d:\novolis\novolis-xsd\src\Novolis.Xsd.Ubl.Validation) error-free on example |
| OasisCreditNoteRoundTrip | Load/save CreditNote sample if present |
| IUblDocumentOnMaindocs | All maindoc roots implement shared interface |
| PackageSizeReport | Artifact: file count / MB vs previous XSCG baseline (checked into `docs/` or CI summary) |

### Coverage / publish gate P3

- Regen committed `Generated/` on CI job or maintainer script; PR must include regen when schemas/tooling change.
- Publish `Novolis.Xsd.Ubl`, `.Ubl.Validation`, `.Generator`, `.Tool` to GPR.
- Consumer smoke: restore Ubl from GPR only; run unit tests.

**Gate G2–G3:** BaseDocument/IUblDocument present; NoSignatures profile optional package or flag documented.

---

## Phase 4 — Lean profile + mutation (Validation: heap + mapper round-trip)

### `LeanRecordsProfile` in CodeGen.Xsd

- Records + init properties; BinaryFacet → omit or `BlobRef` (string id / URI).
- Companion mapper stubs optional in same emit or separate `MapperProfile`.

### `Novolis.Xsd.Ubl.Lean`

- Hand-curate or emit Invoice/CreditNote lean types + `ToLean`/`FromLean` with `StripEmbedded` policy.
- Depend on Wire package for FromLean materialization when needed.

### Tests

| Test | Asserts |
|------|---------|
| LeanHasNoByteArrays | Reflection: no `byte[]` on lean Invoice graph |
| StripEmbedded | Wire with attachment bytes → lean null/URI only |
| FromLeanRoundTrip | Lean→Wire→XML validates for stripped case |
| HeapDelta | Attachment-heavy synthetic XML: lean WorkingSet or allocated bytes &lt; wire (assert ratio &lt; 0.5 or absolute delta) |

### Coverage / publish gate P4

- Publish `Novolis.Xsd.Ubl.Lean`.
- Coverage includes Lean mappers ≥ 85% line.
- **Gate G4–G5.**

---

## Phase 5 — Dual-engine retirement + platform hygiene (Validation: XSCG removed + platform map)

1. Make Roslyn the only engine; delete XSCG PackageReference and CodeDom sanitize path from Generator.
2. Update READMEs, NOTICE, canvases/docs pointers.
3. `Generate-Platform-Slnx.ps1`; `verify-nuget-only`; `verify-project-ref-mode.ps1 -SkipBuild` (or full build of affected).
4. Org coverage: `get-coverage-report.ps1 -Include novolis-codegen,novolis-xsd -LineThreshold 80` (repo-level floor; Xml/Xsd keep 85%).
5. Final GPR publish both repos; gpr-health-check if used.

---

## Cross-cutting Validation matrix (every phase)

| Layer | Command / artifact | Fail if |
|-------|-------------------|---------|
| Unit | TUnit under `Novolis.CodeGen.Unit` / `Novolis.Xsd.Unit` | Any fail |
| Emit compile | AdhocWorkspace compile of generated CUs | Diagnostic severity Error |
| Round-trip | OASIS / fixture XML | Exception or schema Error |
| Coverage | `dotnet test --coverage` + governance report | Xml/Xsd line &lt; 85% |
| NuGet-only | `verify-nuget-only.ps1` | Non-zero |
| Publish | merge workflow → GPR | Push/restore fail |
| Smoke restore | Consumer csproj PackageReference `2026.1.*` from github source | Restore fail |
| Layer boundaries | N/A (orthogonal island) | Avalonia refs forbidden |

Publishing is **in-scope validation**, not optional polish: a phase is incomplete until packages are on GitHub Packages and a clean restore works without ProjectRef.

---

## Out of scope (this plan)

- Schematron / Peppol BIS business-rule validation
- Incremental source generators inside consumer apps (pre-gen remains default)
- Porting Frank.XsdCodeGeneration spike as-is (reference only)
- Full mapper coverage for all ~65 UBL maindocs (Billing Invoice/CreditNote first; expand later)

---

## Success criteria (program complete)

- `Novolis.CodeGen.Xml` + `.Xsd` published; no CodeDom in Roslyn path.
- Full UBL Wire regenerated via Roslyn; OASIS Invoice validate + round-trip green.
- `Novolis.Xsd.Ubl.Lean` with StripEmbedded; heap test green.
- Coverage gates met; nuget-only green; both repos CI publish green.
- XSCG engine removed; Platform slnx includes new packages.

