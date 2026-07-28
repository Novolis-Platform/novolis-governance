#Requires -Version 7.0
<#
.SYNOPSIS
  One-shot GitHub Packages + NuGet dependency health check for Novolis.

.DESCRIPTION
  Runs:
    1. gpr-package-overview.ps1 (summary; always continues)
    2. gpr-find-junk-versions.ps1
    3. find-build-line-floats.ps1
    4. verify-nuget-only.ps1

  Exit non-zero if any check fails. Use after publish waves or when restore looks wrong.

.PARAMETER Org
  GitHub organization (default Novolis-Platform).

.PARAMETER SkipRemote
  Skip GitHub Packages API checks (local Directory.Packages / csproj only).

.PARAMETER SkipLocal
  Skip local checkout scans (GPR only).

.EXAMPLE
  pwsh -File novolis-governance/scripts/gpr-health-check.ps1
#>
param(
    [string]$Org = 'Novolis-Platform',
    [switch]$SkipRemote,
    [switch]$SkipLocal
)

$ErrorActionPreference = 'Stop'
$failed = [System.Collections.Generic.List[string]]::new()

function Invoke-Check {
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][string]$ScriptPath,
        [string[]]$Arguments = @()
    )

    Write-Host ''
    Write-Host "=== $Name ===" -ForegroundColor Cyan
    & $ScriptPath @Arguments
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

    Invoke-Check -Name 'gpr-find-junk-versions' -ScriptPath (Join-Path $scripts 'gpr-find-junk-versions.ps1') -Arguments @('-Org', $Org)
}

if (-not $SkipLocal) {
    Invoke-Check -Name 'find-build-line-floats' -ScriptPath (Join-Path $scripts 'find-build-line-floats.ps1')
    Invoke-Check -Name 'verify-nuget-only' -ScriptPath (Join-Path $scripts 'verify-nuget-only.ps1')
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
