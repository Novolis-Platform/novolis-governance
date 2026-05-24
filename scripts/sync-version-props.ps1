#Requires -Version 7.0
# Regenerate build/version.props from build/version.json
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
$sdkYear = [int]$v.sdkYear
$apiBreak = [int]$v.apiBreak
$feature = [int]$v.feature
$stable = "$sdkYear.$apiBreak.$feature"
$float = "$sdkYear.$apiBreak.*"

$props = @"
<?xml version="1.0" encoding="utf-8"?>
<Project>
  <!-- Generated from build/version.json via scripts/sync-version-props.ps1 -->
  <PropertyGroup Label="Novolis platform version">
    <NovolisSdkYear>$sdkYear</NovolisSdkYear>
    <NovolisApiBreak>$apiBreak</NovolisApiBreak>
    <NovolisFeature>$feature</NovolisFeature>
    <NovolisStableVersion>$stable</NovolisStableVersion>
    <NovolisPackageFloatVersion>$float</NovolisPackageFloatVersion>
  </PropertyGroup>
</Project>
"@

$dir = Split-Path $propsPath -Parent
if (-not (Test-Path $dir)) {
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
}

Set-Content -Path $propsPath -Value $props.TrimEnd() -Encoding utf8NoBOM
Write-Host "Wrote $propsPath ($stable, float $float)"
