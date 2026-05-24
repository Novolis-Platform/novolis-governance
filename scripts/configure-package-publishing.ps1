#Requires -Version 7.0
# Configures Novolis package repos for org NuGet publish with 4-part versioning (0.0.1.1 + build bump on merge).
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
</Project>
'@

$mergeYml = @'
name: 'CI: main'

on:
  push:
    branches: [main]
    paths-ignore:
      - '.novolis/version.props'
  workflow_dispatch:
    inputs:
      skip_publish:
        description: Build and bump only; do not push to nuget.org
        type: boolean
        default: false

permissions:
  contents: write
  id-token: write

jobs:
  merge_job:
    name: Build, publish, bump build
    uses: Novolis-Platform/novolis-workflows/.github/workflows/dotnet-merge-publish.yml@main
    with:
      skip_publish: ${{ inputs.skip_publish == true }}
    secrets: inherit
'@

$pullRequestYml = @'
name: 'CI: pull request'

on:
  pull_request:
    branches: [main]
  workflow_dispatch:

jobs:
  pull_request_job:
    name: CI
    uses: Novolis-Platform/novolis-workflows/.github/workflows/dotnet-pull-request.yml@main
    secrets: inherit
'@

$releaseYml = @'
name: Release

on:
  release:
    types: [published]

permissions:
  contents: read
  id-token: write

jobs:
  publish:
    uses: Novolis-Platform/novolis-workflows/.github/workflows/dotnet-publish-nuget.yml@main
    secrets: inherit
'@

$ciYml = @'
name: CI

on:
  pull_request:
    branches: [main]

permissions:
  contents: read

jobs:
  ci:
    uses: Novolis-Platform/novolis-workflows/.github/workflows/dotnet-pull-request.yml@main
    secrets: inherit
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
    Write-Utf8 (Join-Path $repo '.github/workflows/merge.yml') $mergeYml
    Write-Utf8 (Join-Path $repo '.github/workflows/pull-request.yml') $pullRequestYml
    Write-Utf8 (Join-Path $repo '.github/workflows/release.yml') $releaseYml
    Write-Utf8 (Join-Path $repo '.github/workflows/ci.yml') $ciYml
}

Write-Host 'Done.'
