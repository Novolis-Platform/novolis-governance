#Requires -Version 7.0
# Configures Novolis package repos: single CI workflow, GPR publish, 4-part versioning.
$ErrorActionPreference = 'Stop'
$Root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent

$versionProps = @'
<?xml version="1.0" encoding="utf-8"?>
<Project>
  <PropertyGroup Label="Novolis package version (major.minor.patch.build)">
    <NovolisVersionMajor>0</NovolisVersionMajor>
    <NovolisVersionMinor>0</NovolisVersionMinor>
    <NovolisVersionPatch>1</NovolisVersionPatch>
    <NovolisVersionBuild>1</NovolisVersionBuild>
  </PropertyGroup>
</Project>
'@

$directoryBuildTargets = @'
<Project>
  <Import Project="$(MSBuildThisFileDirectory)..\novolis-governance\build\Novolis.Version.targets"
          Condition="Exists('$(MSBuildThisFileDirectory)..\novolis-governance\build\Novolis.Version.targets')" />
  <Import Project="$(MSBuildThisFileDirectory)..\novolis-governance\build\Novolis.Packaging.targets"
          Condition="Exists('$(MSBuildThisFileDirectory)..\novolis-governance\build\Novolis.Packaging.targets')" />
</Project>
'@

$ciYml = @'
name: CI

on:
  pull_request:
    branches: [main]
  push:
    branches: [main]
    paths-ignore:
      - '.novolis/version.props'
      - 'docs/**'
      - '**.md'
  workflow_dispatch:
    inputs:
      skip_publish:
        description: Build only; do not publish to GitHub Packages
        type: boolean
        default: false

permissions:
  contents: write
  packages: write

jobs:
  pull_request:
    if: github.event_name == 'pull_request'
    uses: Novolis-Platform/novolis-workflows/.github/workflows/dotnet-pull-request.yml@main
    secrets: inherit

  main:
    if: github.event_name == 'push' || github.event_name == 'workflow_dispatch'
    uses: Novolis-Platform/novolis-workflows/.github/workflows/dotnet-merge-publish.yml@main
    with:
      skip_publish: ${{ github.event_name == 'workflow_dispatch' && inputs.skip_publish }}
    secrets: inherit
'@

$releaseYml = @'
name: Release

on:
  release:
    types: [published]

permissions:
  contents: read
  packages: write

jobs:
  publish:
    uses: Novolis-Platform/novolis-workflows/.github/workflows/dotnet-publish-nuget.yml@main
    secrets: inherit
'@

$gprNugetConfig = @'
<?xml version="1.0" encoding="utf-8"?>
<configuration>
  <packageSources>
    <clear />
    <add key="nuget.org" value="https://api.nuget.org/v3/index.json" protocolVersion="3" />
    <add key="github" value="https://nuget.pkg.github.com/Novolis-Platform/index.json" />
  </packageSources>
  <packageSourceMapping>
    <packageSource key="github">
      <package pattern="Novolis.*" />
    </packageSource>
    <packageSource key="nuget.org">
      <package pattern="*" />
    </packageSource>
  </packageSourceMapping>
</configuration>
'@

function Write-Utf8([string]$Path, [string]$Content) {
    $dir = Split-Path $Path -Parent
    if ($dir) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    Set-Content -Path $Path -Value $Content.TrimEnd() -Encoding utf8NoBOM
}

function Ensure-VersionImport([string]$RepoPath) {
    $props = Join-Path $RepoPath 'Directory.Build.props'
    if (-not (Test-Path $props)) { return }
    $text = Get-Content $props -Raw
    if ($text -match 'version\.props') { return }
    $import = @"
  <Import Project="`$(MSBuildThisFileDirectory).novolis\version.props"
          Condition="Exists('`$(MSBuildThisFileDirectory).novolis\version.props')" />
"@
    $text = $text -replace '(<Project>\s*)', "`$1`n$import`n"
    Write-Utf8 $props $text
}

$packageRepos = @(
    'novolis-analyzers', 'novolis-aspire', 'novolis-avalonia', 'novolis-codegen',
    'novolis-commands', 'novolis-install', 'novolis-machinelearning', 'novolis-markup',
    'novolis-math', 'novolis-messaging', 'novolis-physics', 'novolis-raylib',
    'novolis-rendering', 'novolis-security', 'novolis-simulation', 'novolis-smoketest',
    'novolis-storage', 'novolis-template-dotnet', 'novolis-templates', 'novolis-testing',
    'novolis-transports', 'novolis-wirefish'
)

foreach ($name in $packageRepos) {
    $repo = Join-Path $Root $name
    if (-not (Test-Path $repo)) {
        Write-Warning "Skip missing repo: $name"
        continue
    }
    Write-Host "Configure $name"
    Write-Utf8 (Join-Path $repo '.novolis/version.props') $versionProps
    Write-Utf8 (Join-Path $repo 'Directory.Build.targets') $directoryBuildTargets
    Ensure-VersionImport $repo
    if ($name -ne 'novolis-raylib') {
        Write-Utf8 (Join-Path $repo '.github/workflows/ci.yml') $ciYml
        foreach ($old in @('pull-request.yml', 'merge.yml')) {
            $p = Join-Path $repo ".github/workflows/$old"
            if (Test-Path $p) { Remove-Item $p -Force }
        }
    }
    $nuget = Join-Path $repo 'nuget.config'
    if (-not (Test-Path $nuget) -and -not (Test-Path (Join-Path $repo 'NuGet.config'))) {
        Write-Utf8 $nuget $gprNugetConfig
    }
    Write-Utf8 (Join-Path $repo '.github/workflows/release.yml') $releaseYml
}

Write-Host 'Done.'
