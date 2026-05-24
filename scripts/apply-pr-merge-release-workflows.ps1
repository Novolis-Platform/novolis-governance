#Requires -Version 7.0
# Thin repo workflows calling shared definitions in novolis-workflows.
$ErrorActionPreference = 'Stop'
$Root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$Uses = 'Novolis-Platform/novolis-workflows/.github/workflows'

$pullRequestYml = @"
name: Pull request
on:
  pull_request:
    branches: [main]
jobs:
  ci:
    uses: $Uses/dotnet-pull-request.yml@main
"@

$mergeYml = @"
name: Merge
on:
  push:
    branches: [main]
    paths-ignore:
      - '.novolis/version.props'
      - 'docs/**'
      - '**.md'
  workflow_dispatch:
    inputs:
      skip_publish:
        type: boolean
        default: false
jobs:
  ci:
    uses: $Uses/dotnet-merge-publish.yml@main
    with:
      skip_publish: `${{ inputs.skip_publish == true }}
    permissions:
      contents: write
      packages: write
"@

$releaseYml = @"
name: Release
on:
  release:
    types: [published]
jobs:
  ci:
    uses: $Uses/dotnet-release-publish.yml@main
    secrets:
      NUGET_API_KEY: `${{ secrets.NUGET_API_KEY }}
    permissions:
      contents: write
"@

$raylibPullRequestYml = @"
name: Pull request
on:
  pull_request:
    branches: [main]
jobs:
  ci:
    uses: $Uses/dotnet-raylib-pull-request.yml@main
"@

$raylibMergeYml = @"
name: Merge
on:
  push:
    branches: [main]
    paths-ignore:
      - '.novolis/version.props'
      - 'docs/**'
      - '**.md'
  workflow_dispatch:
    inputs:
      skip_publish:
        type: boolean
        default: false
jobs:
  ci:
    uses: $Uses/dotnet-raylib-merge-publish.yml@main
    with:
      skip_publish: `${{ inputs.skip_publish == true }}
    permissions:
      contents: write
      packages: write
"@

function Write-Utf8([string]$Path, [string]$Content) {
    $dir = Split-Path $Path -Parent
    if ($dir) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    Set-Content -Path $Path -Value $Content.TrimEnd() -Encoding utf8NoBOM
}

function Remove-WorkflowExtras([string]$RepoPath) {
    foreach ($name in @('ci.yml', 'set-packages-public.yml', 'republish-public.yml')) {
        $p = Join-Path $RepoPath ".github/workflows/$name"
        if (Test-Path $p) { Remove-Item $p -Force; Write-Host "  removed $name" }
    }
}

$packageRepos = @(
    'novolis-analyzers', 'novolis-aspire', 'novolis-avalonia', 'novolis-codegen',
    'novolis-commands', 'novolis-install', 'novolis-machinelearning', 'novolis-markup',
    'novolis-math', 'novolis-messaging', 'novolis-physics', 'novolis-rendering',
    'novolis-security', 'novolis-simulation', 'novolis-smoketest', 'novolis-storage',
    'novolis-template-dotnet', 'novolis-templates', 'novolis-testing',
    'novolis-transports', 'novolis-wirefish'
)

foreach ($name in $packageRepos) {
    $repo = Join-Path $Root $name
    if (-not (Test-Path $repo)) { continue }
    Write-Host "Workflows: $name"
    $wf = Join-Path $repo '.github/workflows'
    Write-Utf8 (Join-Path $wf 'pull-request.yml') $pullRequestYml
    Write-Utf8 (Join-Path $wf 'merge.yml') $mergeYml
    Write-Utf8 (Join-Path $wf 'release.yml') $releaseYml
    Remove-WorkflowExtras $repo
}

$raylib = Join-Path $Root 'novolis-raylib'
if (Test-Path $raylib) {
    Write-Host 'Workflows: novolis-raylib'
    $wf = Join-Path $raylib '.github/workflows'
    Write-Utf8 (Join-Path $wf 'pull-request.yml') $raylibPullRequestYml
    Write-Utf8 (Join-Path $wf 'merge.yml') $raylibMergeYml
    Write-Utf8 (Join-Path $wf 'release.yml') $releaseYml
    Remove-WorkflowExtras $raylib
}

$dog = Join-Path $Root 'novolis-dogfooding'
if (Test-Path $dog) {
    Write-Host 'Workflows: novolis-dogfooding (no CI — consumes published packages only)'
    $wf = Join-Path $dog '.github/workflows'
    if (Test-Path $wf) {
        Get-ChildItem $wf -Filter '*.yml' -ErrorAction SilentlyContinue | Remove-Item -Force
        if (-not (Get-ChildItem $wf -ErrorAction SilentlyContinue)) { Remove-Item $wf -Force -ErrorAction SilentlyContinue }
    }
    Remove-WorkflowExtras $dog
}

$templateWf = Join-Path $Root 'novolis-templates/src/Novolis.Templates/content/Novolis.Templates.GitHubSolution/.github/workflows'
if (Test-Path $templateWf) {
    Write-Host 'Workflows: Novolis.Templates.GitHubSolution'
    Write-Utf8 (Join-Path $templateWf 'pull-request.yml') $pullRequestYml
    Write-Utf8 (Join-Path $templateWf 'merge.yml') $mergeYml
    Write-Utf8 (Join-Path $templateWf 'release.yml') $releaseYml
    $ci = Join-Path $templateWf 'ci.yml'
    if (Test-Path $ci) { Remove-Item $ci -Force }
}

Write-Host 'Done.'
