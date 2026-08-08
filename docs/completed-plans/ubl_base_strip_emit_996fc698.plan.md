---
name: UBL Base strip emit
overview: Add a deterministic Roslyn emit profile that generates InvoiceBase / CreditNoteBase / ReminderBase as records + interfaces (plus a shared billing spine interface), rewriting BinaryObject embeddings to metadata-only refs so large attachments cannot inflate heap.
todos:
  - id: codegen-base-profile
    content: StripEmbeddedBaseProfile + BinaryObjectRef + IBillingDocumentBase; EmitOptions; unit tests ≥85%
    status: completed
  - id: xsd-host-ubl-base
    content: RoslynXsdCodeGenerator.GenerateBase + XsdGen ubl-base → Ubl.Lean/Generated
    status: completed
  - id: mappers-tests
    content: Wire↔Base mappers for Invoice/CreditNote/Reminder; no-byte[] + heap tests; retire hand LeanModels
    status: completed
  - id: publish-docs
    content: Publish CodeGen.Xsd + Ubl.Lean; README/canvas pointers; nuget-only check
    status: completed
isProject: false
---

# Deterministic UBL Base emit (records + interfaces, StripEmbedded)

Derived from [ubl-type-hierarchies](C:\Users\frank\.cursor\projects\d-novolis\canvases\ubl-type-hierarchies.canvas.tsx) and current Wire/Lean stack. Extends [`Novolis.CodeGen.Xsd`](d:\novolis\novolis-codegen\src\Novolis.CodeGen.Xsd) and dogfoods via [`novolis-xsd`](d:\novolis\novolis-xsd).

## Locked decisions

- **Shape**: positional/init **records** + matching **`I{Name}Base`** interfaces (not XmlSerializer Wire classes).
- **Names**: `InvoiceBase` / `CreditNoteBase` / `ReminderBase` (and line/CAC analogues as `*Base`), plus shared spine `IBillingDocumentBase`.
- **Package**: commit generated sources under [`Novolis.Xsd.Ubl.Lean`](d:\novolis\novolis-xsd\src\Novolis.Xsd.Ubl.Lean) in `Generated/` (replace hand-thin `InvoiceLean` surface over time; keep mappers as Wire↔Base).
- **StripEmbedded**: BinaryFacet / `byte[]` **Value** omitted; **keep** metadata attributes (`mimeCode`, `filename`, `uri`, `format`, `encodingCode`, `characterSetCode`) on a generated `BinaryObjectRef` record. `ExternalReference` stays as-is (already non-byte).
- **Scope v1**: document closures of **Invoice, CreditNote, Reminder** only (`SchemaGraphScope` + three roots).
- **Determinism**: SchemaGraph ordered type ids; stable property order; one file per type; no timestamps in output.

```mermaid
flowchart TB
  xsd[UBL XSD] --> graph[SchemaGraph]
  graph --> scope[Filter Invoice CreditNote Reminder closure]
  scope --> profile[StripEmbeddedBaseProfile]
  profile --> binRef[BinaryObjectRef metadata only]
  profile --> spine[IBillingDocumentBase]
  profile --> docs["InvoiceBase / CreditNoteBase / ReminderBase"]
  profile --> ifaces["IInvoiceBase / ..."]
  docs --> leanPkg[Novolis.Xsd.Ubl.Lean Generated]
  wire[Wire InvoiceType] --> mapper[ToBase StripEmbedded]
  mapper --> docs
```

## CodeGen (`novolis-codegen`)

### New emit profile

Add [`StripEmbeddedBaseProfile`](d:\novolis\novolis-codegen\src\Novolis.CodeGen.Xsd) implementing `IEmitProfile`:

- For each included complex type `FooType` → emit:
  - `public interface IFooBase { ... }`
  - `public sealed record FooBase(...) : IFooBase;` (or `FooBase` without `Type` suffix for document roots: **`InvoiceBase`** from `InvoiceType`)
- Naming rule (deterministic):
  - Document roots (`IsDocumentRoot`): strip trailing `Type` → `InvoiceBase`, interface `IInvoiceBase`
  - Other complex: `{CSharpName}` with `Type`→`Base` (`InvoiceLineType` → `InvoiceLineBase`)
- Collections: `IReadOnlyList<TBase>` (not `Collection<>`)
- Simple CBC wrappers with non-binary `Value`: collapse to CLR scalar **or** keep thin `*Base` with `Value` only — **collapse to CLR** for identifier/amount/code/date (smaller graphs; matches current Lean intent). Keep nested CAC as Base records.
- **Binary rewrite** (core OOM guard):
  - When particle/attr type has `BinaryFacet != None` or resolves to `byte[]`: emit property type `BinaryObjectRef?` instead of nested binary type / `byte[]`
  - Do **not** emit `EmbeddedDocumentBinaryObjectType` / UDT `BinaryObjectType` as full types
  - Emit single shared:

```csharp
public sealed record BinaryObjectRef(
    string? MimeCode,
    string? Filename,
    string? Uri,
    string? Format,
    string? EncodingCode,
    string? CharacterSetCode);
```

- Skip emitting any type whose **only** content would be `byte[] Value` after strip (no orphan empty types).

### Shared billing spine

After emitting the three document Bases, emit [`IBillingDocumentBase`](d:\novolis\novolis-codegen\src\Novolis.CodeGen.Xsd) listing the **exact triple-intersection** property set (35 props from hierarchy analysis), using Base/scalar types. Each of `IInvoiceBase`, `ICreditNoteBase`, `IReminderBase` **extends** `IBillingDocumentBase`. Document-specific props remain only on the concrete iface/record.

Role analogues stay document-specific (`InvoiceTypeCode` vs `CreditNoteTypeCode` vs `ReminderTypeCode`) — not forced onto the spine.

### EmitOptions additions

Extend [`EmitOptions`](d:\novolis\novolis-codegen\src\Novolis.CodeGen.Xsd\IEmitProfile.cs):

- `StripEmbeddedPolicy` = `MetadataOnly` (default for this profile)
- `BillingSpineInterfaceName` = `"IBillingDocumentBase"`
- Reuse `IncludeTypeIds` / root namespace / one-file-per-type

### Tests (`Novolis.CodeGen.Unit/Xsd/`)

| Test | Assert |
|------|--------|
| BaseEmitDeterministic | Two emits → identical formatted text |
| BaseHasInterfaces | Syntax contains `InterfaceDeclaration` + `RecordDeclaration` |
| NoByteArrays | Emitted text / compiled types have no `byte[]` |
| BinaryObjectBecomesRef | Attachment-like fixture → `BinaryObjectRef` props, metadata names present |
| BillingSpineOnDocs | `IInvoiceBase` base list includes `IBillingDocumentBase` |
| InvoiceCreditNoteReminderScope | Fixture or tiny multi-root graph emits three `*Base` roots |

Coverage: keep CodeGen.Xsd line ≥ 85%.

## novolis-xsd host

### Generator API

Extend [`XsdGenerationOptions`](d:\novolis\novolis-xsd\src\Novolis.Xsd.Generator\XsdGenerationOptions.cs) + thin `RoslynXsdCodeGenerator.GenerateBase(...)`:

- `Profile = Base` (StripEmbedded)
- `ScopeLocalNames = { Invoice, CreditNote, Reminder }`
- Output: `src/Novolis.Xsd.Ubl.Lean/Generated`

### Tool

[`tools/XsdGen`](d:\novolis\novolis-xsd\tools\XsdGen\Program.cs):

```text
ubl-base   # regenerate Lean/Generated Bases (roslyn StripEmbedded)
```

Wire existing `ubl-lean` to call the same path (or alias).

### Mappers (hand + tests)

Replace stub mappers in [`Mappers.cs`](d:\novolis\novolis-xsd\src\Novolis.Xsd.Ubl.Lean\Mappers.cs):

- `InvoiceBaseMapper.ToBase(InvoiceType)` / `FromBase` (FromBase does **not** restore bytes)
- Same for CreditNote + **Reminder**
- Strip path: `DocumentReference.Attachment.EmbeddedDocumentBinaryObject` → `BinaryObjectRef` from attrs; `Value` ignored
- Also strip `Signature.DigitalSignatureAttachment` embeddings in closure

Retire or thin-wrap old `InvoiceLean` names as aliases to `InvoiceBase` if needed for one release, then delete duplicates in `LeanModels.cs`.

### Validation tests (`Novolis.Xsd.Unit`)

- Reflection: no `byte[]` anywhere under `InvoiceBase` graph
- OASIS Invoice → `ToBase` succeeds; attachment-heavy synthetic Wire with 2MB `Value` → Base allocated footprint ≪ Wire (reuse/strengthen heap test)
- ReminderBase round-trip of scalar spine fields
- Regenerated `Generated/` is committed; CI can optionally run `ubl-base` and fail on dirty tree

## Determinism checklist

1. Graph build order already sorted in [`SchemaGraphBuilder`](d:\novolis\novolis-codegen\src\Novolis.CodeGen.Xml\SchemaGraphBuilder.cs)
2. Property emit order: attributes alpha, then particle DFS (document); same as Wire
3. `SyntaxEmitWriter.Format` only (no wall-clock)
4. Unit test golden: hash of concatenated relative path + source

## Publish / hygiene

- Bump/publish `Novolis.CodeGen.Xsd` then `Novolis.Xsd.Ubl.Lean` (+ Generator/Tool) to GPR (`2026.1.*`)
- `verify-nuget-only`; regen Platform map if new packables (none expected)
- Update Lean README + hierarchy canvas “Proposed bases” to point at generated `*Base`

## Out of scope

- Changing Wire `Generated/` XmlSerializer models (bytes remain on Wire for fidelity)
- All ~65 maindocs as Base
- Schematron / Peppol rules
- Restoring binary on `FromBase`

