#Requires -Version 7.0
<#
.SYNOPSIS
  One-shot GitHub Packages + NuGet dependency health check for Novolis.

.DESCRIPTION
  Runs:
    Remote (unless -SkipRemote):
      1. gpr-package-overview.ps1 (report; soft)
      2. gpr-find-junk-versions.ps1
      3. gpr-find-broken-deps.ps1 (only with -CheckBrokenDeps; slow)
    Local (unless -SkipLocal):
      4. find-build-line-floats.ps1
      5. find-local-nuget-feeds.ps1
      6. find-stale-package-ids.ps1
      7. verify-nuget-only.ps1
      8. verify-project-ref-mode.ps1 (-SkipBuild for speed in health check)
      9. verify-layer-boundaries.ps1 (Avalonia isolation + spine PackageReferences)
  Exit non-zero if any hard check fails. Use after publish waves or when restore looks wrong.

.PARAMETER Org
  GitHub organization (default Novolis-Platform).

.PARAMETER SkipRemote
  Skip GitHub Packages API checks (local Directory.Packages / csproj only).

.PARAMETER SkipLocal
  Skip local checkout scans (GPR only).

.PARAMETER CheckBrokenDeps
  Also download latest nuspecs and verify Novolis dependency versions exist on GPR.
  Slow on a full org inventory; prefer targeting with gpr-find-broken-deps.ps1 -Package.

.EXAMPLE
  pwsh -File novolis-governance/scripts/gpr-health-check.ps1
  pwsh -File novolis-governance/scripts/gpr-health-check.ps1 -SkipRemote
  pwsh -File novolis-governance/scripts/gpr-health-check.ps1 -CheckBrokenDeps
#>
param(
    [string]$Org = 'Novolis-Platform',
    [switch]$SkipRemote,
    [switch]$SkipLocal,
    [switch]$CheckBrokenDeps
)

$ErrorActionPreference = 'Stop'
$failed = [System.Collections.Generic.List[string]]::new()

function Invoke-Check {
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][string]$ScriptPath,
        [hashtable]$ArgumentTable = @{}
    )

    Write-Host ''
    Write-Host "=== $Name ===" -ForegroundColor Cyan
    & $ScriptPath @ArgumentTable
    $code = $LASTEXITCODE
    if ($code -ne 0) {
        $failed.Add("$Name (exit $code)")
        Write-Host "FAIL: $Name" -ForegroundColor Red
    }
    else {
        Write-Host "PASS: $Name" -ForegroundColor Green
    }
}

$scripts = $PSScriptRoot

if (-not $SkipRemote) {
    # Overview exits 1 when issues exist; still useful as a report — capture but treat junk as the hard fail.
    Write-Host ''
    Write-Host '=== gpr-package-overview ===' -ForegroundColor Cyan
    & (Join-Path $scripts 'gpr-package-overview.ps1') -Org $Org
    if ($LASTEXITCODE -ne 0) {
        Write-Host 'Overview reported issues (see table above).' -ForegroundColor Yellow
    }
    else {
        Write-Host 'PASS: gpr-package-overview' -ForegroundColor Green
    }

    # Hashtable splat — string arrays would bind "-Org" as the Org *value*.
    Invoke-Check -Name 'gpr-find-junk-versions' -ScriptPath (Join-Path $scripts 'gpr-find-junk-versions.ps1') -ArgumentTable @{ Org = $Org }

    if ($CheckBrokenDeps) {
        Invoke-Check -Name 'gpr-find-broken-deps' -ScriptPath (Join-Path $scripts 'gpr-find-broken-deps.ps1') -ArgumentTable @{ Org = $Org }
    }
}

if (-not $SkipLocal) {
    Invoke-Check -Name 'find-build-line-floats' -ScriptPath (Join-Path $scripts 'find-build-line-floats.ps1')
    Invoke-Check -Name 'find-local-nuget-feeds' -ScriptPath (Join-Path $scripts 'find-local-nuget-feeds.ps1')
    Invoke-Check -Name 'find-stale-package-ids' -ScriptPath (Join-Path $scripts 'find-stale-package-ids.ps1')
    Invoke-Check -Name 'verify-nuget-only' -ScriptPath (Join-Path $scripts 'verify-nuget-only.ps1')
    Invoke-Check -Name 'verify-project-ref-mode' -ScriptPath (Join-Path $scripts 'verify-project-ref-mode.ps1') -ArgumentTable @{ SkipBuild = $true }
    Invoke-Check -Name 'verify-layer-boundaries' -ScriptPath (Join-Path $scripts 'verify-layer-boundaries.ps1')
}

Write-Host ''
if ($failed.Count -gt 0) {
    Write-Host "gpr-health-check: FAILED ($($failed.Count))" -ForegroundColor Red
    foreach ($f in $failed) {
        Write-Host "  - $f"
    }
    Write-Host ''
    Write-Host 'Runbook: novolis-governance/docs/gpr-maintenance.md' -ForegroundColor Cyan
    exit 1
}

Write-Host 'gpr-health-check: OK' -ForegroundColor Green
exit 0
