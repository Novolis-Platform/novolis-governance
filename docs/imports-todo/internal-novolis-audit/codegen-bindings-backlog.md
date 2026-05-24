# CodeGen bindings — post–Phase 4 backlog

## What

Items **deferred** after the binding codegen library baseline ([initial-idea-v2.md](https://github.com/Novolis-Platform/novolis-codegen/blob/main/docs/specs/binding-codegen-library/initial-idea-v2.md)):

| Item | Description |
|------|-------------|
| **Phase 6 — façade doc enrichment** | Automated flow from generated façade XML back into C# manifest sources (`Novolis.Raylib.Manifests`) |
| **Second consumer** | Prove `Novolis.CodeGen.Bindings` is not Raylib-only (e.g. future native UI shim, another game API) |
| **NativePack generator** | Packaging native DLLs consistently with L0 manifest fragments |
| **BindingSurface sugar** | Higher-level manifest ergonomics beyond raw fragments |
| **Parity T2** | Byte-identical generated output (not required today; T1 AST gate is enough) |

**Shipped baseline (do not re-import):**

- `Novolis.CodeGen.Pipeline`, `Bindings`, `Bindings.Roslyn`
- Raylib manifests, `RaylibBindingCodegenHost`, T0/T1 parity, 14 generated outputs

## Why

- Raylib lane is the forcing function; without a second consumer, manifest APIs may stay Raylib-shaped.
- Doc enrichment reduces hand-maintained companion drift between L2 companions and L3 façades.
- Native pack generation is recurring work across Raylib, ImGui, Raygui shims.

## How

### Phase 6 — doc enrichment

1. Define manifest fragment field for doc template or `@doc` hooks consumed by emitter.
2. Pipeline step: after generate, optional `doc-sync` writes summary lines into companion `.cs` **only** when fingerprint unchanged (safety).
3. Gate with T1 comparer excluding doc-only regions if needed.

### Second consumer spike

1. Pick smallest non-Raylib target (e.g. code generator for `novolis-wirefish` capture metadata, or internal test manifest).
2. Implement `IBindingManifestSource` + one `InteropExports` fragment; run `BindingCodegenExecutor` in unit test with `MockFileSystem`.
3. Document required companion pattern in `novolis-codegen/docs`.

### NativePack generator

1. Spec fragment type `NativePack` with RID → DLL list.
2. MSBuild target emits `runtimes/**` layout; align with `Novolis.Raylib` packaging today.
3. Share with install repo if needed.

### Sequencing

- After Raylib bindings stable on GPR `2026.1.*`.
- No cross-repo `ProjectReference` into `novolis-raylib` from codegen — manifests stay in consumer repo.

## Acceptance

- Backlog tracked here; each item gets its own PR wave with parity tests.
- Second consumer merged or spike doc explains why deferred another quarter.
