# Documentation policy

Complements [repository-policy.md](repository-policy.md) and [package-policy.md](package-policy.md).

Every **packable** library under `src/` must ship:

1. **XML API documentation** (`GenerateDocumentationFile` with strict `CS1591` — no suppressions).
2. A **package README** at `src/<Project>/README.md`, packed via `PackageReadmeFile`.

## XML documentation (public API)

Document all `public` and `protected` types and members:

| Element | Required |
|---------|----------|
| Types, members | `/// <summary>` |
| Method parameters | `/// <param name="...">` |
| Return values (non-void) | `/// <returns>` |
| Generic type parameters | `/// <typeparam name="...">` |
| Documented exceptions | `/// <exception cref="...">` when part of the contract |

Guidelines:

- Use `/// <see cref="..."/>` for cross-references.
- Use `/// <inheritdoc/>` on explicit interface implementations.
- Do **not** document `private` or `internal` members unless intentionally exposed.
- **Generated binding surfaces** produced by codegen: document regeneration and manifest inputs in the package README; do not hand-maintain thousands of `///` on generated members unless the generator emits them.

## Package README

Each packable project directory must contain `README.md` with:

1. Title and one-line purpose
2. `dotnet add package <PackageId>`
3. Prerequisites (`.NET 10` / `net10.0`)
4. Minimal quick-start code sample
5. When to use this package vs sibling packages (table for meta/umbrella packages)
6. Links to repo `docs/getting-started.md` and related package READMEs
7. Stability note when pre-release

## MSBuild wiring

Import [Novolis.Documentation.props](../build/Novolis.Documentation.props) from the repo only after all packable packages in that repo pass a strict build (no missing XML docs).

Standard csproj fragment:

```xml
<PackageReadmeFile>README.md</PackageReadmeFile>
<ItemGroup>
  <None Include="README.md" Pack="true" PackagePath="\" Condition="Exists('README.md')" />
</ItemGroup>
```

Repo-level import (example):

```xml
<Import Project="$(MSBuildThisFileDirectory)build\Novolis.Example.Documentation.props"
        Condition="Exists('$(MSBuildThisFileDirectory)build\Novolis.Example.Documentation.props')" />
```

`Novolis.Example.Documentation.props`:

```xml
<Project>
  <Import Project="$(MSBuildThisFileDirectory)..\..\novolis-governance\build\Novolis.Documentation.props"
          Condition="Exists('$(MSBuildThisFileDirectory)..\..\novolis-governance\build\Novolis.Documentation.props')" />
</Project>
```

Apply to packable `src/**/*.csproj` via `Directory.Build.props` under `src/` or per-project `Import` of repo documentation props.

## CI audit

Run [scripts/doc-audit.ps1](../scripts/doc-audit.ps1) before merge when a repo is marked documentation-complete (`build/.novolis-documentation-complete` marker file). The audit fails on missing READMEs, missing **Install** / **Quick start** sections, and placeholder quick starts (`// See docs/getting-started.md`).

## Scaffold

New packages: copy [docs/templates/package-readme.md](templates/package-readme.md).
