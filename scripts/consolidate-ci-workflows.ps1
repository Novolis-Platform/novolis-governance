#Requires -Version 7.0
# One CI workflow per repo (PR build + main publish). Removes pull-request.yml and merge.yml.
$ErrorActionPreference = 'Stop'
$Root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent

$standardCi = @'
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

$directoryBuildTargets = @'
<Project>
  <Import Project="$(MSBuildThisFileDirectory)..\novolis-governance\build\Novolis.Version.targets"
          Condition="Exists('$(MSBuildThisFileDirectory)..\novolis-governance\build\Novolis.Version.targets')" />
  <Import Project="$(MSBuildThisFileDirectory)..\novolis-governance\build\Novolis.Packaging.targets"
          Condition="Exists('$(MSBuildThisFileDirectory)..\novolis-governance\build\Novolis.Packaging.targets')" />
</Project>
'@

$packageRepos = @(
    'novolis-analyzers', 'novolis-aspire', 'novolis-avalonia', 'novolis-codegen',
    'novolis-commands', 'novolis-install', 'novolis-machinelearning', 'novolis-markup',
    'novolis-math', 'novolis-messaging', 'novolis-physics', 'novolis-rendering',
    'novolis-security', 'novolis-simulation', 'novolis-smoketest', 'novolis-storage',
    'novolis-template-dotnet', 'novolis-templates', 'novolis-testing',
    'novolis-transports', 'novolis-wirefish'
)

function Write-Utf8([string]$Path, [string]$Content) {
    $dir = Split-Path $Path -Parent
    if ($dir) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    Set-Content -Path $Path -Value $Content.TrimEnd() -Encoding utf8NoBOM
}

foreach ($name in $packageRepos) {
    $repo = Join-Path $Root $name
    if (-not (Test-Path $repo)) { continue }
    Write-Host "CI consolidate: $name"
    Write-Utf8 (Join-Path $repo '.github/workflows/ci.yml') $standardCi
    foreach ($old in @('pull-request.yml', 'merge.yml')) {
        $p = Join-Path $repo ".github/workflows/$old"
        if (Test-Path $p) { Remove-Item $p -Force }
    }
    Write-Utf8 (Join-Path $repo 'Directory.Build.targets') $directoryBuildTargets
    $nuget = Join-Path $repo 'nuget.config'
    if (-not (Test-Path $nuget) -and -not (Test-Path (Join-Path $repo 'NuGet.config'))) {
        Write-Utf8 $nuget $gprNugetConfig
    }
}

Write-Host 'Done (novolis-raylib uses its own ci.yml).'
