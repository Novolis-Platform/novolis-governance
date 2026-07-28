#Requires -Version 7.0
<#
.SYNOPSIS
  Verify Platform ProjectReference mode map + intersect-only MSBuild substitution.

.DESCRIPTION
  1. Regenerate-or-load map completeness: every IsPackable PackageId ↔ one map entry, paths exist, unique ids.
  2. Static intersect dry-run: sample consumers must only substitute packages they PackageReference.
  3. MSBuild smoke: with NovolisUseProjectReferences=true, expected ProjectReferences appear and
     those PackageReferences are removed; with false, no cross-repo ProjectReferences from the map.

.PARAMETER WorkspaceRoot
  Novolis workspace root.

.PARAMETER SkipMsBuild
  Skip the MSBuild -getItem smoke (map + static checks only).

.PARAMETER SkipBuild
  Skip optional focused build of Novolis.Physics.Unit under project-ref mode.
#>
[CmdletBinding()]
param(
    [string]$WorkspaceRoot,
    [switch]$SkipMsBuild,
    [switch]$SkipBuild
)

$ErrorActionPreference = 'Stop'
$failures = [System.Collections.Generic.List[string]]::new()

function Fail([string]$Message) {
    $failures.Add($Message)
    Write-Host "FAIL: $Message" -ForegroundColor Red
}

$scriptsRoot = $PSScriptRoot
$govRoot = Split-Path $scriptsRoot -Parent
if (-not $WorkspaceRoot) {
    $WorkspaceRoot = if ($env:NOVOLIS_ROOT) { $env:NOVOLIS_ROOT } else { Split-Path $govRoot -Parent }
}

$mapScript = Join-Path $govRoot 'build\Generate-PackageToProjectMap.ps1'
$mapPath = Join-Path $govRoot 'build\generated\Novolis.PackageToProject.props'
$excludeRepo = [regex]'workflows|governance|registry|dogfooding|installer|experimental|smoketest|template-dotnet'

Write-Host "=== regenerate map ===" -ForegroundColor Cyan
& $mapScript -WorkspaceRoot $WorkspaceRoot -OutputPath $mapPath | Out-Null

if (-not (Test-Path $mapPath)) {
    Fail "Map file missing after generate: $mapPath"
    Write-Error ($failures -join [Environment]::NewLine)
    exit 1
}

# Parse map entries
$mapText = Get-Content $mapPath -Raw
$mapEntries = [System.Collections.Generic.Dictionary[string, string]]::new([StringComparer]::OrdinalIgnoreCase)
foreach ($m in [regex]::Matches($mapText, '<NovolisPackageProject Include="([^"]+)">\s*<ProjectPath>\$\(NovolisWorkspaceRoot\)([^<]+)</ProjectPath>')) {
    $id = $m.Groups[1].Value
    $rel = $m.Groups[2].Value.Trim() -replace '/', '\'
    if ($mapEntries.ContainsKey($id)) {
        Fail "Duplicate map PackageId: $id"
    }
    else {
        $mapEntries[$id] = $rel
    }
}

Write-Host "Map entries: $($mapEntries.Count)"

# Scan packable projects
$packable = [System.Collections.Generic.Dictionary[string, string]]::new([StringComparer]::OrdinalIgnoreCase)
Get-ChildItem $WorkspaceRoot -Directory -Filter 'novolis-*' |
    Where-Object { $_.Name -notmatch $excludeRepo } |
    ForEach-Object {
        Get-ChildItem $_.FullName -Recurse -Filter '*.csproj' -ErrorAction SilentlyContinue |
            Where-Object { $_.FullName -notmatch '[\\/](obj|bin)[\\/]' } |
            ForEach-Object {
                $text = Get-Content $_.FullName -Raw
                if ($text -notmatch '<IsPackable>\s*true\s*</IsPackable>') { return }
                $packageId = if ($text -match '<PackageId>\s*([^<]+?)\s*</PackageId>') {
                    $Matches[1].Trim()
                }
                else {
                    [IO.Path]::GetFileNameWithoutExtension($_.Name)
                }
                $rel = $_.FullName.Substring($WorkspaceRoot.Length).TrimStart('\', '/') -replace '/', '\'
                if ($packable.ContainsKey($packageId)) {
                    Fail "Duplicate packable PackageId in tree: $packageId"
                }
                else {
                    $packable[$packageId] = $rel
                }
            }
    }

Write-Host "Packable projects: $($packable.Count)"

foreach ($kv in $packable.GetEnumerator()) {
    if (-not $mapEntries.ContainsKey($kv.Key)) {
        Fail "Packable missing from map: $($kv.Key) ($($kv.Value))"
        continue
    }
    if ($mapEntries[$kv.Key] -ne $kv.Value) {
        Fail "Map path mismatch for $($kv.Key): map='$($mapEntries[$kv.Key])' actual='$($kv.Value)'"
    }
}

foreach ($kv in $mapEntries.GetEnumerator()) {
    if (-not $packable.ContainsKey($kv.Key)) {
        Fail "Map entry not packable / stale: $($kv.Key) -> $($kv.Value)"
    }
    $full = Join-Path $WorkspaceRoot $kv.Value
    if (-not (Test-Path -LiteralPath $full)) {
        Fail "Map path does not exist: $($kv.Key) -> $full"
    }
}

function Get-PackageReferences([string]$CsprojPath) {
    $text = Get-Content $CsprojPath -Raw
    $ids = [System.Collections.Generic.List[string]]::new()
    foreach ($m in [regex]::Matches($text, '<PackageReference\s+Include="(Novolis\.[^"]+)"')) {
        $ids.Add($m.Groups[1].Value) | Out-Null
    }
    return $ids
}

function Get-ExpectedSubstitutions([string]$CsprojPath) {
    $pkgRefs = Get-PackageReferences $CsprojPath
    $expected = [System.Collections.Generic.List[string]]::new()
    foreach ($id in $pkgRefs) {
        if ($mapEntries.ContainsKey($id)) {
            $expected.Add($id) | Out-Null
        }
    }
    return $expected
}

# Static intersect dry-run samples
$samples = @(
    (Join-Path $WorkspaceRoot 'novolis-physics\src\Novolis.Physics\Novolis.Physics.csproj'),
    (Join-Path $WorkspaceRoot 'novolis-physics\tests\Novolis.Physics.Unit\Novolis.Physics.Unit.csproj'),
    (Join-Path $WorkspaceRoot 'novolis-simulation\src\Novolis.Simulation\Novolis.Simulation.csproj')
)

Write-Host "=== static intersect dry-run ===" -ForegroundColor Cyan
foreach ($sample in $samples) {
    if (-not (Test-Path $sample)) {
        Write-Host "SKIP (missing): $sample" -ForegroundColor Yellow
        continue
    }
    $pkgRefs = Get-PackageReferences $sample
    $expected = Get-ExpectedSubstitutions $sample
    $rel = $sample.Substring($WorkspaceRoot.Length).TrimStart('\', '/')
    Write-Host "  $rel"
    Write-Host "    PackageReference Novolis.*: $($pkgRefs -join ', ')"
    Write-Host "    Would substitute: $($expected -join ', ')"

    foreach ($id in $mapEntries.Keys) {
        if ($expected -notcontains $id -and $pkgRefs -notcontains $id) {
            # must not invent — nothing to check beyond expected list
            continue
        }
        if ($pkgRefs -notcontains $id -and $expected -contains $id) {
            Fail "$rel would invent ProjectReference for unreferenced $id"
        }
    }
    foreach ($id in $pkgRefs) {
        if ($mapEntries.ContainsKey($id) -and $expected -notcontains $id) {
            Fail "$rel PackageReference $id is in map but not in expected substitute set"
        }
        if (-not $mapEntries.ContainsKey($id) -and $id -like 'Novolis.*') {
            # third-party Novolis? or not packable locally — OK to stay PackageReference
            Write-Host "    (stays PackageReference, no local map): $id" -ForegroundColor DarkGray
        }
    }
}

function Get-MsBuildItems {
    param(
        [Parameter(Mandatory)][string]$Project,
        [Parameter(Mandatory)][string]$ItemName,
        [hashtable]$Properties = @{},
        [string[]]$Targets = @()
    )

    $args = [System.Collections.Generic.List[string]]::new()
    $args.Add($Project) | Out-Null
    if ($Targets.Count -gt 0) {
        $args.Add("-t:$($Targets -join ';')") | Out-Null
    }
    $args.Add("-getItem:$ItemName") | Out-Null
    $args.Add('-nologo') | Out-Null
    foreach ($k in $Properties.Keys) {
        $args.Add("-p:$k=$($Properties[$k])") | Out-Null
    }

    $json = & dotnet msbuild @args 2>$null | Out-String
    if ($LASTEXITCODE -ne 0) {
        $err = & dotnet msbuild @args 2>&1 | Out-String
        Fail "dotnet msbuild -getItem:$ItemName failed for $Project : $err"
        return @()
    }

    # Extract the outermost JSON object (dotnet may emit noise around it).
    $start = $json.IndexOf('{')
    $end = $json.LastIndexOf('}')
    if ($start -lt 0 -or $end -le $start) {
        Fail "No JSON from -getItem:$ItemName for $Project. Raw: $json"
        return @()
    }
    $jsonOnly = $json.Substring($start, $end - $start + 1)

    try {
        $obj = $jsonOnly | ConvertFrom-Json
        $items = $obj.Items.$ItemName
        if ($null -eq $items) { return @() }
        if ($items -is [System.Array]) { return @($items) }
        return @($items)
    }
    catch {
        Fail "Failed to parse -getItem:$ItemName JSON: $_. Content: $jsonOnly"
        return @()
    }
}

function Get-ItemFullPaths($items) {
    $list = [System.Collections.Generic.List[string]]::new()
    foreach ($i in $items) {
        if ($null -eq $i) { continue }
        if ($i -is [string]) {
            try { $list.Add([IO.Path]::GetFullPath($i)) | Out-Null } catch { $list.Add($i) | Out-Null }
            continue
        }
        $path = $null
        if ($i.PSObject.Properties['FullPath'] -and $i.FullPath) { $path = [string]$i.FullPath }
        elseif ($i.PSObject.Properties['Identity']) { $path = [string]$i.Identity }
        if ($path) {
            try { $list.Add([IO.Path]::GetFullPath($path)) | Out-Null } catch { $list.Add($path) | Out-Null }
        }
    }
    return $list
}

function Get-ItemIdentities($items) {
    $list = [System.Collections.Generic.List[string]]::new()
    foreach ($i in $items) {
        if ($null -eq $i) { continue }
        if ($i -is [string]) {
            $list.Add($i) | Out-Null
            continue
        }
        if ($i.PSObject.Properties['Identity']) {
            $list.Add([string]$i.Identity) | Out-Null
        }
    }
    return $list
}

if (-not $SkipMsBuild) {
    Write-Host "=== MSBuild intersect smoke ===" -ForegroundColor Cyan
    $consumer = Join-Path $WorkspaceRoot 'novolis-physics\src\Novolis.Physics.Abstractions\Novolis.Physics.Abstractions.csproj'
    if (-not (Test-Path $consumer)) {
        Fail "Smoke consumer missing: $consumer"
    }
    else {
        $expectedIds = Get-ExpectedSubstitutions $consumer
        $geometryPath = Join-Path $WorkspaceRoot ($mapEntries['Novolis.Math.Geometry'])
        $subTarget = @('NovolisSubstituteProjectReferences')

        # Mode OFF baseline (no substitute target needed)
        $projOff = Get-ItemFullPaths (Get-MsBuildItems -Project $consumer -ItemName 'ProjectReference' -Properties @{
                NovolisUseProjectReferences = 'false'
            })
        $pkgOff = Get-ItemIdentities (Get-MsBuildItems -Project $consumer -ItemName 'PackageReference' -Properties @{
                NovolisUseProjectReferences = 'false'
            })

        # Mode ON — must run substitute target so -getItem sees rewritten items
        $projOn = Get-ItemFullPaths (Get-MsBuildItems -Project $consumer -ItemName 'ProjectReference' -Properties @{
                NovolisUseProjectReferences = 'true'
            } -Targets $subTarget)
        $pkgOn = Get-ItemIdentities (Get-MsBuildItems -Project $consumer -ItemName 'PackageReference' -Properties @{
                NovolisUseProjectReferences = 'true'
            } -Targets $subTarget)

        foreach ($id in $expectedIds) {
            $mapped = Join-Path $WorkspaceRoot $mapEntries[$id]
            $full = [IO.Path]::GetFullPath($mapped)
            if ($projOn -notcontains $full) {
                Fail "Mode ON: missing ProjectReference for $id (expected $full). Got: $($projOn -join '; ')"
            }
            if ($pkgOn -contains $id) {
                Fail "Mode ON: PackageReference $id should have been removed"
            }
        }

        # Invented = newly added ProjectReferences (ON - OFF) that are not expected substitutes
        $expectedPaths = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
        foreach ($id in $expectedIds) {
            $expectedPaths.Add([IO.Path]::GetFullPath((Join-Path $WorkspaceRoot $mapEntries[$id]))) | Out-Null
        }
        $offSet = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
        foreach ($p in $projOff) { $offSet.Add($p) | Out-Null }

        foreach ($p in $projOn) {
            if ($offSet.Contains($p)) { continue }
            if ($expectedPaths.Contains($p)) { continue }
            Fail "Mode ON: invented ProjectReference (not in PackageReference intersect): $p"
        }

        if ($geometryPath -and (Test-Path $geometryPath)) {
            $geoFull = [IO.Path]::GetFullPath($geometryPath)
            if ($projOff -contains $geoFull) {
                Fail "Mode OFF: unexpected ProjectReference to Novolis.Math.Geometry"
            }
        }
        foreach ($id in $expectedIds) {
            if ($pkgOff -notcontains $id) {
                Fail "Mode OFF: PackageReference $id should remain (got: $($pkgOff -join ', '))"
            }
        }

        Write-Host "  Consumer: Novolis.Physics.Abstractions"
        Write-Host "  Expected substitutes: $($expectedIds -join ', ')"
        Write-Host "  Mode ON ProjectReferences: $($projOn.Count)"
        Write-Host "  Mode OFF PackageReferences kept: $($expectedIds -join ', ')"
    }
}

if (-not $SkipBuild -and -not $SkipMsBuild) {
    Write-Host "=== focused build smoke (Physics.Unit, project-ref mode) ===" -ForegroundColor Cyan
    $unit = Join-Path $WorkspaceRoot 'novolis-physics\tests\Novolis.Physics.Unit\Novolis.Physics.Unit.csproj'
    if (Test-Path $unit) {
        & dotnet build $unit -p:NovolisUseProjectReferences=true --no-restore 2>&1 | Out-Null
        # restore first then build
        & dotnet build $unit -p:NovolisUseProjectReferences=true -v:q
        if ($LASTEXITCODE -ne 0) {
            Fail "dotnet build Novolis.Physics.Unit with NovolisUseProjectReferences=true failed"
        }
        else {
            Write-Host "  Build OK" -ForegroundColor Green
        }
    }
    else {
        Write-Host "SKIP build smoke (project missing)" -ForegroundColor Yellow
    }
}

Write-Host ''
if ($failures.Count -gt 0) {
    Write-Host "verify-project-ref-mode: FAILED ($($failures.Count))" -ForegroundColor Red
    foreach ($f in $failures) {
        Write-Host "  - $f"
    }
    Write-Host 'See novolis-governance/docs/platform-project-ref-mode.md'
    exit 1
}

Write-Host 'verify-project-ref-mode: OK' -ForegroundColor Green
exit 0
