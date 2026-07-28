# Local NuGet development

**Preferred:** iterate cross-repo with **Platform ProjectReference mode** — open/build [`Novolis.Platform.slnx`](../build/Novolis.Platform.slnx). No pack loop, no local feed. See [platform-project-ref-mode.md](platform-project-ref-mode.md).

```powershell
pwsh -File novolis-governance/build/Generate-Platform-Slnx.ps1
dotnet build novolis-governance/build/Novolis.Platform.slnx
# or: dotnet build <consumer.csproj> -p:NovolisUseProjectReferences=true
```

Committed source stays `PackageReference`-only. Publish to **GitHub Packages** before consumers outside the meta solution can restore your change ([nuget-only-policy.md](nuget-only-policy.md)).

## Deprecated: local folder feed

The folder-feed workflow (`artifacts/nuget-local`, `pack-novolis-local.ps1`, `novolis-local` in `nuget.config`) is **deprecated** and **forbidden** for agents and new work. Do not add local sources to committed `nuget.config` files.

Historical notes (do not follow for new work):

| Default (legacy) | Override |
|------------------|----------|
| `d:\novolis\artifacts\nuget-local` | `NOVOLIS_LOCAL_FEED` |

Cross-repo `ProjectReference` in `.csproj` remains forbidden — enforce with `scripts/verify-nuget-only.ps1`.

## Stack boundary verification

Before shipping math / physics / simulation:

```powershell
.\novolis-governance\scripts\verify-stack-boundaries.ps1
```

See [library-boundaries.md](library-boundaries.md).

## Versioning (GPR)

| Context | Version |
|---------|---------|
| CI / GitHub Packages | Platform line `2026.1.*` — see [package-policy.md](package-policy.md) |
| Local meta build | Source via ProjectReference mode (no version bump needed) |

## Related

- [platform-project-ref-mode.md](platform-project-ref-mode.md)
- [nuget-only-policy.md](nuget-only-policy.md)
- [simulation-layer-policy.md](simulation-layer-policy.md)
- [package-policy.md](package-policy.md)
