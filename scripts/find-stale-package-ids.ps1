#Requires -Version 7.0
<#
.SYNOPSIS
  Find references to renamed/retired Novolis package ids.

.DESCRIPTION
  Scans Directory.Packages.props and *.csproj under novolis-* for package ids that
  were renamed or folded into another package. Update consumers before the old id
  disappears from GitHub Packages.

  Exit 1 when any hit is found.

.PARAMETER Root
  Org checkout root (default NOVOLIS_ROOT or parent of governance).

.PARAMETER ExtraIds
  Additional package ids to flag (exact match).

.EXAMPLE
  pwsh -File novolis-governance/scripts/find-stale-package-ids.ps1
#>
param(
    [string]$Root = '',
    [string[]]$ExtraIds = @()
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'lib\Gpr.ps1')

if (-not $Root) {
    $Root = Get-NovolisRoot
}
if (-not (Test-Path $Root)) {
    throw "Root not found: $Root"
}

# id -> replacement hint
$stale = [ordered]@{
    'Novolis.Audio.Host.NAudio'         = 'Novolis.Audio.Output.NAudio'
    'Novolis.Audio.Host.Abstractions'    = 'Novolis.Audio.Output.Abstractions'
    'Novolis.Audio.Live.Repl'           = 'Novolis.Audio.Live.Protocol (Repl types)'
    'Novolis.Audio.Analysis'            = 'Novolis.Audio.Live.Visuals'
    'Novolis.Audio.Live.Host'           = 'LiveStudio.Host in novolis-apps (not a package)'
}

foreach ($id in $ExtraIds) {
    if (-not $stale.Contains($id)) {
        $stale[$id] = '(custom)'
    }
}

$idPattern = ($stale.Keys | ForEach-Object { [regex]::Escape($_) }) -join '|'
$includeRx = [regex]"(?i)Include=`"(?<id>$idPattern)`""

$hits = [System.Collections.Generic.List[object]]::new()

function Scan-File([string]$Path) {
    $rel = $Path.Substring($Root.Length).TrimStart('\', '/')
    $lines = Get-Content $Path
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $m = $includeRx.Match($lines[$i])
        if (-not $m.Success) { continue }
        $id = $m.Groups['id'].Value
        $hits.Add([pscustomobject]@{
            File        = $rel
            Line        = $i + 1
            Package     = $id
            Replacement = $stale[$id]
        })
    }
}

Get-ChildItem $Root -Directory -Filter 'novolis-*' | ForEach-Object {
    $props = Join-Path $_.FullName 'Directory.Packages.props'
    if (Test-Path $props) {
        Scan-File $props
    }

    Get-ChildItem $_.FullName -Recurse -Filter '*.csproj' -File -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -notmatch '\\(obj|bin|artifacts)\\' } |
        ForEach-Object { Scan-File $_.FullName }
}

if ($hits.Count -eq 0) {
    Write-Host "find-stale-package-ids: OK (scanned $Root)" -ForegroundColor Green
    exit 0
}

Write-Host "Found $($hits.Count) stale package id reference(s):" -ForegroundColor Yellow
$hits | Format-Table File, Line, Package, Replacement -AutoSize
Write-Host ''
Write-Host 'See novolis-governance/docs/nuget-only-policy.md and gpr-maintenance.md' -ForegroundColor Cyan
exit 1
