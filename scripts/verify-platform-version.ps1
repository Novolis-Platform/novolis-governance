#Requires -Version 7.0
<#
.SYNOPSIS
  Fails if build/version.json is not on the platform line YEAR.1.1 (default 2026.1.1).

.DESCRIPTION
  The second segment is MAJOR (breaking API generation), not a calendar "year.2" line.
  Platform packages must stay on major=1, minor=1 until governance approves a deliberate bump.

.PARAMETER RepoPath
  Root of a novolis-* repository.

.PARAMETER ExpectedYear
  Default 2026.

.PARAMETER ExpectedMajor
  Default 1 (breaking API generation — must not become 2 without explicit approval).

.PARAMETER ExpectedMinor
  Default 1 (release line on the 2026.1 platform).
#>
param(
    [Parameter(Mandatory = $true)]
    [string] $RepoPath,

    [int] $ExpectedYear = 2026,
    [int] $ExpectedMajor = 1,
    [int] $ExpectedMinor = 1
)

$ErrorActionPreference = 'Stop'
$RepoPath = (Resolve-Path $RepoPath).Path
$jsonPath = Join-Path $RepoPath 'build/version.json'

if (-not (Test-Path $jsonPath)) {
    Write-Error "Missing $jsonPath"
}

$v = Get-Content $jsonPath -Raw | ConvertFrom-Json
$year = [int]($v.year ?? $v.sdkYear)
$major = [int]($v.major ?? $v.apiBreak)
$minor = [int]($v.minor ?? $v.feature)

$failures = [System.Collections.Generic.List[string]]::new()

if ($year -ne $ExpectedYear) {
    $failures.Add("year=$year (expected $ExpectedYear)")
}
if ($major -ne $ExpectedMajor) {
    $failures.Add("major=$major (expected $ExpectedMajor — a value of 2 would publish 2026.2.* and is forbidden without approval)")
}
if ($minor -ne $ExpectedMinor) {
    $failures.Add("minor=$minor (expected $ExpectedMinor)")
}

$propsPath = Join-Path $RepoPath 'build/version.props'
if (Test-Path $propsPath) {
    $propsText = Get-Content $propsPath -Raw
    $expectedPlatform = "$ExpectedYear.$ExpectedMajor.$ExpectedMinor"
    if ($propsText -notmatch "<NovolisPlatformVersion>$expectedPlatform</NovolisPlatformVersion>") {
        $failures.Add("build/version.props NovolisPlatformVersion does not match $expectedPlatform")
    }
    $expectedFloat = "$ExpectedYear.$ExpectedMajor.*"
    if ($propsText -notmatch "<NovolisPackageFloatVersion>$expectedFloat</NovolisPackageFloatVersion>") {
        $failures.Add("build/version.props NovolisPackageFloatVersion does not match $expectedFloat")
    }
}

if ($failures.Count -gt 0) {
    Write-Error "Platform version mismatch in $RepoPath : $($failures -join '; ')"
}

$platform = "$year.$major.$minor"
Write-Host "OK $([IO.Path]::GetFileName($RepoPath)) platform line $platform (GPR: ${platform}.BUILD)"
