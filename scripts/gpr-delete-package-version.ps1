#Requires -Version 7.0
<#
.SYNOPSIS
  Delete a specific NuGet package version from GitHub Packages.

.DESCRIPTION
  Looks up the version id for Package + Version and deletes it. Use after
  gpr-find-broken-deps.ps1 reports a poison latest version.

  Prefer -WhatIf first.

.PARAMETER Org
  GitHub organization (default Novolis-Platform).

.PARAMETER Package
  Exact package id (e.g. Novolis.Audio.Live.Protocol).

.PARAMETER Version
  Exact version string (e.g. 2026.1.10.36).

.PARAMETER WhatIf
  Show what would be deleted without calling DELETE.

.EXAMPLE
  pwsh -File novolis-governance/scripts/gpr-delete-package-version.ps1 -Package Novolis.Audio.Live.Protocol -Version 2026.1.10.36 -WhatIf
  pwsh -File novolis-governance/scripts/gpr-delete-package-version.ps1 -Package Novolis.Audio.Live.Protocol -Version 2026.1.10.36
#>
param(
    [string]$Org = 'Novolis-Platform',
    [Parameter(Mandatory)][string]$Package,
    [Parameter(Mandatory)][string]$Version,
    [switch]$WhatIf
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'lib\Gpr.ps1')

Assert-GhCli
$versions = @(Get-NovolisGprPackageVersions -Org $Org -PackageName $Package)
$match = @($versions | Where-Object { $_.name -eq $Version })
if ($match.Count -eq 0) {
    throw "Version not found: $Package $Version"
}

$v = $match[0]
$label = "$Package $Version (id=$($v.id))"
if ($WhatIf) {
    Write-Host "WhatIf: would delete $label" -ForegroundColor Yellow
    exit 0
}

gh api --method DELETE "orgs/$Org/packages/nuget/$Package/versions/$($v.id)"
if ($LASTEXITCODE -ne 0) {
    throw "Failed to delete $label"
}

Write-Host "Deleted $label" -ForegroundColor Green
exit 0
