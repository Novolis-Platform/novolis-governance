#Requires -Version 7.0
<#
.SYNOPSIS
  Shared helpers for Novolis GitHub Packages (GPR) NuGet maintenance scripts.
#>

# When this file is dot-sourced, $PSScriptRoot is .../scripts/lib.
$script:GprLibDir = $PSScriptRoot

function Assert-GhCli {
    if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
        throw 'GitHub CLI (gh) is required. Install from https://cli.github.com/'
    }
}

function Get-NovolisGprPackages {
    param(
        [Parameter(Mandatory)]
        [string]$Org
    )

    Assert-GhCli
    $all = [System.Collections.Generic.List[object]]::new()
    $page = 1
    do {
        $raw = gh api "orgs/$Org/packages?package_type=nuget&per_page=100&page=$page"
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to list packages for org $Org (page $page)."
        }
        $packages = $raw | ConvertFrom-Json
        if (-not $packages -or @($packages).Count -eq 0) { break }
        foreach ($pkg in @($packages)) {
            $all.Add($pkg)
        }
        $page++
    } while (@($packages).Count -eq 100)

    return $all
}

function Get-NovolisGprPackageVersions {
    param(
        [Parameter(Mandatory)]
        [string]$Org,
        [Parameter(Mandatory)]
        [string]$PackageName
    )

    Assert-GhCli
    $all = [System.Collections.Generic.List[object]]::new()
    $page = 1
    do {
        $raw = gh api "orgs/$Org/packages/nuget/$PackageName/versions?per_page=100&page=$page" 2>$null
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to list versions for $PackageName (page $page)."
        }
        $versions = $raw | ConvertFrom-Json
        if (-not $versions -or @($versions).Count -eq 0) { break }
        foreach ($v in @($versions)) {
            $all.Add($v)
        }
        $page++
    } while (@($versions).Count -eq 100)

    return $all
}

function Test-NovolisJunkPackageVersion {
    <#
    .SYNOPSIS
      Returns $true when a NuGet version is a known throwaway that poisons 2026.1.* floats.
    .DESCRIPTION
      Real Novolis CI versions are YEAR.MAJOR.MINOR.BUILD (four segments), e.g. 2026.1.6.53.
      Junk like 2026.1.99 or 2026.1.100 is three segments and sorts above legitimate builds
      under a platform-line float (2026.1.*).
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Version
    )

    if ($Version -eq '1.0.0') {
        return $true
    }

    # Explicit denylist for known throwaways.
    if ($Version -match '^2026\.1\.(99|100)(\.|$)') {
        return $true
    }

    # Three-segment 2026.1.N where N looks like a local/bootstrap stub (high "minor").
    if ($Version -match '^2026\.1\.(\d+)$') {
        $third = [int]$Matches[1]
        if ($third -ge 90) {
            return $true
        }
    }

    return $false
}

function Get-NovolisRoot {
    if ($env:NOVOLIS_ROOT) {
        return $env:NOVOLIS_ROOT
    }
    # lib -> scripts -> governance -> org checkout root
    $scripts = Split-Path $script:GprLibDir -Parent
    $governance = Split-Path $scripts -Parent
    return (Split-Path $governance -Parent)
}
