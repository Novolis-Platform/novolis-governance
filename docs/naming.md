# Naming policy

## Repositories

Use `novolis-<domain>` (lowercase, kebab-case).

Examples: `novolis-math`, `novolis-raylib`, `novolis-transports`.

Avoid: personal names, `core`, `common`, `utils`, `shared`, vague junk-drawer names.

## NuGet packages

Use `Novolis.<Domain>` (PascalCase segments).

Examples: `Novolis.Math`, `Novolis.Raylib`.

Adapters use suffixes: `Novolis.Storage.SqlServer`, `Novolis.Messaging.AzureServiceBus`, `Novolis.Testing.Xunit`.
