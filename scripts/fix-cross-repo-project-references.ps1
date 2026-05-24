#Requires -Version 7.0
# Replace sibling-repo ProjectReference paths with GitHub Packages PackageReference (CI-safe).
# Prefer verify-nuget-only.ps1 after manual edits; this script is a one-shot migrator.
$ErrorActionPreference = 'Stop'
$Root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$novolisVersion = '2026.1.*'

$fixes = @(
    @{
        Repo     = 'novolis-transports'
        File     = 'src/Novolis.Transports.WireFish/Novolis.Transports.WireFish.csproj'
        Remove   = '<ProjectReference Include="..\..\..\novolis-messaging\src\Novolis.Messaging.Channels\Novolis.Messaging.Channels.csproj" />'
        Add      = '<PackageReference Include="Novolis.Messaging.Channels" />'
        Packages = @('Novolis.Messaging.Channels')
    },
    @{
        Repo     = 'novolis-wirefish'
        File     = 'src/Frank.WireFish/Frank.WireFish.csproj'
        Remove   = '<ProjectReference Include="..\..\..\novolis-messaging\src\Novolis.Messaging.Channels\Novolis.Messaging.Channels.csproj" />'
        Add      = '<PackageReference Include="Novolis.Messaging.Channels" />'
        Packages = @('Novolis.Messaging.Channels')
    },
    @{
        Repo     = 'novolis-messaging'
        File     = 'tests/Novolis.Messaging.Unit/Novolis.Messaging.Unit.csproj'
        Remove   = @(
            '<ProjectReference Include="../../../novolis-testing/src/Novolis.Testing.TestBases/Novolis.Testing.TestBases.csproj" />'
            '<ProjectReference Include="../../../novolis-testing/src/Novolis.Testing.TUnit/Novolis.Testing.TUnit.csproj" />'
        )
        Add      = @(
            '<PackageReference Include="Novolis.Testing.TestBases" />'
            '<PackageReference Include="Novolis.Testing.TUnit" />'
        )
        Packages = @('Novolis.Testing.TestBases', 'Novolis.Testing.TUnit')
    },
    @{
        Repo     = 'novolis-security'
        File     = 'tests/Novolis.Security.Unit/Novolis.Security.Unit.csproj'
        Remove   = '<ProjectReference Include="..\..\..\novolis-testing\src\Novolis.Testing.Logging\Novolis.Testing.Logging.csproj" />'
        Add      = '<PackageReference Include="Novolis.Testing.Logging" />'
        Packages = @('Novolis.Testing.Logging')
    },
    @{
        Repo     = 'novolis-raylib'
        File     = 'codegen/Novolis.Raylib.Manifests/Novolis.Raylib.Manifests.csproj'
        Remove   = '<ProjectReference Include="..\..\..\novolis-codegen\src\Novolis.CodeGen.Bindings\Novolis.CodeGen.Bindings.csproj" />'
        Add      = '<PackageReference Include="Novolis.CodeGen.Bindings" />'
        Packages = @('Novolis.CodeGen.Bindings')
    },
    @{
        Repo     = 'novolis-raylib'
        File     = 'codegen/Novolis.Raylib.CodeGen.Abstractions/Novolis.Raylib.CodeGen.Abstractions.csproj'
        Remove   = @(
            '<ProjectReference Include="..\..\..\novolis-codegen\src\Novolis.CodeGen.Bindings\Novolis.CodeGen.Bindings.csproj" />'
            '<ProjectReference Include="..\..\..\novolis-codegen\src\Novolis.CodeGen.Bindings.Roslyn\Novolis.CodeGen.Bindings.Roslyn.csproj" />'
            '<ProjectReference Include="..\..\..\novolis-codegen\src\Novolis.CodeGen.Pipeline\Novolis.CodeGen.Pipeline.csproj" />'
        )
        Add      = @(
            '<PackageReference Include="Novolis.CodeGen.Bindings" />'
            '<PackageReference Include="Novolis.CodeGen.Bindings.Roslyn" />'
            '<PackageReference Include="Novolis.CodeGen.Pipeline" />'
        )
        Packages = @('Novolis.CodeGen.Bindings', 'Novolis.CodeGen.Bindings.Roslyn', 'Novolis.CodeGen.Pipeline')
    },
    @{
        Repo     = 'novolis-raylib'
        File     = 'codegen/Novolis.Raylib.Pipeline/Novolis.Raylib.Pipeline.csproj'
        Remove   = '<ProjectReference Include="..\..\..\novolis-codegen\src\Novolis.CodeGen.Pipeline\Novolis.CodeGen.Pipeline.csproj" />'
        Add      = '<PackageReference Include="Novolis.CodeGen.Pipeline" />'
        Packages = @('Novolis.CodeGen.Pipeline')
    },
    @{
        Repo     = 'novolis-codegen'
        File     = 'tests/Novolis.CodeGen.Bindings.Unit/Novolis.CodeGen.Bindings.Unit.csproj'
        Remove   = '<ProjectReference Include="../../../novolis-raylib/codegen/Novolis.Raylib.Manifests/Novolis.Raylib.Manifests.csproj" />'
        Add      = '<PackageReference Include="Novolis.Raylib.Manifests" />'
        Packages = @('Novolis.Raylib.Manifests')
    }
)

function Ensure-PackageVersions([string]$PropsPath, [string[]]$PackageIds) {
    if (-not (Test-Path $PropsPath)) { return }
    $text = Get-Content $PropsPath -Raw
    foreach ($id in $PackageIds) {
        if ($text -match [regex]::Escape($id)) { continue }
        $entry = "    <PackageVersion Include=`"$id`" Version=`"$novolisVersion`" />"
        if ($text -match '</ItemGroup>') {
            $text = $text -replace '</ItemGroup>', "$entry`n  </ItemGroup>"
        }
    }
    Set-Content $PropsPath $text.TrimEnd() -Encoding utf8NoBOM
}

foreach ($fix in $fixes) {
    $proj = Join-Path (Join-Path $Root $fix.Repo) $fix.File
    if (-not (Test-Path $proj)) {
        Write-Warning "Skip missing: $proj"
        continue
    }
    $text = Get-Content $proj -Raw
    foreach ($line in @($fix.Remove)) {
        $text = $text.Replace($line, '')
    }
    $addLines = @($fix.Add) -join "`n    "
    if ($text -notmatch [regex]::Escape(($fix.Add | Select-Object -First 1))) {
        $text = $text -replace '(<ItemGroup>)', "`$1`n    $addLines"
    }
    Set-Content $proj $text.TrimEnd() -Encoding utf8NoBOM
    $props = Join-Path (Join-Path $Root $fix.Repo) 'Directory.Packages.props'
    Ensure-PackageVersions $props $fix.Packages
    Write-Host "Fixed $($fix.Repo)/$($fix.File)"
}

Write-Host 'Done. Run verify-nuget-only.ps1 to confirm.'
