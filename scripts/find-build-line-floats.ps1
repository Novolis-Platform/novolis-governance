#Requires -Version 7.0
<#
.SYNOPSIS
  Find Novolis PackageVersion floats that are not on the platform line.

.DESCRIPTION
  Scans novolis-*/Directory.Packages.props for Version="2026.1.N.*" (build-line floats)
  and other risky patterns. Platform-line floats (2026.1.*) and exact pins are OK.

  Exit 1 when build-line floats are found.

.PARAMETER Root
  Org checkout root (default NOVOLIS_ROOT or parent of governance).

.EXAMPLE
  pwsh -File novolis-governance/scripts/find-build-line-floats.ps1
#>
param(
    [string]$Root = ''
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'lib\Gpr.ps1')

if (-not $Root) {
    $Root = Get-NovolisRoot
}
if (-not (Test-Path $Root)) {
    throw "Root not found: $Root"
}

# Build-line float: 2026.1.10.* or 2026.1.1.* (third segment fixed, fourth is *).
$buildLineFloat = [regex]'Version\s*=\s*"(?<ver>2026\.1\.\d+\.\*)"'

$hits = [System.Collections.Generic.List[object]]::new()

Get-ChildItem $Root -Directory -Filter 'novolis-*' | ForEach-Object {
    $props = Join-Path $_.FullName 'Directory.Packages.props'
    if (-not (Test-Path $props)) { return }

    $relProps = $props.Substring($Root.Length).TrimStart('\', '/')
    $lines = Get-Content $props
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        if ($line -notmatch 'PackageVersion' -or $line -notmatch 'Novolis\.') { continue }

        $pkg = if ($line -match 'Include="(?<id>[^"]+)"') { $Matches['id'] } else { '(unknown)' }

        if ($buildLineFloat.IsMatch($line)) {
            $m = $buildLineFloat.Match($line)
            $hits.Add([pscustomobject]@{
                File    = $relProps
                Line    = $i + 1
                Package = $pkg
                Version = $m.Groups['ver'].Value
                Kind    = 'build-line-float'
            })
        }
    }
}

if ($hits.Count -eq 0) {
    Write-Host "find-build-line-floats: OK (scanned $Root)" -ForegroundColor Green
    exit 0
}

Write-Host "Found $($hits.Count) build-line float(s). Prefer 2026.1.* or an exact published pin:" -ForegroundColor Yellow
$hits | Format-Table File, Line, Package, Version, Kind -AutoSize
Write-Host ''
Write-Host 'See novolis-governance/docs/nuget-only-policy.md' -ForegroundColor Cyan
exit 1
