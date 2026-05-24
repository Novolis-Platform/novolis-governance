#Requires -Version 7.0
# One-time: set all org NuGet packages to public (needs gh auth with read:packages + write:packages).
param(
    [string]$Org = 'Novolis-Platform'
)

$ErrorActionPreference = 'Stop'

if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    throw 'GitHub CLI (gh) is required.'
}

$scopes = gh auth status 2>&1 | Out-String
if ($scopes -notmatch 'read:packages' -or $scopes -notmatch 'write:packages') {
    Write-Host 'Refreshing gh scopes: read:packages, write:packages' -ForegroundColor Yellow
    gh auth refresh -h github.com -s read:packages,write:packages
}

$page = 1
$updated = 0
do {
    $json = gh api "orgs/$Org/packages?package_type=nuget&per_page=100&page=$page" 2>&1
    if ($LASTEXITCODE -ne 0) { throw $json }
    $packages = $json | ConvertFrom-Json
    if (-not $packages -or $packages.Count -eq 0) { break }

    foreach ($pkg in $packages) {
        $name = $pkg.name
        if ($pkg.visibility -eq 'public') {
            Write-Host "Skip (already public): $name"
            continue
        }
        Write-Host "Public: $name"
        gh api -X PATCH "orgs/$Org/packages/nuget/$name/visibility" -f visibility=public 2>&1 | Out-Host
        if ($LASTEXITCODE -eq 0) { $updated++ }
    }
    $page++
} while ($packages.Count -eq 100)

Write-Host "Done. Updated $updated package(s)."
