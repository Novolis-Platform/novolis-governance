#Requires -Version 7.0
# Migrate build/version.json to YEAR.MAJOR.MINOR schema (minor=1) and refresh version.props + floating refs.
$ErrorActionPreference = 'Stop'
$Root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$SyncScript = Join-Path $PSScriptRoot 'sync-version-props.ps1'
$Template = @'
{
  "year": 2026,
  "major": 1,
  "minor": 1,
  "dotnetBaseline": "net10.0",
  "publicPackage": true
}
'@

function Write-Utf8([string]$Path, [string]$Content) {
    $dir = Split-Path $Path -Parent
    if ($dir) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    Set-Content -Path $Path -Value $Content.TrimEnd() -Encoding utf8NoBOM
}

$repos = Get-ChildItem $Root -Directory -Filter 'novolis-*' |
    Where-Object { $_.Name -notmatch 'workflows|governance|registry|dogfooding|installer' }

foreach ($repo in $repos) {
    $buildDir = Join-Path $repo.FullName 'build'
    if (-not (Test-Path $buildDir)) { continue }
    Write-Host $repo.Name
    Write-Utf8 (Join-Path $buildDir 'version.json') $Template
    & $SyncScript -RepoPath $repo.FullName

    $dp = Join-Path $repo.FullName 'Directory.Packages.props'
    if (Test-Path $dp) {
        $t = Get-Content $dp -Raw
        $n = $t -replace '(Include="Novolis\.[^"]+"\s+Version=")2026\.[0-9.]+[^"]*(")', '${1}2026.1.1.*${2}'
        if ($n -ne $t) { Write-Utf8 $dp $n }
    }
}

$dog = Join-Path $Root 'novolis-dogfooding\Directory.Packages.props'
if (Test-Path $dog) {
    $t = Get-Content $dog -Raw
    $n = $t -replace '(Include="Novolis\.[^"]+"\s+Version=")2026\.[0-9.]+[^"]*(")', '${1}2026.1.1.*${2}'
    if ($n -ne $t) { Write-Utf8 $dog $n; Write-Host 'novolis-dogfooding' }
}

Write-Host 'Done.'
