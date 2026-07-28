#Requires -Version 7.0
<#
.SYNOPSIS
  Find forbidden local NuGet folder feeds in nuget.config files.

.DESCRIPTION
  Scans the org checkout (and optionally the workspace root nuget.config) for
  sources such as novolis-local, artifacts/nuget-local, or NOVOLIS_LOCAL_FEED.
  Those feeds violate nuget-only policy and poison restores vs GitHub Packages.

  Exit 1 when any hit is found.

.PARAMETER Root
  Org checkout root (default NOVOLIS_ROOT or parent of governance).

.EXAMPLE
  pwsh -File novolis-governance/scripts/find-local-nuget-feeds.ps1
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

$forbidden = [regex]'(?i)novolis-local|nuget-local|NOVOLIS_LOCAL_FEED|artifacts[/\\]+nuget'
$hits = [System.Collections.Generic.List[object]]::new()

$configs = [System.Collections.Generic.List[string]]::new()
$rootConfig = Join-Path $Root 'nuget.config'
if (Test-Path $rootConfig) {
    $configs.Add($rootConfig)
}

Get-ChildItem $Root -Directory -Filter 'novolis-*' | ForEach-Object {
    Get-ChildItem $_.FullName -Recurse -Include 'nuget.config', 'NuGet.config' -File -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -notmatch '\\(obj|bin|artifacts)\\' } |
        ForEach-Object { $configs.Add($_.FullName) }
}

foreach ($path in ($configs | Select-Object -Unique)) {
    $lines = Get-Content $path
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($forbidden.IsMatch($lines[$i])) {
            $rel = $path.Substring($Root.Length).TrimStart('\', '/')
            $hits.Add([pscustomobject]@{
                File = $rel
                Line = $i + 1
                Text = $lines[$i].Trim()
            })
        }
    }
}

if ($hits.Count -eq 0) {
    Write-Host "find-local-nuget-feeds: OK (scanned $Root)" -ForegroundColor Green
    exit 0
}

Write-Host "Found $($hits.Count) local NuGet feed reference(s). Remove them (nuget.org + github only):" -ForegroundColor Yellow
$hits | Format-Table File, Line, Text -AutoSize
Write-Host ''
Write-Host 'See novolis-governance/docs/nuget-only-policy.md' -ForegroundColor Cyan
exit 1
