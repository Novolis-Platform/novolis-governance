#Requires -Version 7.0
# Configures Novolis package repos: PR/merge/release workflows, GPR on merge, build/version.json scheme.
$ErrorActionPreference = 'Stop'
$Root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$SyncScript = Join-Path $PSScriptRoot 'sync-version-props.ps1'
$GovVersionJson = Join-Path $PSScriptRoot '..\build\version.json'
$versionJsonTemplate = @'
{
  "year": 2026,
  "major": 1,
  "minor": 1,
  "dotnetBaseline": "net10.0",
  "publicPackage": true
}
'@
$versionJson = $versionJsonTemplate

$directoryBuildTargets = @'
<Project>
  <Import Project="$(MSBuildThisFileDirectory)..\novolis-governance\build\Novolis.Version.targets"
          Condition="Exists('$(MSBuildThisFileDirectory)..\novolis-governance\build\Novolis.Version.targets')" />
  <Import Project="$(MSBuildThisFileDirectory)..\novolis-governance\build\Novolis.Packaging.targets"
          Condition="Exists('$(MSBuildThisFileDirectory)..\novolis-governance\build\Novolis.Packaging.targets')" />
</Project>
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
    if ($text -match 'build\\version\.props') { return }
    $import = @"

  <Import Project="`$(MSBuildThisFileDirectory)build\version.props"
          Condition="Exists('`$(MSBuildThisFileDirectory)build\version.props')" />

"@
    $text = $text -replace '(<Project>\s*)', "`$1$import"
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
    $buildDir = Join-Path $repo 'build'
    New-Item -ItemType Directory -Force -Path $buildDir | Out-Null
    Write-Utf8 (Join-Path $buildDir 'version.json') $versionJson
    & $SyncScript -RepoPath $repo
    $old = Join-Path $repo '.novolis/version.props'
    if (Test-Path $old) { Remove-Item $old -Force }
    Write-Utf8 (Join-Path $repo 'Directory.Build.targets') $directoryBuildTargets
    Ensure-VersionImport $repo
    $nuget = Join-Path $repo 'nuget.config'
    if (-not (Test-Path $nuget) -and -not (Test-Path (Join-Path $repo 'NuGet.config'))) {
        Write-Utf8 $nuget $gprNugetConfig
    }
}

& (Join-Path $PSScriptRoot 'apply-pr-merge-release-workflows.ps1')
& (Join-Path $PSScriptRoot 'migrate-versioning-to-2026.ps1')
Write-Host 'Done.'
