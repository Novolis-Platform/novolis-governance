#Requires -Version 7.0
<#
.SYNOPSIS
  Delete throwaway NuGet versions from GitHub Packages.

.DESCRIPTION
  Deletes versions identified by Test-NovolisJunkPackageVersion (same rules as
  gpr-find-junk-versions.ps1). Prefer -WhatIf first.

  WARNING: If a package only has junk versions, deleting them removes the package
  from the org feed. Republish from the owning repo's Merge workflow afterward.

.PARAMETER Org
  GitHub organization (default Novolis-Platform).

.PARAMETER WhatIf
  List deletions without calling the API.

.PARAMETER Package
  Optional package id filter (exact match).

.EXAMPLE
  pwsh -File novolis-governance/scripts/gpr-remove-junk-versions.ps1 -WhatIf

.EXAMPLE
  pwsh -File novolis-governance/scripts/gpr-remove-junk-versions.ps1
#>
param(
    [string]$Org = 'Novolis-Platform',
    [string]$Package = '',
    [switch]$WhatIf
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'lib\Gpr.ps1')

$packages = Get-NovolisGprPackages -Org $Org
if ($Package) {
    $packages = @($packages | Where-Object { $_.name -eq $Package })
    if ($packages.Count -eq 0) {
        throw "Package not found in org feed: $Package"
    }
}

$deleted = 0
$failed = 0

foreach ($pkg in $packages) {
    $versions = Get-NovolisGprPackageVersions -Org $Org -PackageName $pkg.name
    $junk = @($versions | Where-Object { Test-NovolisJunkPackageVersion -Version $_.name })
    if ($junk.Count -eq 0) { continue }

    $remaining = $versions.Count - $junk.Count
    if ($remaining -eq 0) {
        Write-Host "WARN: $($pkg.name) only has junk versions — delete removes the package from the feed." -ForegroundColor Yellow
    }

    foreach ($v in $junk) {
        $label = "$($pkg.name) $($v.name) (id=$($v.id))"
        if ($WhatIf) {
            Write-Host "WhatIf: would delete $label"
            $deleted++
            continue
        }

        Write-Host "DELETE $label"
        gh api -X DELETE "orgs/$Org/packages/nuget/$($pkg.name)/versions/$($v.id)"
        if ($LASTEXITCODE -ne 0) {
            Write-Host "FAILED $label" -ForegroundColor Red
            $failed++
        }
        else {
            $deleted++
        }
    }
}

if ($WhatIf) {
    Write-Host "WhatIf: $deleted junk version(s) would be deleted." -ForegroundColor Cyan
}
else {
    Write-Host "Deleted: $deleted  Failed: $failed"
}

if ($failed -gt 0) { exit 1 }
exit 0
