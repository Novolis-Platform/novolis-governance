# Novolis registry data

This directory contains the canonical static catalog data used by Novolis
tooling and migration documentation.

```text
registry/
  index.json
  packages/
  schemas/
```

`index.json` is a `Novolis.Registry.Primitives.RegistryDocument` with one
entry per published NuGet package. The individual files under `packages/`
remain useful for package-specific metadata and migration records.

The reusable library and future provider adapters live in
[`Novolis-Platform/novolis-registry`](https://github.com/Novolis-Platform/novolis-registry).
The catalog does not host binaries. Packages resolve through nuget.org or
GitHub Packages, and application artifacts resolve through their release
provider.

Regenerate package entries from the workspace with:

```powershell
pwsh -File d:\novolis\novolis-governance\scripts\sync-registry-packages.ps1
```
