#Requires -Version 7.0
<#
.SYNOPSIS
  Upgrades Novolis repo + package READMEs with brand heroes, badges, and package indexes.
  Also writes per-repo SVG banners into the .github brand folder and can refresh GitHub descriptions/topics.
.PARAMETER WorkspaceRoot
  Parent folder that contains novolis-* checkouts (default: parent of this repo).
.PARAMETER GitHubBrandRoot
  Path to the Novolis-Platform/.github checkout (brand assets live here).
.PARAMETER ApplyGitHubMeta
  When set, updates GitHub repository description + topics via `gh`.
.PARAMETER SkipBanners
  Skip regenerating SVG banners under brand/banners/.
#>
param(
    [string] $WorkspaceRoot = '',
    [string] $GitHubBrandRoot = '',
    [switch] $ApplyGitHubMeta,
    [switch] $SkipBanners
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
$bannerDir = Join-Path $GitHubBrandRoot 'brand\banners'
New-Item -ItemType Directory -Force -Path $bannerDir | Out-Null

$org = 'Novolis-Platform'
$brandLogoUrl = "https://raw.githubusercontent.com/$org/.github/main/brand/logo-brand-transparent.svg"
$brandIconUrl = "https://raw.githubusercontent.com/$org/.github/main/brand/logo-icon.svg"
$socialPngUrl = "https://raw.githubusercontent.com/$org/.github/main/brand/generated/logo-social.png"

# Tagline, short blurb (for README), GitHub description, topics
$catalog = @{
    'novolis-agent'           = @{ Tag = 'Live agent surfaces'; Blurb = 'Control surfaces for live apps — Core, Surface, and Testing helpers.'; Desc = 'Live agent control surfaces for running Novolis apps (Core, Surface, Testing).'; Topics = @('dotnet','agents','novolis') }
    'novolis-analyzers'       = @{ Tag = 'Roslyn that enforces the platform'; Blurb = 'Roslyn analyzers for stack boundaries, AutoMapper, and code-length discipline.'; Desc = 'Roslyn analyzers for Novolis stack boundaries and code quality.'; Topics = @('dotnet','roslyn','analyzers','novolis') }
    'novolis-apps'            = @{ Tag = 'Desktop products on NuGet only'; Blurb = 'Production Avalonia apps and installers composed entirely from Novolis packages.'; Desc = 'Desktop apps and installers built on Novolis NuGet packages (Avalonia studios + games).'; Topics = @('dotnet','avalonia','desktop','novolis') }
    'novolis-aspire'          = @{ Tag = 'Aspire hosting extensions'; Blurb = 'Aspire hosting helpers (e.g. Signoz) for Novolis distributed apps.'; Desc = 'Aspire hosting extensions for the Novolis ecosystem.'; Topics = @('dotnet','aspire','observability','novolis') }
    'novolis-astro'           = @{ Tag = 'Stars, catalogs, assessment'; Blurb = 'Astronomical catalog, assessment, and related libraries for space sims.'; Desc = '.NET astronomy / catalog libraries for Novolis space simulations.'; Topics = @('dotnet','astronomy','simulation','novolis') }
    'novolis-audio'           = @{ Tag = 'SFX, voice, and live music'; Blurb = 'Cross-platform audio: miniaudio SFX, TTS voice stacks, and live music runtime.'; Desc = 'Cross-platform .NET audio — miniaudio SFX, TTS/voice, and live music.'; Topics = @('dotnet','audio','tts','miniaudio','novolis') }
    'novolis-avalonia'        = @{ Tag = 'UI chrome for the platform'; Blurb = 'Avalonia controls and shells for CAD, gaming, agents, video, and mobile.'; Desc = 'Avalonia UI libraries for Novolis apps (CAD, gaming, agents, video, mobile).'; Topics = @('dotnet','avalonia','ui','novolis') }
    'novolis-cad'             = @{ Tag = 'CAD interchange without UI'; Blurb = 'Avalonia-free CAD primitives and interchange (.cadjson / .cadphys).'; Desc = 'CAD interchange primitives (.cadjson / .cadphys) — Avalonia-free DTOs for Novolis.'; Topics = @('dotnet','cad','novolis') }
    'novolis-civics'          = @{ Tag = 'Civic agents and firm bridges'; Blurb = 'Civics agents, core ledgers, and economy bridges for polity sims.'; Desc = 'Civics simulation libraries for Novolis — agents, core, and economy bridges.'; Topics = @('dotnet','simulation','civics','novolis') }
    'novolis-codegen'         = @{ Tag = 'Bindings pipelines that scale'; Blurb = 'Codegen pipeline, reflection, and binding generators used across the platform.'; Desc = 'Code generation pipelines and binding generators for Novolis native stacks.'; Topics = @('dotnet','codegen','novolis') }
    'novolis-documents'       = @{ Tag = 'One-column pages to Skia PDF'; Blurb = 'Immutable document blocks, layout, and Skia PDF — not HTML-to-PDF.'; Desc = 'Paged document model and Skia PDF layout for Novolis (one-column flow).'; Topics = @('dotnet','pdf','documents','novolis') }
    'novolis-commands'        = @{ Tag = 'Interrupt-aware command queues'; Blurb = 'Parse prompts into command envelopes, queue them, run with cancellation.'; Desc = 'Command envelopes, queues, and interrupt-aware execution for Novolis.'; Topics = @('dotnet','commands','novolis') }
    'novolis-dogfooding'      = @{ Tag = 'Integration labs that prove the stack'; Blurb = 'Dogfood apps and labs that exercise Novolis packages end-to-end.'; Desc = 'Integration labs and dogfood apps for the Novolis platform.'; Topics = @('dotnet','samples','novolis') }
    'novolis-economy'         = @{ Tag = 'Deterministic markets and firms'; Blurb = 'Headless economic simulation — supply chains, markets, accounting, logistics.'; Desc = 'Headless deterministic economic simulation libraries for Novolis.'; Topics = @('dotnet','economy','simulation','novolis') }
    # novolis-experimental is local-only (copyrighted IP) — never market or push to GitHub
    'novolis-gaming'          = @{ Tag = 'Game authoring above simulation'; Blurb = 'Game identity, humanoids, menu flows, packaging — no Avalonia in this layer.'; Desc = 'Game authoring libraries for Novolis (identity, humanoids, packaging).'; Topics = @('dotnet','gamedev','novolis') }
    'novolis-geopolitics'     = @{ Tag = 'Full-world geopolitics engines'; Blurb = 'Homage geopolitics simulation libraries; GeoPolity hosts live in novolis-apps.'; Desc = 'Full-world geopolitics simulation libraries for Novolis (homage only).'; Topics = @('dotnet','geopolitics','simulation','novolis') }
    'novolis-governance'      = @{ Tag = 'Policies that keep the org coherent'; Blurb = 'Contribution model, package rules, layer boundaries, and maintainer docs.'; Desc = 'Org-wide policies, layer boundaries, NuGet rules, and maintainer docs for Novolis.'; Topics = @('dotnet','governance','novolis') }
    'novolis-install'         = @{ Tag = 'One CLI to install the ecosystem'; Blurb = 'Cross-platform `novolis` installer CLI.'; Desc = 'Cross-platform novolis CLI installer for the Novolis ecosystem.'; Topics = @('dotnet','cli','installer','novolis') }
    'novolis-installer-inno'  = @{ Tag = 'Windows Inno Setup packaging'; Blurb = 'Inno Setup packaging helpers for Novolis Windows installers.'; Desc = 'Inno Setup installer packaging for Novolis Windows desktop apps.'; Topics = @('dotnet','installer','windows','novolis') }
    'novolis-io'              = @{ Tag = 'Git, paths, processes, recovery'; Blurb = 'IO helpers: Git, watching, recovery, processes, and path utilities.'; Desc = 'IO helpers for Novolis — Git, watching, recovery, processes, paths.'; Topics = @('dotnet','io','novolis') }
    'novolis-logging'         = @{ Tag = 'Logging building blocks'; Blurb = 'Logging helpers shared across Novolis libraries and apps.'; Desc = 'Logging helpers for the Novolis ecosystem.'; Topics = @('dotnet','logging','novolis') }
    'novolis-machinelearning' = @{ Tag = 'AutoML and neural helpers'; Blurb = 'Machine learning core, AutoML, and neural utilities for Novolis.'; Desc = '.NET machine learning helpers (AutoML, neural) for Novolis.'; Topics = @('dotnet','machine-learning','novolis') }
    'novolis-manuscript'      = @{ Tag = 'Long-form manuscript tooling'; Blurb = 'Manuscript authoring helpers that sit beside Markup and Documents.'; Desc = 'Manuscript authoring libraries for Novolis long-form content.'; Topics = @('dotnet','manuscript','markup','novolis') }
    'novolis-mapping'         = @{ Tag = 'Mapping utilities'; Blurb = 'Mapping helpers for Novolis applications.'; Desc = 'Mapping utilities for the Novolis ecosystem.'; Topics = @('dotnet','mapping','novolis') }
    'novolis-markup'          = @{ Tag = 'Manuscripts, markdown, mermaid'; Blurb = 'Manuscript, markdown, and Mermaid markup pipelines.'; Desc = 'Manuscript, markdown, and Mermaid markup libraries for Novolis.'; Topics = @('dotnet','markdown','markup','novolis') }
    'novolis-msbuild'         = @{ Tag = 'MSBuild props and targets'; Blurb = 'Shared MSBuild props/targets used across Novolis package repos.'; Desc = 'Shared MSBuild props and targets for Novolis .NET repositories.'; Topics = @('dotnet','msbuild','novolis') }
    'novolis-os'              = @{ Tag = 'Minimal Debian runtime images'; Blurb = 'Allowlisted Debian rootfs and QEMU appliances for running Novolis apps.'; Desc = 'Minimal Debian glibc runtime images for Novolis apps (rootfs + QEMU appliance).'; Topics = @('dotnet','linux','debian','runtime','novolis') }
    'novolis-math'            = @{ Tag = 'Geometry on BCL numerics'; Blurb = 'Renderer-agnostic math: arrays, geometry, topology — System.Numerics first.'; Desc = 'Math libraries for Novolis — arrays, geometry, topology on System.Numerics.'; Topics = @('dotnet','math','geometry','novolis') }
    'novolis-messaging'       = @{ Tag = 'Channels and messaging cores'; Blurb = 'Messaging abstractions and channel-based transports for realtime systems.'; Desc = 'Messaging and channel libraries for Novolis realtime systems.'; Topics = @('dotnet','messaging','novolis') }
    'novolis-physics'         = @{ Tag = 'Force-first textbook physics'; Blurb = 'Motion, gravity, ballistics, cloth, collision, orbits — Math only, no cameras.'; Desc = 'Force-first textbook physics for .NET — motion, gravity, cloth, orbits.'; Topics = @('dotnet','physics','simulation','novolis') }
    'novolis-raylib'          = @{ Tag = 'Raylib 6 for modern .NET'; Blurb = 'Multi-package Raylib 6 + raygui bindings, game API, hosting, and testing.'; Desc = 'Modern .NET bindings for raylib 6 + raygui — game, hosting, native RIDs.'; Topics = @('dotnet','raylib','gamedev','novolis') }
    'novolis-registry'        = @{ Tag = 'Static package & app catalog'; Blurb = 'Static registry of Novolis packages and apps.'; Desc = 'Static package and app registry for the Novolis ecosystem.'; Topics = @('dotnet','nuget','registry','novolis') }
    'novolis-rendering'       = @{ Tag = 'Compile-time friendly rendering'; Blurb = 'Rendering abstractions, compile pipeline, and GPU-facing helpers.'; Desc = 'Rendering libraries for Novolis — abstractions, compile, and GPU helpers.'; Topics = @('dotnet','graphics','rendering','novolis') }
    'novolis-scheduling'      = @{ Tag = 'Scheduling primitives'; Blurb = 'Scheduling helpers for Novolis runtimes.'; Desc = 'Scheduling primitives for the Novolis ecosystem.'; Topics = @('dotnet','scheduling','novolis') }
    'novolis-security'        = @{ Tag = 'Passwords, encryption, breach checks'; Blurb = 'Password hashing, encryption, and HaveIBeenPwned helpers.'; Desc = 'Security libraries for Novolis — hashing, encryption, breach checks.'; Topics = @('dotnet','security','novolis') }
    'novolis-ship'            = @{ Tag = 'Ship topology and airtight CAD'; Blurb = 'Avalonia-free ship domain — primitives, topology graphs, and airtight validation for .cadjson.'; Desc = 'Ship domain libraries for Novolis — primitives, topology, and airtight validation.'; Topics = @('dotnet','cad','ship','novolis') }
    'novolis-simulation'      = @{ Tag = 'Worlds, clocks, humanoids'; Blurb = 'Simulation orchestration above physics — humanoids, kinematics, space combat.'; Desc = 'Simulation libraries for Novolis — worlds, clocks, humanoids, space combat.'; Topics = @('dotnet','simulation','gamedev','novolis') }
    'novolis-smoketest'       = @{ Tag = 'Template smoke package'; Blurb = 'Smoke-test package proving the template/publish pipeline.'; Desc = 'Template smoke-test package for Novolis CI and publishing.'; Topics = @('dotnet','ci','novolis') }
    'novolis-storage'         = @{ Tag = 'Workspaces and persistence'; Blurb = 'Storage abstractions, in-memory/SQLite providers, and workspace IO.'; Desc = 'Storage and workspace IO libraries for Novolis.'; Topics = @('dotnet','storage','sqlite','novolis') }
    'novolis-template-dotnet' = @{ Tag = 'Canonical package repo template'; Blurb = 'Template for new Novolis .NET package repositories.'; Desc = 'Canonical .NET package and tool repository template for Novolis.'; Topics = @('dotnet','template','novolis') }
    'novolis-templates'       = @{ Tag = 'dotnet new templates'; Blurb = 'dotnet new templates for Novolis apps and libraries.'; Desc = 'dotnet new templates for the Novolis ecosystem.'; Topics = @('dotnet','templates','novolis') }
    'novolis-testing'         = @{ Tag = 'Test bases and containers'; Blurb = 'Logging test helpers, test bases, and Testcontainers integrations.'; Desc = 'Testing helpers for Novolis — bases, logging, Testcontainers.'; Topics = @('dotnet','testing','novolis') }
    'novolis-tools'           = @{ Tag = 'Maintainer CLIs and docs site'; Blurb = 'Maintainer tools: novolis-docs site builder, SQLite/LiteDB CLIs, and helpers.'; Desc = 'Maintainer CLIs and docs tooling for the Novolis platform.'; Topics = @('dotnet','cli','docs','novolis') }
    'novolis-transports'      = @{ Tag = 'HTTP, IPC, torrents, and more'; Blurb = 'Transport libraries: HTTP, local IPC, torrent, and related adapters.'; Desc = 'Transport libraries for Novolis — HTTP, local IPC, torrent, and more.'; Topics = @('dotnet','networking','novolis') }
    'novolis-video'           = @{ Tag = 'RTC mesh and movie edit core'; Blurb = 'Realtime video RTC contracts/mesh, Windows capture, and storyboard edit core.'; Desc = 'Realtime video for Novolis — RTC mesh, Windows capture, storyboard edit.'; Topics = @('dotnet','webrtc','video','novolis') }
    'novolis-wirefish'        = @{ Tag = 'Wire inspection tooling'; Blurb = 'Wire/protocol inspection helpers for Novolis debugging.'; Desc = 'Wire inspection tooling for the Novolis ecosystem.'; Topics = @('dotnet','networking','novolis') }
    'novolis-workflows'       = @{ Tag = 'Reusable GitHub Actions'; Blurb = 'Reusable CI workflows for build, pack, and release across Novolis repos.'; Desc = 'Reusable GitHub Actions workflows for Novolis build, pack, and release.'; Topics = @('github-actions','ci','novolis') }
    'novolis-workspaces'      = @{ Tag = 'Snapshots and timelines'; Blurb = 'Workspace, snapshot, and timeline libraries for editor and studio apps.'; Desc = 'Workspace, snapshot, and timeline libraries for Novolis studio apps.'; Topics = @('dotnet','workspaces','novolis') }
    'novolis-xsd'             = @{ Tag = 'XSD and schema tooling'; Blurb = 'XML schema helpers used by Novolis codegen and interchange formats.'; Desc = 'XSD / XML schema tooling for Novolis libraries and codegen.'; Topics = @('dotnet','xml','xsd','novolis') }
    '.github'                 = @{ Tag = 'Org home and brand'; Blurb = 'Organization profile README, brand assets, and landing status generators.'; Desc = 'Novolis-Platform organization profile, brand assets, and landing status.'; Topics = @('novolis','brand','documentation') }
}

function Export-RepoCatalogJson {
    param([hashtable]$Catalog, [string]$OutPath)
    $ordered = [ordered]@{}
    foreach ($key in ($Catalog.Keys | Sort-Object)) {
        $m = $Catalog[$key]
        $ordered[$key] = [ordered]@{
            tag    = [string]$m.Tag
            blurb  = [string]$m.Blurb
            desc   = [string]$m.Desc
            topics = @($m.Topics)
        }
    }
    $json = $ordered | ConvertTo-Json -Depth 6
    $dir = Split-Path $OutPath -Parent
    if ($dir) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    Set-Content -Path $OutPath -Value ($json.TrimEnd() + "`n") -Encoding utf8NoBOM
}

function Get-XmlText([xml]$xml, [string]$name) {
    foreach ($pg in @($xml.Project.PropertyGroup)) {
        if ($null -eq $pg) { continue }
        $n = $pg.$name
        if ($n -is [System.Array]) { $n = $n | Select-Object -First 1 }
        if ($n) { return [string]$n }
    }
    return $null
}

function New-BannerSvg {
    param([string]$RepoName, [string]$Tagline, [string]$OutPath)
    $title = $RepoName -replace '^novolis-', ''
    if ($title -eq '.github') { $title = 'platform' }
    $escTag = [System.Security.SecurityElement]::Escape($Tagline)
    $escTitle = [System.Security.SecurityElement]::Escape($title)
    $svg = @"
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1200 320" width="1200" height="320" role="img" aria-label="Novolis $escTitle">
  <defs>
    <linearGradient id="bg" x1="0" y1="0" x2="1200" y2="320" gradientUnits="userSpaceOnUse">
      <stop offset="0" stop-color="#05070d"/>
      <stop offset="0.55" stop-color="#0a1530"/>
      <stop offset="1" stop-color="#121028"/>
    </linearGradient>
    <linearGradient id="accent" x1="0" y1="0" x2="1200" y2="0" gradientUnits="userSpaceOnUse">
      <stop offset="0" stop-color="#2fdfff"/>
      <stop offset="0.5" stop-color="#4d86ff"/>
      <stop offset="1" stop-color="#b246ff"/>
    </linearGradient>
    <linearGradient id="glow" x1="900" y1="40" x2="1180" y2="280" gradientUnits="userSpaceOnUse">
      <stop offset="0" stop-color="#2fdfff" stop-opacity="0.35"/>
      <stop offset="1" stop-color="#8f37ff" stop-opacity="0"/>
    </linearGradient>
  </defs>
  <rect width="1200" height="320" fill="url(#bg)"/>
  <circle cx="1080" cy="60" r="160" fill="url(#glow)"/>
  <rect x="0" y="0" width="1200" height="4" fill="url(#accent)"/>
  <text x="56" y="118" fill="#e8f4ff" font-family="Segoe UI, Helvetica Neue, Arial, sans-serif" font-size="28" font-weight="600" letter-spacing="6">NOVOLIS</text>
  <text x="56" y="188" fill="#ffffff" font-family="Segoe UI, Helvetica Neue, Arial, sans-serif" font-size="64" font-weight="700">$escTitle</text>
  <text x="56" y="248" fill="#9eb6d4" font-family="Segoe UI, Helvetica Neue, Arial, sans-serif" font-size="26">$escTag</text>
  <rect x="56" y="280" width="180" height="4" rx="2" fill="url(#accent)"/>
</svg>
"@
    Set-Content -Path $OutPath -Value $svg -Encoding utf8NoBOM
}

function Get-MarketingHeader {
    param([string]$RepoName, [hashtable]$Meta)
    $bannerName = if ($RepoName -eq '.github') { 'github-org' } else { $RepoName }
    $bannerUrl = "https://raw.githubusercontent.com/$org/.github/main/brand/banners/$bannerName.svg"
    $tag = $Meta.Tag
    $blurb = $Meta.Blurb
    $docsUrl = if ($RepoName -eq '.github') {
        "https://$($org.ToLowerInvariant()).github.io/.github/"
    }
    else {
        "https://$($org.ToLowerInvariant()).github.io/.github/$RepoName/"
    }
    $mergeImg = "https://img.shields.io/github/actions/workflow/status/$org/$RepoName/merge.yml?branch=main&label=merge&logo=github"
    $pkgImg = "https://img.shields.io/badge/packages-GitHub%20Packages-0a7ea3?logo=nuget"
    $docsImg = "https://img.shields.io/badge/docs-portfolio-0a7ea3"
    $orgImg = "https://img.shields.io/badge/org-Novolis--Platform-111827"

    return @"
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
  <a href="$docsUrl"><img src="$docsImg" alt="docs"/></a>
  <a href="https://github.com/$org/$RepoName/actions"><img src="$mergeImg" alt="merge"/></a>
  <a href="https://github.com/orgs/$org/packages?repo_name=$RepoName"><img src="$pkgImg" alt="packages"/></a>
  <a href="https://github.com/$org"><img src="$orgImg" alt="org"/></a>
</p>

<p align="center">
  <a href="$docsUrl">Docs</a>
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
}

function Get-EffectiveIsPackable {
    param([string]$CsprojPath)
    [xml]$xml = Get-Content $CsprojPath -Raw
    $explicit = Get-XmlText $xml 'IsPackable'
    if ($explicit -eq 'false') { return $false }
    if ($explicit -eq 'true') { return $true }

    $dir = Split-Path $CsprojPath -Parent
    while ($dir) {
        $props = Join-Path $dir 'Directory.Build.props'
        if (Test-Path $props) {
            [xml]$px = Get-Content $props -Raw
            $v = Get-XmlText $px 'IsPackable'
            if ($v -eq 'false') { return $false }
            if ($v -eq 'true') { return $true }
        }
        $parent = Split-Path $dir -Parent
        if ($parent -eq $dir) { break }
        # stop at repo root (has .git or README + slnx)
        if ((Test-Path (Join-Path $dir '.git')) -or (Test-Path (Join-Path $dir '.gitignore'))) {
            break
        }
        $dir = $parent
    }
    # SDK default is packable; still skip obvious app/test names
    $leaf = Split-Path (Split-Path $CsprojPath -Parent) -Leaf
    if ($leaf -match '(Lab|Studio|Play|App|Host|Smoke)$') { return $false }
    return $true
}

function Ensure-PackageReadme {
    param([string]$CsprojPath, [string]$RepoName)
    if (-not (Get-EffectiveIsPackable -CsprojPath $CsprojPath)) { return $false }
    [xml]$xml = Get-Content $CsprojPath -Raw

    $dir = Split-Path $CsprojPath -Parent
    $id = Get-XmlText $xml 'PackageId'
    if (-not $id) { $id = Split-Path $dir -Leaf }
    $desc = Get-XmlText $xml 'Description'
    if (-not $desc) { $desc = "$id — Novolis platform library." }

    $readmePath = Join-Path $dir 'README.md'
    $brandStrip = @"
<p align="center">
  <a href="https://github.com/$org/$RepoName">
    <img src="$brandIconUrl" width="72" alt="Novolis"/>
  </a>
</p>

"@

    if (-not (Test-Path $readmePath)) {
        $content = @"
$brandStrip# $id

$desc

## Install

``````bash
dotnet add package $id
``````

**Prerequisites:** [.NET 10 SDK](https://dotnet.microsoft.com/download) (net10.0).

## Quick start

``````csharp
// See the repository docs and related package READMEs for entry points.
using $id;
``````

## More documentation

- [Repository](https://github.com/$org/$RepoName)
- [Org landing](https://github.com/$org)

## Support

Pre-release packages publish continuously to GitHub Packages as 2026.1.*.
"@
        # Fix accidental escaping of fences
        $content = $content -replace '``````', '```'
        Set-Content -Path $readmePath -Value $content -Encoding utf8NoBOM
        return $true
    }

    $body = Get-Content $readmePath -Raw
    $changed = $false
    if ($body -notmatch 'logo-icon\.svg') {
        if ($body -match '(?s)<!-- novolis-pkg-brand:start -->.*?<!-- novolis-pkg-brand:end -->') {
            # already marked
        }
        else {
            $strip = "<!-- novolis-pkg-brand:start -->`n$brandStrip<!-- novolis-pkg-brand:end -->`n`n"
            $body = $strip + $body.TrimStart()
            $changed = $true
        }
    }
    if ($body -notmatch '(?m)^## Install\s*$' -and $body -notmatch '(?m)^## Installation\s*$') {
        $install = @"

## Install

``````bash
dotnet add package $id
``````

**Prerequisites:** [.NET 10 SDK](https://dotnet.microsoft.com/download) (net10.0).
"@ -replace '``````', '```'
        # Insert after first H1 block
        if ($body -match '(?s)^(#[^\n]+\n(?:(?!^#)[^\n]*\n)*)') {
            $body = $body.Insert($Matches[0].Length, $install)
            $changed = $true
        }
        else {
            $body = $body.TrimEnd() + "`n" + $install + "`n"
            $changed = $true
        }
    }
    if ($changed) {
        Set-Content -Path $readmePath -Value ($body.TrimEnd() + "`n") -Encoding utf8NoBOM
    }
    return $changed
}

function Update-RepoReadme {
    param([string]$RepoRoot, [hashtable]$Meta)
    $repoName = Split-Path $RepoRoot -Leaf
    $readmePath = Join-Path $RepoRoot 'README.md'
    $header = Get-MarketingHeader -RepoName $repoName -Meta $Meta

    if (-not (Test-Path $readmePath) -or ((Get-Item $readmePath).Length -lt 20)) {
        $seed = @"
$header
# $repoName

$($Meta.Blurb)

## Get started

Configure GitHub Packages once (from a sibling `novolis-governance` checkout):

``````powershell
pwsh -File ../novolis-governance/scripts/configure-gpr-user-nuget.ps1
``````

See [Novolis-Platform](https://github.com/$org) for the full ecosystem.
"@ -replace '``````', '```'
        Set-Content -Path $readmePath -Value $seed -Encoding utf8NoBOM
    }
    else {
        $body = Get-Content $readmePath -Raw
        if ($body -match '(?s)<!-- novolis-marketing:start -->.*?<!-- novolis-marketing:end -->\s*') {
            $body = $body -replace '(?s)<!-- novolis-marketing:start -->.*?<!-- novolis-marketing:end -->\s*', $header
        }
        else {
            # Place marketing above package-index if present, else at top
            if ($body -match '(?s)(<!-- novolis-package-index:start -->.*?<!-- novolis-package-index:end -->\s*)') {
                $body = $header + $body
            }
            else {
                $body = $header + $body.TrimStart()
            }
        }
        Set-Content -Path $readmePath -Value ($body.TrimEnd() + "`n") -Encoding utf8NoBOM
    }
}

function Sync-PackageIndex {
    param([string]$RepoRoot)
    $sync = Join-Path $governanceRoot 'scripts\sync-repo-package-index-readme.ps1'
    try {
        & $sync -RepoRoot $RepoRoot -Replace
        return $true
    }
    catch {
        Write-Warning "Package index skip for $(Split-Path $RepoRoot -Leaf): $($_.Exception.Message)"
        return $false
    }
}

# --- Banners + docs-site catalog ---
if (-not $SkipBanners) {
    foreach ($key in $catalog.Keys) {
        $name = if ($key -eq '.github') { 'github-org' } else { $key }
        New-BannerSvg -RepoName $key -Tagline $catalog[$key].Tag -OutPath (Join-Path $bannerDir "$name.svg")
    }
    Write-Host "Wrote banners to $bannerDir"
}

$catalogJson = Join-Path $GitHubBrandRoot 'site\repo-catalog.json'
Export-RepoCatalogJson -Catalog $catalog -OutPath $catalogJson
Write-Host "Wrote docs catalog $catalogJson"

# --- Repos ---
$repoDirs = @(Get-ChildItem $WorkspaceRoot -Directory | Where-Object {
        $_.Name -like 'novolis-*' -or $_.Name -eq '.github'
    })

$stats = [ordered]@{ Repos = 0; PackageReadmes = 0; Indexes = 0; Meta = 0 }

foreach ($dir in ($repoDirs | Sort-Object Name)) {
    $name = $dir.Name
    if (-not $catalog.ContainsKey($name)) {
        Write-Warning "No catalog entry for $name — using defaults"
        $catalog[$name] = @{
            Tag    = 'Novolis ecosystem library'
            Blurb  = "Part of the Novolis platform ($name)."
            Desc   = "Novolis ecosystem repository: $name"
            Topics = @('dotnet', 'novolis')
        }
    }
    $meta = $catalog[$name]
    Write-Host "==> $name"

    $skipPkgReadmeRepos = @('novolis-apps', 'novolis-dogfooding', 'novolis-experimental', 'novolis-template-dotnet', '.github', 'novolis-governance', 'novolis-workflows', 'novolis-registry')
    $skipPackageIndexRepos = @('novolis-apps', 'novolis-dogfooding', 'novolis-experimental', 'novolis-template-dotnet', '.github', 'novolis-governance', 'novolis-workflows', 'novolis-registry', 'novolis-logging', 'novolis-mapping', 'novolis-scheduling', 'novolis-wirefish')

    if ($name -notin $skipPkgReadmeRepos) {
        foreach ($csproj in @(Get-ChildItem (Join-Path $dir.FullName 'src') -Recurse -Filter '*.csproj' -EA SilentlyContinue)) {
            if (Ensure-PackageReadme -CsprojPath $csproj.FullName -RepoName $name) {
                $stats.PackageReadmes++
            }
        }
        foreach ($csproj in @(Get-ChildItem (Join-Path $dir.FullName 'codegen') -Recurse -Filter '*.csproj' -EA SilentlyContinue)) {
            if (Ensure-PackageReadme -CsprojPath $csproj.FullName -RepoName $name) {
                $stats.PackageReadmes++
            }
        }
    }

    # Index first so marketing header can sit above it.
    if ($name -notin $skipPackageIndexRepos) {
        if (Sync-PackageIndex -RepoRoot $dir.FullName) { $stats.Indexes++ }
    }
    else {
        # Remove mistaken package indexes from app/infra repos
        $rd = Join-Path $dir.FullName 'README.md'
        if (Test-Path $rd) {
            $b = Get-Content $rd -Raw
            if ($b -match '(?s)<!-- novolis-package-index:start -->.*?<!-- novolis-package-index:end -->\s*') {
                $b = $b -replace '(?s)<!-- novolis-package-index:start -->.*?<!-- novolis-package-index:end -->\s*', ''
                Set-Content -Path $rd -Value ($b.TrimEnd() + "`n") -Encoding utf8NoBOM
                Write-Host "  stripped package index from $name"
            }
        }
    }

    Update-RepoReadme -RepoRoot $dir.FullName -Meta $meta
    $stats.Repos++

    if ($ApplyGitHubMeta) {
        $ghName = if ($name -eq '.github') { '.github' } else { $name }
        # Skip local-only folders that are not org repos
        $localOnly = @('novolis-logging', 'novolis-mapping', 'novolis-scheduling', 'novolis-wirefish')
        if ($name -in $localOnly) {
            # leave local README upgrades; no remote
        }
        else {
            try {
                gh repo edit "$org/$ghName" --description $meta.Desc | Out-Null
                foreach ($t in $meta.Topics) {
                    gh repo edit "$org/$ghName" --add-topic $t 2>$null | Out-Null
                }
                $stats.Meta++
            }
            catch {
                Write-Warning "gh meta failed for ${ghName}: $($_.Exception.Message)"
            }
        }
    }
}

Write-Host ""
Write-Host "Done. Repos=$($stats.Repos) packageReadmeTouches=$($stats.PackageReadmes) indexes=$($stats.Indexes) meta=$($stats.Meta)"
Write-Host "Banners: $bannerDir"
Write-Host "Remember: commit+push .github first so banner URLs resolve, then other repos."
