#Requires -Version 7.0
<#
.SYNOPSIS
  Find published NuGet versions whose Novolis dependencies are missing from GPR.

.DESCRIPTION
  For each org package (or -Package filter), inspects the latest version's nuspec.
  If a Novolis.* dependency version is not present on GitHub Packages, the package
  version is reported as broken — this is the "Live.Protocol required LocalIpc
  2026.1.10.36" class of restore poison under 2026.1.* floats.

  Exit 1 when any broken dependency is found.

.PARAMETER Org
  GitHub organization (default Novolis-Platform).

.PARAMETER Package
  Optional exact package id to inspect (default: all).

.PARAMETER MaxPackages
  Cap how many packages to inspect (0 = all). Useful for smoke checks.

.EXAMPLE
  pwsh -File novolis-governance/scripts/gpr-find-broken-deps.ps1
  pwsh -File novolis-governance/scripts/gpr-find-broken-deps.ps1 -Package Novolis.Audio.Live.Protocol
#>
param(
    [string]$Org = 'Novolis-Platform',
    [string]$Package = '',
    [int]$MaxPackages = 0
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'lib\Gpr.ps1')

Assert-GhCli
$token = (gh auth token 2>$null)
if (-not $token) {
    throw 'gh auth token failed. Run: gh auth login'
}

Write-Host "Loading package inventory for $Org..." -ForegroundColor Cyan
$packages = @(Get-NovolisGprPackages -Org $Org)
if ($Package) {
    $packages = @($packages | Where-Object { $_.name -eq $Package })
    if ($packages.Count -eq 0) {
        throw "Package not found: $Package"
    }
}
elseif ($MaxPackages -gt 0 -and $packages.Count -gt $MaxPackages) {
    $packages = @($packages | Select-Object -First $MaxPackages)
}

# versionIndex[packageName] = HashSet of version strings
$versionIndex = @{}
Write-Host "Indexing versions ($($packages.Count) packages)..." -ForegroundColor Cyan
foreach ($pkg in $packages) {
    $versions = @(Get-NovolisGprPackageVersions -Org $Org -PackageName $pkg.name)
    $set = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach ($v in $versions) {
        [void]$set.Add($v.name)
    }
    $versionIndex[$pkg.name] = @{
        Versions = $set
        Latest   = if ($versions.Count -gt 0) { $versions[0].name } else { $null }
        VersionObjects = $versions
    }
}

# Also index remaining org packages we may depend on but skipped via -MaxPackages/-Package
function Ensure-PackageIndexed([string]$Id) {
    if ($versionIndex.ContainsKey($Id)) { return }
    try {
        $versions = @(Get-NovolisGprPackageVersions -Org $Org -PackageName $Id)
    }
    catch {
        $versionIndex[$Id] = @{
            Versions = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
            Latest   = $null
            VersionObjects = @()
        }
        return
    }
    $set = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach ($v in $versions) {
        [void]$set.Add($v.name)
    }
    $versionIndex[$Id] = @{
        Versions = $set
        Latest   = if ($versions.Count -gt 0) { $versions[0].name } else { $null }
        VersionObjects = $versions
    }
}

function Get-NuspecText {
    param(
        [string]$PackageId,
        [string]$Version
    )

    $tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("gpr-nuspec-{0}-{1}" -f $PackageId, [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $tmp | Out-Null
    try {
        $nupkg = Join-Path $tmp "$PackageId.$Version.nupkg"
        $url = "https://nuget.pkg.github.com/$Org/download/$PackageId/$Version/$PackageId.$Version.nupkg"
        $headers = @{
            Authorization = "Bearer $token"
            Accept        = 'application/octet-stream'
        }
        try {
            Invoke-WebRequest -Uri $url -Headers $headers -OutFile $nupkg -UseBasicParsing
        }
        catch {
            return $null
        }

        $extract = Join-Path $tmp 'extract'
        Expand-Archive -Path $nupkg -DestinationPath $extract -Force
        $nuspec = Get-ChildItem -Path $extract -Filter '*.nuspec' -Recurse | Select-Object -First 1
        if (-not $nuspec) { return $null }
        return (Get-Content $nuspec.FullName -Raw)
    }
    finally {
        Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
    }
}

$depRx = [regex]'<dependency\s+id="(?<id>Novolis\.[^"]+)"\s+version="(?<ver>[^"]+)"'
$hits = [System.Collections.Generic.List[object]]::new()
$inspected = 0

foreach ($pkg in $packages) {
    $meta = $versionIndex[$pkg.name]
    $latest = $meta.Latest
    if (-not $latest) { continue }

    $nuspec = Get-NuspecText -PackageId $pkg.name -Version $latest
    $inspected++
    if (-not $nuspec) {
        Write-Host "WARN: could not download $pkg.name $latest" -ForegroundColor DarkYellow
        continue
    }

    foreach ($m in $depRx.Matches($nuspec)) {
        $depId = $m.Groups['id'].Value
        $depVer = $m.Groups['ver'].Value
        # Ignore floating dependency ranges in nuspec (rare for packed Novolis pkgs).
        if ($depVer.Contains('*') -or $depVer.Contains('[') -or $depVer.Contains('(')) {
            continue
        }

        Ensure-PackageIndexed $depId
        $depSet = $versionIndex[$depId].Versions
        if (-not $depSet.Contains($depVer)) {
            $hits.Add([pscustomobject]@{
                Package        = $pkg.name
                PackageVersion = $latest
                Dependency     = $depId
                Required       = $depVer
                AvailableLatest = $versionIndex[$depId].Latest
            })
        }
    }

    if (($inspected % 25) -eq 0) {
        Write-Host "  inspected $inspected / $($packages.Count)..." -ForegroundColor DarkGray
    }
}

if ($hits.Count -eq 0) {
    Write-Host "gpr-find-broken-deps: OK ($inspected package latest version(s) inspected)" -ForegroundColor Green
    exit 0
}

Write-Host "Found $($hits.Count) broken Novolis dependency edge(s) on latest versions:" -ForegroundColor Yellow
$hits | Sort-Object Package, Dependency | Format-Table Package, PackageVersion, Dependency, Required, AvailableLatest -AutoSize
Write-Host ''
Write-Host 'These versions poison 2026.1.* floats. Delete the broken package version from GPR' -ForegroundColor Cyan
Write-Host '(GitHub Packages UI or API) and republish a good build, or publish the missing dependency version.'
Write-Host "Example delete:"
Write-Host '  gh api --method DELETE orgs/ORG/packages/nuget/PACKAGE/versions/VERSION_ID'
exit 1
