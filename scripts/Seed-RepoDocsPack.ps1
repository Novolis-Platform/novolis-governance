#Requires -Version 7.0
<#
.SYNOPSIS
  Seeds the policy docs pack (docs/README + getting-started/design/release) for Novolis repos
  and refreshes root README marketing headers with a Docs site link.

.DESCRIPTION
  Does not overwrite existing docs files. Reads marketing metadata from
  .github/site/repo-catalog.json (or Upgrade-RepoMarketingReadmes catalog defaults).

.PARAMETER WorkspaceRoot
  Parent of novolis-* checkouts.

.PARAMETER GitHubBrandRoot
  Path to Novolis-Platform/.github checkout.

.PARAMETER CommitPush
  When set, commits and pushes each changed repo on main.

.PARAMETER OverwriteThin
  Replace existing docs that are empty stubs ("Reserved for future content",
  tiny templates, wrong template-dotnet README copy, or Novolis.Example placeholders).

.PARAMETER SkipMarketing
  Skip rewriting the root README marketing header.
#>
param(
    [string] $WorkspaceRoot = '',
    [string] $GitHubBrandRoot = '',
    [switch] $CommitPush,
    [switch] $OverwriteThin,
    [switch] $SkipMarketing,
    [string[]] $OnlyRepos = @()
)

$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$governanceRoot = (Resolve-Path (Join-Path $scriptDir '..')).Path
if (-not $WorkspaceRoot) {
    $WorkspaceRoot = (Resolve-Path (Join-Path $governanceRoot '..')).Path
}
if (-not $GitHubBrandRoot) {
    $GitHubBrandRoot = Join-Path $WorkspaceRoot '.github'
}
$GitHubBrandRoot = (Resolve-Path $GitHubBrandRoot).Path
$org = 'Novolis-Platform'
$docsSiteRoot = "https://$($org.ToLowerInvariant()).github.io/.github"

$catalogPath = Join-Path $GitHubBrandRoot 'site\repo-catalog.json'
if (-not (Test-Path -LiteralPath $catalogPath)) {
    throw "Missing catalog: $catalogPath — run Upgrade-RepoMarketingReadmes.ps1 first."
}
$catalog = Get-Content -LiteralPath $catalogPath -Raw | ConvertFrom-Json

$skipLocalOnly = @('novolis-experimental', 'novolis-logging', 'novolis-mapping', 'novolis-scheduling', 'novolis-wirefish')

function Get-RepoMeta([string]$name) {
    $entry = $catalog.$name
    if ($null -eq $entry) {
        return [pscustomobject]@{
            tag    = 'Novolis ecosystem library'
            blurb  = "Part of the Novolis platform ($name)."
            desc   = "Novolis ecosystem repository: $name"
            topics = @('dotnet', 'novolis')
        }
    }
    return $entry
}

function Get-DocsSiteUrl([string]$repoName) {
    if ($repoName -eq '.github') { return "$docsSiteRoot/" }
    return "$docsSiteRoot/$repoName/"
}

function Test-IsThinDoc {
    param(
        [string] $Path,
        [ValidateSet('readme', 'getting-started', 'design', 'release')]
        [string] $Kind,
        [string] $RepoName
    )
    if (-not (Test-Path -LiteralPath $Path)) { return $true }
    if (-not $OverwriteThin) { return $false }

    $text = Get-Content -LiteralPath $Path -Raw
    $len = (Get-Item -LiteralPath $Path).Length
    if ($text -match '(?i)Reserved for future content') { return $true }
    if ($len -lt 200) { return $true }
    if ($Kind -eq 'getting-started' -and $text -match 'dotnet add package Novolis\.Example') { return $true }
    if ($Kind -eq 'readme' -and $RepoName -ne 'novolis-template-dotnet' -and
        $text -match 'Canonical starter pack for new Novolis') { return $true }
    if ($Kind -eq 'readme' -and $RepoName -ne 'novolis-template-dotnet' -and
        $text -match 'novolis-template-dotnet/') { return $true }
    return $false
}

function Get-LayerHint([string]$RepoName) {
    switch -Regex ($RepoName) {
        '^novolis-math' { return 'Closed spine: **Math** (bottom). No Physics/Simulation/Raylib/Avalonia references.' }
        '^novolis-physics' { return 'Closed spine: **Physics** over Math. No cameras, Raylib, or Avalonia.' }
        '^novolis-simulation' { return 'Closed spine: **Simulation** over Physics/Math. Cameras and world clocks live here.' }
        '^novolis-gaming' { return 'Closed spine: **Gaming** (`Novolis.Game.*`) over Simulation. No Avalonia in this layer.' }
        '^novolis-avalonia' { return '**Avalonia** layer only (`Novolis.Avalonia.*`). Sole libraries allowed to take Avalonia package refs.' }
        '^novolis-raylib' { return '**Raylib** island — never references Simulation; apps wire Raylib + Simulation.' }
        '^novolis-documents|^novolis-markup|^novolis-manuscript' { return 'Documents/Markup island — Avalonia hosts may call PDF/HTML helpers; do not pull Avalonia into these packages.' }
        '^novolis-cad|^novolis-ship' { return 'CAD / ship domain DTOs and validation — Avalonia-free; UI chrome lives in `Novolis.Avalonia.*`. Mesh scene graphs live in `Novolis.3D.*` (novolis-avalonia).' }
        '^novolis-os' { return 'Runtime images / appliances — not a NuGet library spine package.' }
        '^novolis-governance|^\.github|^novolis-workflows|^novolis-registry|^novolis-template' { return 'Org / template / CI infrastructure — not a closed-spine library.' }
        default { return 'Follow [library-boundaries](https://github.com/Novolis-Platform/novolis-governance/blob/main/docs/library-boundaries.md) for layer placement.' }
    }
}

function Get-PackablePackages([string]$repoRoot) {
    $pkgs = [System.Collections.Generic.List[string]]::new()
    foreach ($dirName in @('src', 'codegen')) {
        $root = Join-Path $repoRoot $dirName
        if (-not (Test-Path -LiteralPath $root)) { continue }
        foreach ($csproj in Get-ChildItem -LiteralPath $root -Recurse -Filter '*.csproj' -ErrorAction SilentlyContinue) {
            [xml]$xml = Get-Content $csproj.FullName -Raw
            $id = $null
            foreach ($pg in @($xml.Project.PropertyGroup)) {
                if ($null -eq $pg) { continue }
                if ($pg.PackageId) { $id = [string]$pg.PackageId; break }
            }
            if (-not $id) { $id = $csproj.BaseName }
            $isPackable = $true
            foreach ($pg in @($xml.Project.PropertyGroup)) {
                if ($null -eq $pg) { continue }
                if ("$($pg.IsPackable)" -eq 'false') { $isPackable = $false; break }
            }
            if ($isPackable -and $id -like 'Novolis.*') {
                if (-not $pkgs.Contains($id)) { $pkgs.Add($id) }
            }
        }
    }
    return @($pkgs | Sort-Object)
}

function New-DocsReadme {
    param(
        [string]$RepoName,
        [object]$Meta,
        [string[]]$ExistingDocs,
        [string[]]$Packages
    )
    $site = Get-DocsSiteUrl $RepoName
    $title = if ($RepoName -eq '.github') { 'Novolis platform docs' } else { "$RepoName documentation" }
    $lines = [System.Collections.Generic.List[string]]::new()
    $lines.Add("# $title")
    $lines.Add('')
    $lines.Add($Meta.blurb)
    $lines.Add('')
    $lines.Add("Published docs: [$site]($site)")
    $lines.Add('')
    $lines.Add('## Guides')
    $lines.Add('')
    $lines.Add('| Doc | What it covers |')
    $lines.Add('| --- | --- |')
    $lines.Add('| [getting-started.md](getting-started.md) | Install, restore from GitHub Packages, first use |')
    $lines.Add('| [design.md](design.md) | Goals, layer placement, non-goals |')
    $lines.Add('| [release.md](release.md) | CalVer publish and package list |')
    $extra = @($ExistingDocs | Where-Object {
            $_ -notin @('README.md', 'getting-started.md', 'design.md', 'release.md') -and $_ -notlike '*/*'
        } | Sort-Object)
    foreach ($doc in $extra) {
        $label = [System.IO.Path]::GetFileNameWithoutExtension($doc)
        $lines.Add("| [$doc]($doc) | $label |")
    }
    $lines.Add('')
    if ($Packages.Count -gt 0) {
        $lines.Add('## Packages')
        $lines.Add('')
        $lines.Add('| Package |')
        $lines.Add('| --- |')
        foreach ($pkg in $Packages) {
            $lines.Add("| ``$pkg`` |")
        }
        $lines.Add('')
    }
    $lines.Add('## More')
    $lines.Add('')
    $lines.Add("- [Org docs catalog]($docsSiteRoot/)")
    $lines.Add("- [Repository README](../README.md)")
    $lines.Add("- [Governance](https://github.com/$org/novolis-governance)")
    $lines.Add('')
    return ($lines -join "`n")
}

function New-GettingStarted {
    param([string]$RepoName, [object]$Meta, [string[]]$Packages)
    $site = Get-DocsSiteUrl $RepoName
    $sample = if ($Packages.Count -gt 0) { $Packages[0] } else { 'Novolis.Example' }
    @"
# Getting started

$($Meta.blurb)

Published guide: [$site]($site)

## Prerequisites

- [.NET 10 SDK](https://dotnet.microsoft.com/download)
- GitHub Packages auth for ``Novolis.*`` (see [nuget-only-policy](https://github.com/$org/novolis-governance/blob/main/docs/nuget-only-policy.md))

Configure GPR once from a sibling ``novolis-governance`` checkout:

``````powershell
pwsh -File d:\novolis\novolis-governance\scripts\configure-gpr-user-nuget.ps1
``````

## Install

``````bash
dotnet add package $sample
``````

Local multi-repo iteration uses ProjectReference mode via ``d:\novolis\Novolis.Platform.slnx`` — never a local NuGet folder feed.

## Next

- [design.md](design.md) — layer placement and non-goals
- [release.md](release.md) — publish cadence
- [Org docs catalog]($docsSiteRoot/)
"@ -replace '``````', '```'
}

function New-DesignDoc {
    param([string]$RepoName, [object]$Meta, [string[]]$Packages)
    $site = Get-DocsSiteUrl $RepoName
    $layer = Get-LayerHint $RepoName
    $pkgList = if ($Packages.Count -gt 0) {
        (@($Packages | ForEach-Object { "- ``$_``" }) -join "`n")
    } else {
        '- (no packable ``Novolis.*`` projects detected in ``src/`` / ``codegen/``)'
    }
    @"
# Design

$($Meta.blurb)

Published docs: [$site]($site)

## Layer placement

$layer

## Goals

- Keep public APIs documented and packable as ``Novolis.*`` on GitHub Packages (when applicable).
- Prefer BCL types and existing Novolis packages over parallel abstractions.
- Document restore and ProjectReference-mode builds without local NuGet folder feeds.

## Non-goals

- Local NuGet folder feeds or committed cross-repo ``ProjectReference`` into sibling checkouts.
- Avalonia package references outside ``Novolis.Avalonia.*``.
- Upward spine dependencies (e.g. Math → Simulation).

## Packages

$pkgList

## Topics

$((@($Meta.topics) | ForEach-Object { "- ``$_``" }) -join "`n")
"@
}

function New-ReleaseDoc {
    param([string]$RepoName, [string[]]$Packages)
    $site = Get-DocsSiteUrl $RepoName
    $pkgList = if ($Packages.Count -gt 0) {
        (@($Packages | ForEach-Object { "- ``$_``" }) -join "`n")
    } else {
        '- (no packable ``Novolis.*`` projects detected — see repository README)'
    }
    @"
# Release

This repository publishes with the org CalVer scheme (``2026.1.*``) via ``merge.yml`` to GitHub Packages when packages are packable.

See [release-policy](https://github.com/$org/novolis-governance/blob/main/docs/release-policy.md).

Published docs: [$site]($site)

## Packages

$pkgList

## Consumers

Restore from nuget.org + ``https://nuget.pkg.github.com/$org/index.json`` only.

Local multi-repo iteration: open ``d:\novolis\Novolis.Platform.slnx`` (ProjectReference mode) — do not add a local feed.
"@
}

function Update-MarketingHeader {
    param([string]$RepoRoot, [string]$RepoName, [object]$Meta)
    $readmePath = Join-Path $RepoRoot 'README.md'
    $site = Get-DocsSiteUrl $RepoName
    $bannerName = if ($RepoName -eq '.github') { 'github-org' } else { $RepoName }
    $bannerUrl = "https://raw.githubusercontent.com/$org/.github/main/brand/banners/$bannerName.svg"
    $brandLogoUrl = "https://raw.githubusercontent.com/$org/.github/main/brand/logo-brand-transparent.svg"
    $tag = [string]$Meta.tag
    $blurb = [string]$Meta.blurb
    $mergeImg = "https://img.shields.io/github/actions/workflow/status/$org/$RepoName/merge.yml?branch=main&label=merge&logo=github"
    $pkgImg = "https://img.shields.io/badge/packages-GitHub%20Packages-0a7ea3?logo=nuget"
    $docsImg = "https://img.shields.io/badge/docs-portfolio-0a7ea3"
    $orgImg = "https://img.shields.io/badge/org-Novolis--Platform-111827"

    $header = @"
<!-- novolis-marketing:start -->
<p align="center">
  <a href="https://github.com/$org">
    <img src="$brandLogoUrl" width="360" alt="Novolis"/>
  </a>
</p>

<p align="center">
  <img src="$bannerUrl" width="100%" alt="$RepoName"/>
</p>

<p align="center">
  <strong>$tag</strong><br/>
  $blurb
</p>

<p align="center">
  <a href="$site"><img src="$docsImg" alt="docs"/></a>
  <a href="https://github.com/$org/$RepoName/actions"><img src="$mergeImg" alt="merge"/></a>
  <a href="https://github.com/orgs/$org/packages?repo_name=$RepoName"><img src="$pkgImg" alt="packages"/></a>
  <a href="https://github.com/$org"><img src="$orgImg" alt="org"/></a>
</p>

<p align="center">
  <a href="$site">Docs</a>
  ·
  <a href="https://nuget.pkg.github.com/$org/index.json"><code>https://nuget.pkg.github.com/$org/index.json</code></a>
  ·
  <a href="https://github.com/$org/.github/blob/main/profile/README.md">Org landing</a>
  ·
  <a href="https://github.com/$org/novolis-governance">Governance</a>
</p>

---
<!-- novolis-marketing:end -->

"@

    if (-not (Test-Path -LiteralPath $readmePath)) {
        $seed = @"
$header
# $RepoName

$blurb

## Documentation

- [Docs site]($site)
- [Getting started](docs/getting-started.md)
"@
        Set-Content -LiteralPath $readmePath -Value $seed -Encoding utf8NoBOM
        return $true
    }

    $body = Get-Content -LiteralPath $readmePath -Raw
    $changed = $false
    if ($body -match '(?s)<!-- novolis-marketing:start -->.*?<!-- novolis-marketing:end -->\s*') {
        $body = $body -replace '(?s)<!-- novolis-marketing:start -->.*?<!-- novolis-marketing:end -->\s*', $header
        $changed = $true
    }
    else {
        $body = $header + $body.TrimStart()
        $changed = $true
    }

    # Ensure a Docs site link exists somewhere in the README body (outside marketing block is fine).
    if ($body -notmatch [regex]::Escape($site)) {
        $docsBlock = @"

## Documentation

- [Docs site]($site) — rendered guides from ``docs/``
- [getting-started.md](docs/getting-started.md)
- [design.md](docs/design.md)
- [release.md](docs/release.md)

"@
        if ($body -match '(?s)(<!-- novolis-marketing:end -->\s*---\s*)') {
            $body = $body -replace '(?s)(<!-- novolis-marketing:end -->\s*)', "`$1$docsBlock"
        }
        else {
            $body = $body.TrimEnd() + "`n" + $docsBlock
        }
        $changed = $true
    }

    if ($changed) {
        Set-Content -LiteralPath $readmePath -Value ($body.TrimEnd() + "`n") -Encoding utf8NoBOM
    }
    return $changed
}

$stats = [ordered]@{ Repos = 0; Readme = 0; GettingStarted = 0; Design = 0; Release = 0; Marketing = 0; Pushed = 0 }

$repoDirs = @(Get-ChildItem -LiteralPath $WorkspaceRoot -Directory | Where-Object {
        ($_.Name -like 'novolis-*' -or $_.Name -eq '.github') -and ($_.Name -notin $skipLocalOnly)
    })

if ($OnlyRepos.Count -gt 0) {
    $repoDirs = @($repoDirs | Where-Object { $_.Name -in $OnlyRepos })
}

foreach ($dir in ($repoDirs | Sort-Object Name)) {
    $name = $dir.Name
    if (-not ($catalog.PSObject.Properties.Name -contains $name) -and $name -ne '.github') {
        # Still seed public checkouts that appear on the org even if catalog is stale.
        $remote = gh repo view "$org/$name" --json isArchived -q .isArchived 2>$null
        if ($LASTEXITCODE -ne 0) { continue }
        if ("$remote" -eq 'true') { continue }
    }

    $meta = Get-RepoMeta $name
    $docsDir = Join-Path $dir.FullName 'docs'
    New-Item -ItemType Directory -Force -Path $docsDir | Out-Null

    $packages = @(Get-PackablePackages $dir.FullName)
    $existing = @(Get-ChildItem -LiteralPath $docsDir -Filter '*.md' -File -ErrorAction SilentlyContinue | ForEach-Object Name)

    Write-Host "==> $name"

    $readmePath = Join-Path $docsDir 'README.md'
    if (Test-IsThinDoc -Path $readmePath -Kind readme -RepoName $name) {
        Set-Content -LiteralPath $readmePath -Value (New-DocsReadme -RepoName $name -Meta $meta -ExistingDocs $existing -Packages $packages) -Encoding utf8NoBOM
        $stats.Readme++
        Write-Host '  + docs/README.md'
    }

    $gs = Join-Path $docsDir 'getting-started.md'
    if (Test-IsThinDoc -Path $gs -Kind getting-started -RepoName $name) {
        Set-Content -LiteralPath $gs -Value (New-GettingStarted -RepoName $name -Meta $meta -Packages $packages) -Encoding utf8NoBOM
        $stats.GettingStarted++
        Write-Host '  + docs/getting-started.md'
    }

    $design = Join-Path $docsDir 'design.md'
    if (Test-IsThinDoc -Path $design -Kind design -RepoName $name) {
        Set-Content -LiteralPath $design -Value (New-DesignDoc -RepoName $name -Meta $meta -Packages $packages) -Encoding utf8NoBOM
        $stats.Design++
        Write-Host '  + docs/design.md'
    }

    $release = Join-Path $docsDir 'release.md'
    if (Test-IsThinDoc -Path $release -Kind release -RepoName $name) {
        Set-Content -LiteralPath $release -Value (New-ReleaseDoc -RepoName $name -Packages $packages) -Encoding utf8NoBOM
        $stats.Release++
        Write-Host '  + docs/release.md'
    }

    if (-not $SkipMarketing) {
        if (Update-MarketingHeader -RepoRoot $dir.FullName -RepoName $name -Meta $meta) {
            $stats.Marketing++
            Write-Host '  ~ README marketing / Docs link'
        }
    }

    $stats.Repos++

    if ($CommitPush) {
        Push-Location $dir.FullName
        try {
            if (-not (Test-Path -LiteralPath (Join-Path $dir.FullName '.git'))) {
                Write-Warning "  skip push (not a git repo)"
                continue
            }
            git add docs README.md 2>$null
            $pending = git status --porcelain -- docs README.md
            if (-not $pending) {
                Write-Host '  (no git changes)'
                continue
            }
            $msg = @"
Seed docs pack and link the org docs site.

Add missing docs/README + policy guides when absent, and point the README at https://novolis-platform.github.io/.github/$name/.
"@
            if ($name -eq '.github') {
                $msg = @"
Seed docs pack and link the org docs site.

Add missing docs/README + policy guides when absent, and point the README at the portfolio docs home.
"@
            }
            git commit -m $msg
            if ($LASTEXITCODE -ne 0) {
                Write-Warning "  commit failed"
                continue
            }
            git push origin HEAD
            if ($LASTEXITCODE -ne 0) {
                Write-Warning "  push failed"
                continue
            }
            $stats.Pushed++
            Write-Host '  pushed'
        }
        finally {
            Pop-Location
        }
    }
}

Write-Host ''
Write-Host "Done. Repos=$($stats.Repos) docsREADME=$($stats.Readme) gettingStarted=$($stats.GettingStarted) design=$($stats.Design) release=$($stats.Release) marketing=$($stats.Marketing) pushed=$($stats.Pushed)"
