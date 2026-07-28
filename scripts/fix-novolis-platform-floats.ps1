#Requires -Version 7.0
<#
.SYNOPSIS
  Rewrite Novolis PackageVersion entries to the platform float 2026.1.*.

.DESCRIPTION
  Updates novolis-*/Directory.Packages.props (and optional version.props float
  properties) so Novolis.* versions are 2026.1.* — never build-line floats
  (2026.1.N.*) or ad-hoc exact pins in central package management.

  Dry-run by default; pass -Apply to write files.

.PARAMETER Root
  Org checkout root (default NOVOLIS_ROOT or parent of governance).

.PARAMETER Apply
  Write changes (otherwise report only).

.PARAMETER IncludeExactPins
  Also rewrite exact four-segment Novolis pins (e.g. 2026.1.10.32) to 2026.1.*.

.EXAMPLE
  pwsh -File novolis-governance/scripts/fix-novolis-platform-floats.ps1
  pwsh -File novolis-governance/scripts/fix-novolis-platform-floats.ps1 -Apply -IncludeExactPins
#>
param(
    [string]$Root = '',
    [switch]$Apply,
    [switch]$IncludeExactPins
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'lib\Gpr.ps1')

if (-not $Root) {
    $Root = Get-NovolisRoot
}
if (-not (Test-Path $Root)) {
    throw "Root not found: $Root"
}

$platformFloat = '2026.1.*'
$buildLineRx = [regex]'(Include="Novolis\.[^"]+"\s+Version=")2026\.1\.\d+\.(\*)(")'
$exactPinRx = [regex]'(Include="Novolis\.[^"]+"\s+Version=")2026\.1\.\d+\.\d+(")'
$floatPropRx = [regex]'(<NovolisPackageFloatVersion>)2026\.1\.\d+\.\*(</NovolisPackageFloatVersion>)'

$changes = [System.Collections.Generic.List[object]]::new()

function Consider-File([string]$Path, [scriptblock]$Transform) {
    $original = Get-Content $Path -Raw
    $updated = & $Transform $original
    if ($updated -eq $original) { return }

    $rel = $Path.Substring($Root.Length).TrimStart('\', '/')
    $changes.Add([pscustomobject]@{ File = $rel; Action = if ($Apply) { 'updated' } else { 'would-update' } })

    if ($Apply) {
        Set-Content -Path $Path -Value $updated.TrimEnd() -Encoding utf8NoBOM
        Add-Content -Path $Path -Value '' -Encoding utf8NoBOM
    }
}

Get-ChildItem $Root -Directory -Filter 'novolis-*' | ForEach-Object {
    $props = Join-Path $_.FullName 'Directory.Packages.props'
    if (Test-Path $props) {
        Consider-File $props {
            param($text)
            $n = $buildLineRx.Replace($text, "`${1}$platformFloat`${3}")
            if ($IncludeExactPins) {
                $n = $exactPinRx.Replace($n, "`${1}$platformFloat`${2}")
            }
            $n
        }
    }

    $versionProps = Join-Path $_.FullName 'build\version.props'
    if (Test-Path $versionProps) {
        Consider-File $versionProps {
            param($text)
            $floatPropRx.Replace($text, "`${1}$platformFloat`${2}")
        }
    }

    # Template content may nest version.props deeper.
    Get-ChildItem $_.FullName -Recurse -Filter 'version.props' -File -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -notmatch '\\(obj|bin)\\' -and $_.FullName -ne $versionProps } |
        ForEach-Object {
            Consider-File $_.FullName {
                param($text)
                $floatPropRx.Replace($text, "`${1}$platformFloat`${2}")
            }
        }
}

if ($changes.Count -eq 0) {
    Write-Host 'fix-novolis-platform-floats: nothing to change' -ForegroundColor Green
    exit 0
}

Write-Host ("fix-novolis-platform-floats: {0} file(s) {1}" -f $changes.Count, $(if ($Apply) { 'updated' } else { 'would change (pass -Apply)' })) -ForegroundColor $(if ($Apply) { 'Green' } else { 'Yellow' })
$changes | Format-Table File, Action -AutoSize
if (-not $Apply) {
    Write-Host ''
    Write-Host 'Re-run with -Apply to write. Prefer -IncludeExactPins only when pins are not intentional.' -ForegroundColor Cyan
}
exit 0
