#Requires -Version 7.0
<#
.SYNOPSIS
  Lists org NuGet package visibility. Public visibility must be set in the GitHub UI (not REST/gh api).

.DESCRIPTION
  GitHub has NO REST endpoint to change NuGet package visibility:
    PATCH orgs/{org}/packages/nuget/{name}/visibility  -> 404

  Use the package settings UI (or browser automation):
    https://github.com/orgs/Novolis-Platform/packages/nuget/{PackageId}/settings
  Danger Zone -> Change visibility -> Public -> type package name -> confirm.

  See: set-org-nuget-packages-public-via-ui.md

.PARAMETER Org
  Organization login.

.PARAMETER ListOnly
  List packages grouped by visibility (default when no other switch is given).

.EXAMPLE
  .\set-org-nuget-packages-public.ps1 -ListOnly
#>
param(
    [string]$Org = 'Novolis-Platform',
    [switch]$ListOnly
)

$ErrorActionPreference = 'Stop'

if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    throw 'GitHub CLI (gh) is required.'
}

if (-not (gh auth status 2>&1 | Out-String).Contains('read:packages')) {
    Write-Host 'Tip: gh auth refresh -h github.com -s read:packages' -ForegroundColor Yellow
}

$page = 1
$all = [System.Collections.Generic.List[object]]::new()
do {
    $json = gh api "orgs/$Org/packages?package_type=nuget&per_page=100&page=$page"
    $packages = $json | ConvertFrom-Json
    if (-not $packages -or @($packages).Count -eq 0) { break }
    foreach ($pkg in $packages) {
        $all.Add([pscustomobject]@{
            Name       = $pkg.name
            Visibility = $pkg.visibility
            Settings   = "https://github.com/orgs/$Org/packages/nuget/$($pkg.name)/settings"
        })
    }
    $page++
} while (@($packages).Count -eq 100)

$private = @($all | Where-Object Visibility -ne 'public')
$public = @($all | Where-Object Visibility -eq 'public')

Write-Host "Org: $Org  public: $($public.Count)  not public: $($private.Count)" -ForegroundColor White

if ($private.Count -gt 0) {
    Write-Host ''
    Write-Host 'Packages not public (open Settings URL, Change visibility -> Public):' -ForegroundColor Yellow
    $private | Format-Table Name, Visibility, Settings -AutoSize
    Write-Host 'REST PATCH visibility is not supported for NuGet. Use the UI.' -ForegroundColor Cyan
    exit 1
}

Write-Host 'All NuGet packages are public.' -ForegroundColor Green
exit 0
