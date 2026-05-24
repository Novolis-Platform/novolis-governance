#Requires -Version 7.0
# Regenerate build/version.props from build/version.json (YEAR.MAJOR.MINOR; BUILD from CI).
param(
    [string]$RepoPath = '.'
)

$ErrorActionPreference = 'Stop'
$RepoPath = Resolve-Path $RepoPath
$jsonPath = Join-Path $RepoPath 'build/version.json'
$propsPath = Join-Path $RepoPath 'build/version.props'

if (-not (Test-Path $jsonPath)) {
    throw "Missing $jsonPath"
}

$v = Get-Content $jsonPath -Raw | ConvertFrom-Json
$year = [int]($v.year ?? $v.sdkYear)
$major = [int]($v.major ?? $v.apiBreak)
$minor = [int]($v.minor ?? $v.feature)
$platform = "$year.$major.$minor"
# Match any BUILD on this YEAR.MAJOR line (e.g. 2026.1.0.42 and 2026.1.1.366).
$float = "$year.$major.*"

$props = @"
<?xml version="1.0" encoding="utf-8"?>
<Project>
  <!-- Generated from build/version.json via scripts/sync-version-props.ps1 -->
  <PropertyGroup Label="Novolis platform version (YEAR.MAJOR.MINOR; BUILD from CI)">
    <NovolisYear>$year</NovolisYear>
    <NovolisMajor>$major</NovolisMajor>
    <NovolisMinor>$minor</NovolisMinor>
    <NovolisPlatformVersion>$platform</NovolisPlatformVersion>
    <NovolisPackageFloatVersion>$float</NovolisPackageFloatVersion>
    <NovolisLocalBuild Condition="'`$(NovolisLocalBuild)' == ''">1</NovolisLocalBuild>
  </PropertyGroup>
</Project>
"@

$dir = Split-Path $propsPath -Parent
if (-not (Test-Path $dir)) {
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
}

Set-Content -Path $propsPath -Value $props.TrimEnd() -Encoding utf8NoBOM
Write-Host "Wrote $propsPath ($platform, float $float)"
