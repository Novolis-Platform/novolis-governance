#Requires -Version 7.0
# Replace sibling-repo ProjectReference paths with GitHub Packages PackageReference (CI-safe).
$ErrorActionPreference = 'Stop'
$Root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent

$fixes = @(
    @{
        Repo     = 'novolis-transports'
        File     = 'src/Novolis.Transports.WireFish/Novolis.Transports.WireFish.csproj'
        Remove   = '<ProjectReference Include="..\..\..\novolis-messaging\src\Novolis.Messaging.Channels\Novolis.Messaging.Channels.csproj" />'
        Add      = '<PackageReference Include="Novolis.Messaging.Channels" />'
        Packages = @('Novolis.Messaging.Channels')
    },
    @{
        Repo     = 'novolis-testing'
        File     = 'src/Novolis.Testing.TUnit/Novolis.Testing.TUnit.csproj'
        Remove   = '<ProjectReference Include="..\..\..\novolis-codegen\src\Novolis.CodeGen.Reflection.Dump\Novolis.CodeGen.Reflection.Dump.csproj" />'
        Add      = '<PackageReference Include="Novolis.CodeGen.Reflection.Dump" />'
        Packages = @('Novolis.CodeGen.Reflection.Dump')
    },
    @{
        Repo     = 'novolis-messaging'
        File     = 'tests/Novolis.Messaging.Tests/Novolis.Messaging.Tests.csproj'
        Remove   = @(
            '<ProjectReference Include="..\..\..\novolis-testing\src\Novolis.Testing.TestBases\Novolis.Testing.TestBases.csproj" />'
            '<ProjectReference Include="..\..\..\novolis-testing\src\Novolis.Testing.TUnit\Novolis.Testing.TUnit.csproj" />'
        )
        Add      = @(
            '<PackageReference Include="Novolis.Testing.TestBases" />'
            '<PackageReference Include="Novolis.Testing.TUnit" />'
        )
        Packages = @('Novolis.Testing.TestBases', 'Novolis.Testing.TUnit')
    },
    @{
        Repo     = 'novolis-messaging'
        File     = 'tests/Novolis.Messaging.Channels.Tests/Novolis.Messaging.Channels.Tests.csproj'
        Remove   = '<ProjectReference Include="..\..\..\novolis-testing\src\Novolis.Testing.TestBases\Novolis.Testing.TestBases.csproj" />'
        Add      = '<PackageReference Include="Novolis.Testing.TestBases" />'
        Packages = @('Novolis.Testing.TestBases')
    },
    @{
        Repo     = 'novolis-security'
        File     = 'tests/Novolis.Security.Tests/Novolis.Security.Tests.csproj'
        Remove   = '<ProjectReference Include="..\..\..\novolis-testing\src\Novolis.Testing.Logging\Novolis.Testing.Logging.csproj" />'
        Add      = '<PackageReference Include="Novolis.Testing.Logging" />'
        Packages = @('Novolis.Testing.Logging')
    }
)

function Ensure-PackageVersions([string]$PropsPath, [string[]]$PackageIds) {
    if (-not (Test-Path $PropsPath)) { return }
    $text = Get-Content $PropsPath -Raw
    foreach ($id in $PackageIds) {
        if ($text -match [regex]::Escape($id)) { continue }
        $entry = "    <PackageVersion Include=`"$id`" Version=`"*`" />"
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

Write-Host 'Done.'
