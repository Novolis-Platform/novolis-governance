#Requires -Version 7.0
# Migrate package repos to build/version.json + 2026.1.0 scheme.
$ErrorActionPreference = 'Stop'
$Root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$SyncScript = Join-Path $PSScriptRoot 'sync-version-props.ps1'
$GovVersionJson = Join-Path $PSScriptRoot '..\build\version.json'

$versionJson = Get-Content $GovVersionJson -Raw

$packageRepos = @(
    'novolis-analyzers', 'novolis-aspire', 'novolis-avalonia', 'novolis-codegen',
    'novolis-commands', 'novolis-install', 'novolis-machinelearning', 'novolis-markup',
    'novolis-math', 'novolis-messaging', 'novolis-physics', 'novolis-raylib',
    'novolis-rendering', 'novolis-security', 'novolis-simulation', 'novolis-smoketest',
    'novolis-storage', 'novolis-template-dotnet', 'novolis-templates', 'novolis-testing',
    'novolis-transports', 'novolis-wirefish'
)

function Write-Utf8([string]$Path, [string]$Content) {
    $dir = Split-Path $Path -Parent
    if ($dir) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    Set-Content -Path $Path -Value $Content.TrimEnd() -Encoding utf8NoBOM
}

function Update-VersionImport([string]$PropsPath) {
    if (-not (Test-Path $PropsPath)) { return }
    $text = Get-Content $PropsPath -Raw
    $newImport = @'
  <Import Project="$(MSBuildThisFileDirectory)build\version.props"
          Condition="Exists('$(MSBuildThisFileDirectory)build\version.props')" />

'@
    if ($text -match 'build\\version\.props') { return }

    if ($text -match '\.novolis\\version\.props') {
        $text = $text -replace '(?s)\s*<Import Project="\$\(MSBuildThisFileDirectory\)\.novolis\\version\.props"[^/]*/>\s*', "`n$newImport"
    }
    elseif ($text -match '<Project>\s*') {
        $text = $text -replace '(<Project>\s*)', "`$1`n$newImport"
    }
    else { return }

    Write-Utf8 $PropsPath $text
}

function Update-DirectoryPackages([string]$DpPath) {
    if (-not (Test-Path $DpPath)) { return }
    $text = Get-Content $DpPath -Raw
    $changed = $false

    if ($text -notmatch 'CentralPackageFloatingVersionsEnabled') {
        if ($text -match '<ManagePackageVersionsCentrally>true</ManagePackageVersionsCentrally>') {
            $text = $text -replace '(<ManagePackageVersionsCentrally>true</ManagePackageVersionsCentrally>)', "`$1`n    <CentralPackageFloatingVersionsEnabled>true</CentralPackageFloatingVersionsEnabled>"
        }
        elseif ($text -match '<PropertyGroup>') {
            $text = $text -replace '(<PropertyGroup>\s*)', "`$1`n    <ManagePackageVersionsCentrally>true</ManagePackageVersionsCentrally>`n    <CentralPackageFloatingVersionsEnabled>true</CentralPackageFloatingVersionsEnabled>`n"
        }
        $changed = $true
    }

    if ($text -notmatch 'build\\version\.props' -and $text -match 'Novolis\.') {
        $import = @'
  <Import Project="build\version.props" Condition="Exists('build\version.props')" />

'@
        $text = $text -replace '(<Project>\s*)', "`$1$import"
        $changed = $true
    }

    $n = $text
    $n = $n -replace '(Include="Novolis\.[^"]+"\s+Version=")0\.[0-9.]+[^"]*(")', '${1}2026.1.*${2}'
    $n = $n -replace '(Include="Novolis\.[^"]+"\s+Version=")\*(")', '${1}2026.1.*${2}'
    if ($n -ne $text) { $text = $n; $changed = $true }

    $n = $text -replace 'Version="\$\(NovolisPackageFloatVersion\)"', 'Version="2026.1.*"'
    if ($n -ne $text) { $text = $n; $changed = $true }

    if ($changed) { Write-Utf8 $DpPath $text }
}

foreach ($name in $packageRepos) {
    $repo = Join-Path $Root $name
    if (-not (Test-Path $repo)) {
        Write-Warning "Skip missing: $name"
        continue
    }

    Write-Host "Migrate $name"
    $buildDir = Join-Path $repo 'build'
    New-Item -ItemType Directory -Force -Path $buildDir | Out-Null
    Write-Utf8 (Join-Path $buildDir 'version.json') $versionJson
    & $SyncScript -RepoPath $repo

    $old = Join-Path $repo '.novolis/version.props'
    if (Test-Path $old) { Remove-Item $old -Force }

    Update-VersionImport (Join-Path $repo 'Directory.Build.props')
    Update-DirectoryPackages (Join-Path $repo 'Directory.Packages.props')
}

# Dogfooding
$dog = Join-Path $Root 'novolis-dogfooding'
if (Test-Path $dog) {
    Write-Host 'Migrate novolis-dogfooding'
    Update-DirectoryPackages (Join-Path $dog 'Directory.Packages.props')
}

Write-Host 'Done.'
