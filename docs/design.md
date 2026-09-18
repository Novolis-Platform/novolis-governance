# Design

Contribution model, package rules, layer boundaries, and maintainer docs.

## Goals

- Keep public APIs documented and packable as `Novolis.*` on GitHub Packages.
- Respect the closed platform spine and orthogonal islands ([library-boundaries](https://github.com/Novolis-Platform/novolis-governance/blob/main/docs/library-boundaries.md)).

## Non-goals

- Local NuGet folder feeds or cross-repo `ProjectReference` in committed `.csproj` files.
- Pulling Avalonia into non-`Novolis.Avalonia.*` libraries.
- Pulling Microsoft.Maui into non-`Novolis.Maui.*` libraries (except `Novolis.Audio.Voice.Platform.Maui`).

## Topics

- `dotnet`
- `governance`
- `novolis`
