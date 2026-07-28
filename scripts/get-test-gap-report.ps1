#Requires -Version 7.0
<#
.SYNOPSIS
  Find solutions/repos without tests and production assemblies never referenced by a test host.

.DESCRIPTION
  Static, parallel scan — no build required.

  1. Repos with src/codegen (or a .slnx) but no TUnit/xUnit/NUnit/VSTest host under tests/
  2. Assemblies under src/ and codegen/ with no ProjectReference from any test host in that repo

  Uses the same exclude file as get-coverage-report.ps1.

.PARAMETER Root
  Org checkout root.

.PARAMETER Exclude / ExcludeFile / Include
  Same semantics as get-coverage-report.ps1.

.PARAMETER PackableOnly
  Only flag packable assemblies (default). Pass -IncludeNonPackable to include IsPackable=false libs.

.PARAMETER IncludeExecutables
  Include WinExe/Exe projects under src/.

.PARAMETER IncludeNonPackable
  Also flag non-packable libraries.

.PARAMETER ThrottleLimit
  Parallelism for per-repo scans.

.PARAMETER OutputDir
  Report output (default <Root>/artifacts/test-gaps).

.PARAMETER FailOnGaps
  Exit 1 when any gap is found (default: true). Pass -FailOnGaps:`$false for report-only.

.EXAMPLE
  pwsh -File novolis-governance/scripts/get-test-gap-report.ps1

.EXAMPLE
  pwsh -File novolis-governance/scripts/get-test-gap-report.ps1 -Include novolis-audio,novolis-io -FailOnGaps:`$false
#>
param(
    [string]$Root = '',
    [string[]]$Exclude = @(),
    [string]$ExcludeFile = '',
    [string[]]$Include = @(),
    [switch]$IncludeExecutables,
    [switch]$IncludeNonPackable,
    [int]$ThrottleLimit = 0,
    [string]$OutputDir = '',
    [bool]$FailOnGaps = $true
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'lib\Coverage.ps1')

if (-not $Root) {
    $Root = Get-NovolisCoverageRoot
}
$Root = (Resolve-Path -LiteralPath $Root).Path

if (-not $ExcludeFile) {
    $ExcludeFile = Join-Path $PSScriptRoot 'coverage-excludes.txt'
}

if ($ThrottleLimit -le 0) {
    $ThrottleLimit = [Math]::Max(1, [Environment]::ProcessorCount - 1)
}

if (-not $OutputDir) {
    $OutputDir = Join-Path $Root 'artifacts\test-gaps'
}

$PackableOnly = -not [bool]$IncludeNonPackable

$excludeList = Read-CoverageExcludeList -ExcludeFile $ExcludeFile -Exclude $Exclude
$includeList = Expand-NameList $Include
$repos = @(Get-NovolisRepoDirectories -Root $Root -Exclude $excludeList -Include $includeList)

Write-Host "Test-gap root: $Root" -ForegroundColor White
Write-Host "Output:        $OutputDir"
Write-Host "Throttle:      $ThrottleLimit"
Write-Host "PackableOnly:  $PackableOnly"
Write-Host "Excluded:      $($excludeList -join ', ')"
Write-Host "Repos:         $($repos.Count)"
Write-Host ''

if ($repos.Count -eq 0) {
    Write-Host 'No repos matched.' -ForegroundColor Yellow
    exit 0
}

New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null

$packableOnly = [bool]$PackableOnly
$includeExe = [bool]$IncludeExecutables

$results = $repos | ForEach-Object -ThrottleLimit $ThrottleLimit -Parallel {
    $ErrorActionPreference = 'Stop'
    $repo = $_
    $packableOnly = $using:packableOnly
    $includeExe = $using:includeExe

    # Re-dot-source helpers in the runspace by inlining minimal logic would be heavy;
    # call into the same file via a nested pwsh is slow. Duplicate thin discovery here.
    function Test-Host([string]$p) {
        if ($p -notmatch '[\\/]tests[\\/]') { return $false }
        return [bool](Select-String -LiteralPath $p -Pattern 'TUnit|Microsoft\.NET\.Test\.Sdk|xunit|NUnit' -Quiet)
    }

    $testProjects = @(
        Get-ChildItem -LiteralPath $repo.Path -Recurse -Filter '*.csproj' -ErrorAction SilentlyContinue |
            Where-Object { Test-Host $_.FullName } |
            ForEach-Object { $_.FullName }
    )

    $slnxFiles = @(Get-ChildItem -LiteralPath $repo.Path -Filter '*.slnx' -File -ErrorAction SilentlyContinue)
    $hasSrc = (Test-Path -LiteralPath (Join-Path $repo.Path 'src')) -or (Test-Path -LiteralPath (Join-Path $repo.Path 'codegen'))

    $tested = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach ($tp in $testProjects) {
        $dir = Split-Path $tp -Parent
        $text = Get-Content -LiteralPath $tp -Raw
        foreach ($m in [regex]::Matches($text, 'ProjectReference\s+Include="([^"]+)"')) {
            $raw = $m.Groups[1].Value -replace '/', '\'
            $resolved = [IO.Path]::GetFullPath((Join-Path $dir $raw))
            if ($resolved.StartsWith($repo.Path, [StringComparison]::OrdinalIgnoreCase)) {
                [void]$tested.Add($resolved)
            }
        }
    }

    $skipPath = [regex]'[\\/](tests|samples|benchmarks|tools|artifacts|obj|bin)[\\/]'
    $production = [System.Collections.Generic.List[object]]::new()
    foreach ($dirName in @('src', 'codegen')) {
        $dir = Join-Path $repo.Path $dirName
        if (-not (Test-Path -LiteralPath $dir)) { continue }
        Get-ChildItem -LiteralPath $dir -Recurse -Filter '*.csproj' -ErrorAction SilentlyContinue | ForEach-Object {
            if ($skipPath.IsMatch($_.FullName)) { return }
            $text = Get-Content -LiteralPath $_.FullName -Raw
            if ($text -match '(?i)<IsTestProject>\s*true\s*</IsTestProject>') { return }
            if ($text -match '(?i)<OutputType>\s*(WinExe|Exe)\s*</OutputType>' -and -not $includeExe) { return }
            $isPackable = $true
            if ($text -match '(?i)<IsPackable>\s*false\s*</IsPackable>') { $isPackable = $false }
            if ($packableOnly -and -not $isPackable) { return }
            $packageId = [IO.Path]::GetFileNameWithoutExtension($_.FullName)
            if ($text -match '(?i)<PackageId>\s*([^<]+)\s*</PackageId>') {
                $packageId = $Matches[1].Trim()
            }
            $production.Add([pscustomobject]@{
                Path      = $_.FullName
                Name      = [IO.Path]::GetFileNameWithoutExtension($_.FullName)
                PackageId = $packageId
                Packable  = $isPackable
                RelPath   = $_.FullName.Substring($repo.Path.Length).TrimStart('\', '/')
                Tested    = $tested.Contains($_.FullName)
            })
        }
    }

    $untested = @($production | Where-Object { -not $_.Tested })
    $noTests = ($testProjects.Count -eq 0) -and ($hasSrc -or $slnxFiles.Count -gt 0)

    [pscustomobject]@{
        Repo              = $repo.Name
        Path              = $repo.Path
        Solutions         = @($slnxFiles | ForEach-Object { $_.Name })
        TestHostCount     = $testProjects.Count
        ProductionCount   = $production.Count
        TestedCount       = @($production | Where-Object Tested).Count
        UntestedCount     = $untested.Count
        NoTestHosts       = $noTests
        Untested          = @($untested | Sort-Object PackageId)
        CoveragePct       = if ($production.Count -gt 0) {
            [math]::Round(100.0 * @($production | Where-Object Tested).Count / $production.Count, 1)
        } else { $null }
    }
}

$sorted = @($results | Sort-Object Repo)
$reposWithoutTests = @($sorted | Where-Object NoTestHosts)
$untestedAssemblies = @(
    foreach ($r in $sorted) {
        foreach ($a in $r.Untested) {
            [pscustomobject]@{
                Repo      = $r.Repo
                PackageId = $a.PackageId
                RelPath   = $a.RelPath
                Packable  = $a.Packable
            }
        }
    }
)

# Console
Write-Host '=== Repos / solutions without test hosts ===' -ForegroundColor Cyan
if ($reposWithoutTests.Count -eq 0) {
    Write-Host '(none)' -ForegroundColor Green
}
else {
    $reposWithoutTests | ForEach-Object {
        [pscustomobject]@{
            Repo      = $_.Repo
            Solutions = ($_.Solutions -join ', ')
            SrcLibs   = $_.ProductionCount
        }
    } | Format-Table -AutoSize
}

Write-Host ''
Write-Host '=== Assemblies with no test ProjectReference ===' -ForegroundColor Cyan
if ($untestedAssemblies.Count -eq 0) {
    Write-Host '(none)' -ForegroundColor Green
}
else {
    $untestedAssemblies |
        Sort-Object Repo, PackageId |
        Format-Table Repo, PackageId, RelPath -AutoSize
}

Write-Host ''
Write-Host '=== Per-repo test linkage ===' -ForegroundColor Cyan
$sorted | ForEach-Object {
    [pscustomobject]@{
        Repo        = $_.Repo
        TestHosts   = $_.TestHostCount
        Assemblies  = $_.ProductionCount
        Linked      = $_.TestedCount
        Untested    = $_.UntestedCount
        LinkedPct   = if ($null -eq $_.CoveragePct) { '—' } else {
            $_.CoveragePct.ToString('0.0', [Globalization.CultureInfo]::InvariantCulture) + '%'
        }
    }
} | Format-Table -AutoSize

# Markdown + JSON
$mdPath = Join-Path $OutputDir 'SUMMARY.md'
$md = [System.Collections.Generic.List[string]]::new()
$md.Add('# Novolis test gap report')
$md.Add('')
$md.Add("Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
$md.Add("Repos scanned: $($sorted.Count)  |  Without tests: $($reposWithoutTests.Count)  |  Untested assemblies: $($untestedAssemblies.Count)")
$md.Add('')
$md.Add('Metric is **direct** `ProjectReference` from a test host (`tests/**` + TUnit/xUnit/NUnit/VSTest). Transitive-only use does not count.')
$md.Add('')
$md.Add('## Repos without test hosts')
$md.Add('')
if ($reposWithoutTests.Count -eq 0) {
    $md.Add('_None._')
}
else {
    $md.Add('| Repo | Solutions | Production assemblies |')
    $md.Add('|------|-----------|------------------------|')
    foreach ($r in $reposWithoutTests) {
        $sols = if ($r.Solutions.Count -gt 0) { ($r.Solutions -join ', ') } else { '—' }
        $md.Add("| $($r.Repo) | $sols | $($r.ProductionCount) |")
    }
}
$md.Add('')
$md.Add('## Assemblies not referenced by any test host')
$md.Add('')
if ($untestedAssemblies.Count -eq 0) {
    $md.Add('_None._')
}
else {
    $md.Add('| Repo | PackageId | Path |')
    $md.Add('|------|-----------|------|')
    foreach ($a in ($untestedAssemblies | Sort-Object Repo, PackageId)) {
        $md.Add("| $($a.Repo) | $($a.PackageId) | $($a.RelPath) |")
    }
}
$md.Add('')
$md.Add('## Per-repo linkage')
$md.Add('')
$md.Add('| Repo | Test hosts | Assemblies | Linked | Untested | Linked % |')
$md.Add('|------|------------|------------|--------|----------|----------|')
foreach ($r in $sorted) {
    $pct = if ($null -eq $r.CoveragePct) { '—' } else {
        $r.CoveragePct.ToString('0.0', [Globalization.CultureInfo]::InvariantCulture)
    }
    $md.Add("| $($r.Repo) | $($r.TestHostCount) | $($r.ProductionCount) | $($r.TestedCount) | $($r.UntestedCount) | $pct |")
}
($md -join [Environment]::NewLine) | Set-Content -LiteralPath $mdPath -Encoding utf8

$jsonPath = Join-Path $OutputDir 'summary.json'
[pscustomobject]@{
    GeneratedUtc           = (Get-Date).ToUniversalTime().ToString('o')
    PackableOnly           = $packableOnly
    ReposScanned           = $sorted.Count
    ReposWithoutTestHosts  = @($reposWithoutTests | ForEach-Object { $_.Repo })
    UntestedAssemblies     = $untestedAssemblies
    Repos                  = @($sorted | Select-Object Repo, TestHostCount, ProductionCount, TestedCount, UntestedCount, CoveragePct, NoTestHosts, Solutions)
} | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $jsonPath -Encoding utf8

Write-Host ''
Write-Host "Summary: $mdPath" -ForegroundColor Green
Write-Host "JSON:    $jsonPath"
Write-Host "Repos without tests: $($reposWithoutTests.Count)  |  Untested assemblies: $($untestedAssemblies.Count)"

$gapCount = $reposWithoutTests.Count + $untestedAssemblies.Count
if ($FailOnGaps -and $gapCount -gt 0) {
    exit 1
}
exit 0
