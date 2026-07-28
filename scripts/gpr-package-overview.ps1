#Requires -Version 7.0
<#
.SYNOPSIS
  Overview of Novolis org NuGet packages on GitHub Packages.

.DESCRIPTION
  Lists each package with latest version, repository link (or missing), visibility,
  and whether the latest version looks like junk that would poison 2026.1.* floats.

.PARAMETER Org
  GitHub organization (default Novolis-Platform).

.PARAMETER UnlinkedOnly
  Only show packages with no linked repository.

.PARAMETER JunkLatestOnly
  Only show packages whose latest version is junk.

.EXAMPLE
  pwsh -File novolis-governance/scripts/gpr-package-overview.ps1

.EXAMPLE
  pwsh -File novolis-governance/scripts/gpr-package-overview.ps1 -UnlinkedOnly
#>
param(
    [string]$Org = 'Novolis-Platform',
    [switch]$UnlinkedOnly,
    [switch]$JunkLatestOnly
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'lib\Gpr.ps1')

$packages = Get-NovolisGprPackages -Org $Org
$rows = [System.Collections.Generic.List[object]]::new()

foreach ($pkg in $packages) {
    $versions = @(Get-NovolisGprPackageVersions -Org $Org -PackageName $pkg.name)
    $latest = if ($versions.Count -gt 0) { $versions[0].name } else { $null }
    $repo = $pkg.repository.full_name
    $junkLatest = if ($latest) { Test-NovolisJunkPackageVersion -Version $latest } else { $false }
    $junkCount = @($versions | Where-Object { Test-NovolisJunkPackageVersion -Version $_.name }).Count

    $row = [pscustomobject]@{
        Package      = $pkg.name
        Latest       = $latest
        Versions     = $versions.Count
        JunkVersions = $junkCount
        JunkLatest   = $junkLatest
        Repository   = if ($repo) { $repo } else { '(none)' }
        Linked       = [bool]$repo
        Visibility   = $pkg.visibility
        Url          = "https://github.com/orgs/$Org/packages/nuget/$($pkg.name)"
    }

    if ($UnlinkedOnly -and $row.Linked) { continue }
    if ($JunkLatestOnly -and -not $row.JunkLatest) { continue }
    $rows.Add($row)
}

$linked = @($rows | Where-Object Linked).Count
$unlinked = @($rows | Where-Object { -not $_.Linked }).Count
$junkLatest = @($rows | Where-Object JunkLatest).Count
$withJunk = @($rows | Where-Object { $_.JunkVersions -gt 0 }).Count

Write-Host "Org: $Org  packages: $($rows.Count)  linked: $linked  unlinked: $unlinked  junk-latest: $junkLatest  with-junk: $withJunk" -ForegroundColor White
Write-Host ''
$rows |
    Sort-Object Package |
    Format-Table Package, Latest, Versions, JunkVersions, Repository, Visibility -AutoSize

if ($unlinked -gt 0 -or $junkLatest -gt 0 -or $withJunk -gt 0) {
    exit 1
}

exit 0
