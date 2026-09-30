# File-based apps

Standing verify and generate scripts in this repository are .NET 10 file-based apps. Process glue (`git`, `gh`, hooks, destructive GPR deletes) stays PowerShell.

## Run

Always pass `--file`. Bare `dotnet run file.cs` is wrong when the working directory contains a `.csproj`.

```powershell
dotnet run --file d:\novolis\novolis-governance\scripts\verify-nuget-only.cs
dotnet run --file d:\novolis\novolis-governance\scripts\Export-GraphicalProfile.cs -- --check
```

Existing `.ps1` names remain as thin forwarders until shared workflows call `--file` directly.

## House style

Every file-based app starts with:

```csharp
#:property TargetFramework=net10.0
#:property PublishAot=false
#:property PackAsTool=false
#:property ImplicitUsings=enable
#:property Nullable=enable
```

`PublishAot` and `PackAsTool` default on for file-based apps; both are wrong for governance scripts.

## Isolation

[scripts/Directory.Build.props](../scripts/Directory.Build.props) stops a future forest-level props file from leaking into these apps. Do not place file-based apps next to a `.csproj`. Do not `#:project` a sibling checkout (NuGet-only). `#:package` published `Novolis.*` `2026.1.*` is allowed when BCL is not enough.

## Grow-ups

Large shared commands belong in existing families, not new repos:

| Work | Family |
|------|--------|
| Coverage / test gaps | `Novolis.Tools.Coverage` + `.Cli` |
| Marketing / seed / org landing / portfolio site | `Novolis.Tools.Docs` + `.Cli` |
| Platform slnx / package map / project-ref verify | `Novolis.Workspaces.DotNet.Slnx` + `Novolis.Solution.Tool` |
| App / utility publish | `AppsManifest` / `UtilitiesManifest` (private `tools/`) |
