#Requires -Version 7.0
<#
.SYNOPSIS
  Find throwaway NuGet versions on GitHub Packages that poison 2026.1.* floats.

.DESCRIPTION
  Scans every org NuGet package for junk versions (1.0.0, 2026.1.99, 2026.1.100,
  and other three-segment 2026.1.N stubs with N >= 90).

  Exit 1 when any junk version is found. Use gpr-remove-junk-versions.ps1 to delete.

.PARAMETER Org
  GitHub organization (default Novolis-Platform).

.EXAMPLE
  pwsh -File novolis-governance/scripts/gpr-find-junk-versions.ps1
#>
param(
    [string]$Org = 'Novolis-Platform'
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'lib\Gpr.ps1')

$packages = Get-NovolisGprPackages -Org $Org
$hits = [System.Collections.Generic.List[object]]::new()

foreach ($pkg in $packages) {
    $versions = Get-NovolisGprPackageVersions -Org $Org -PackageName $pkg.name
    foreach ($v in $versions) {
        if (Test-NovolisJunkPackageVersion -Version $v.name) {
            $hits.Add([pscustomobject]@{
                Package    = $pkg.name
                Version    = $v.name
                VersionId  = $v.id
                Repository = if ($pkg.repository.full_name) { $pkg.repository.full_name } else { '(none)' }
                CreatedAt  = $v.created_at
            })
        }
    }
}

if ($hits.Count -eq 0) {
    Write-Host "gpr-find-junk-versions: OK (no junk versions in $Org)" -ForegroundColor Green
    exit 0
}

Write-Host "Found $($hits.Count) junk version(s) that can poison 2026.1.* floats:" -ForegroundColor Yellow
$hits | Sort-Object Package, Version | Format-Table Package, Version, Repository, CreatedAt -AutoSize
Write-Host ''
Write-Host 'Remove with:' -ForegroundColor Cyan
Write-Host "  pwsh -File $PSScriptRoot\gpr-remove-junk-versions.ps1 -WhatIf"
Write-Host "  pwsh -File $PSScriptRoot\gpr-remove-junk-versions.ps1"
exit 1
