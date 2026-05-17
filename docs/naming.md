# Naming policy

## Repositories

Use `novolis-<domain>` (lowercase, kebab-case).

Examples: `novolis-math`, `novolis-raylib`, `novolis-transports`.

Avoid: personal names, `core`, `common`, `utils`, `shared`, vague junk-drawer names.

## NuGet packages

Use `Novolis.<Domain>` (PascalCase segments).

Examples: `Novolis.Math`, `Novolis.Raylib`.

Adapters use suffixes: `Novolis.Storage.SqlServer`, `Novolis.Messaging.AzureServiceBus`, `Novolis.Testing.TUnit`.

## Testing

Use **[TUnit](https://tunit.dev)** exclusively at **1.44.39** (central pin in `Directory.Packages.props`). Run tests via **Microsoft.Testing.Platform** (`"test": { "runner": "Microsoft.Testing.Platform" }` in `global.json`).

- Do not add xUnit, NUnit, MSTest, `Microsoft.NET.Test.Sdk`, Coverlet, or **FluentAssertions**.
- Use TUnit assertions only: `await Assert.That(...)` from `TUnit.Core`.
- Test projects reference **TUnit** only (no Test.Sdk); ML-style test exes may set `<OutputType>Exe</OutputType>`.
