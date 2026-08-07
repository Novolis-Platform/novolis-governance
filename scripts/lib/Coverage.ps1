#Requires -Version 7.0
<#
.SYNOPSIS
  Shared helpers for org-wide coverage collection.
#>

# When this file is dot-sourced, $PSScriptRoot is .../scripts/lib.
$script:CoverageLibDir = $PSScriptRoot

function Get-NovolisCoverageRoot {
    if ($env:NOVOLIS_ROOT) {
        return $env:NOVOLIS_ROOT
    }
    $scripts = Split-Path $script:CoverageLibDir -Parent
    $governance = Split-Path $scripts -Parent
    return (Split-Path $governance -Parent)
}

function Expand-NameList {
    param([string[]]$Names = @())
    $out = [System.Collections.Generic.List[string]]::new()
    foreach ($n in $Names) {
        if ([string]::IsNullOrWhiteSpace($n)) { continue }
        foreach ($part in ($n -split ',')) {
            $t = $part.Trim()
            if ($t) { $out.Add($t) }
        }
    }
    return @($out)
}

function Read-CoverageExcludeList {
    param(
        [string]$ExcludeFile,
        [string[]]$Exclude = @()
    )

    $set = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach ($e in (Expand-NameList $Exclude)) {
        [void]$set.Add($e)
    }

    if ($ExcludeFile -and (Test-Path -LiteralPath $ExcludeFile)) {
        Get-Content -LiteralPath $ExcludeFile | ForEach-Object {
            $line = $_.Trim()
            if (-not $line -or $line.StartsWith('#')) { return }
            [void]$set.Add($line)
        }
    }

    return @($set)
}

function Get-NovolisRepoDirectories {
    param(
        [Parameter(Mandatory)]
        [string]$Root,
        [string[]]$Exclude = @(),
        [string[]]$Include = @()
    )

    $excludeSet = [System.Collections.Generic.HashSet[string]]::new(
        [string[]]($Exclude | Where-Object { $_ }),
        [StringComparer]::OrdinalIgnoreCase)

    $includeSet = $null
    if ($Include -and $Include.Count -gt 0) {
        $includeSet = [System.Collections.Generic.HashSet[string]]::new(
            [string[]]($Include | Where-Object { $_ }),
            [StringComparer]::OrdinalIgnoreCase)
    }

    $dirs = [System.Collections.Generic.List[object]]::new()
    Get-ChildItem -LiteralPath $Root -Directory -Filter 'novolis-*' | Sort-Object Name | ForEach-Object {
        $name = $_.Name
        if ($excludeSet.Contains($name)) { return }
        if ($includeSet -and -not $includeSet.Contains($name)) { return }
        $dirs.Add([pscustomobject]@{ Name = $name; Path = $_.FullName })
    }
    return $dirs
}

function Test-NovolisTestHostProject {
    param([Parameter(Mandatory)][string]$ProjectPath)
    if ($ProjectPath -notmatch '[\\/]tests[\\/]') { return $false }
    $text = Get-Content -LiteralPath $ProjectPath -Raw
    # Support / helper libraries under tests/ (TestSupport) are not MTP hosts.
    if ($text -match '(?i)<IsTestProject>\s*false\s*</IsTestProject>') { return $false }
    if ($text -match '(?i)<IsTestingPlatformApplication>\s*false\s*</IsTestingPlatformApplication>') { return $false }
    return [bool](Select-String -LiteralPath $ProjectPath -Pattern 'TUnit|Microsoft\.NET\.Test\.Sdk|xunit|NUnit' -Quiet -SimpleMatch:$false)
}

function Get-NovolisTestHostProjects {
    param([Parameter(Mandatory)][string]$RepoPath)
    @(
        Get-ChildItem -LiteralPath $RepoPath -Recurse -Filter '*.csproj' -ErrorAction SilentlyContinue |
            Where-Object { Test-NovolisTestHostProject -ProjectPath $_.FullName } |
            ForEach-Object { $_.FullName }
    )
}

function Get-NovolisProductionProjects {
    param(
        [Parameter(Mandatory)][string]$RepoPath,
        [switch]$PackableOnly,
        [switch]$IncludeExecutables
    )

    $skipPath = [regex]'[\\/](tests|samples|benchmarks|tools|artifacts|obj|bin)[\\/]'
    $projects = [System.Collections.Generic.List[object]]::new()

    foreach ($dirName in @('src', 'codegen')) {
        $dir = Join-Path $RepoPath $dirName
        if (-not (Test-Path -LiteralPath $dir)) { continue }

        Get-ChildItem -LiteralPath $dir -Recurse -Filter '*.csproj' -ErrorAction SilentlyContinue | ForEach-Object {
            if ($skipPath.IsMatch($_.FullName)) { return }

            $text = Get-Content -LiteralPath $_.FullName -Raw
            if ($text -match '(?i)<IsTestProject>\s*true\s*</IsTestProject>') { return }
            if ($text -match '(?i)<OutputType>\s*(WinExe|Exe)\s*</OutputType>' -and -not $IncludeExecutables) { return }

            $isPackable = $true
            if ($text -match '(?i)<IsPackable>\s*false\s*</IsPackable>') {
                $isPackable = $false
            }
            if ($PackableOnly -and -not $isPackable) { return }

            $packageId = $null
            if ($text -match '(?i)<PackageId>\s*([^<]+)\s*</PackageId>') {
                $packageId = $Matches[1].Trim()
            }

            $projects.Add([pscustomobject]@{
                Path      = $_.FullName
                Name      = [IO.Path]::GetFileNameWithoutExtension($_.FullName)
                PackageId = if ($packageId) { $packageId } else { [IO.Path]::GetFileNameWithoutExtension($_.FullName) }
                Packable  = $isPackable
                RelPath   = $_.FullName.Substring($RepoPath.Length).TrimStart('\', '/')
            })
        }
    }

    return $projects
}

function Get-NovolisProjectReferenceTargets {
    param(
        [Parameter(Mandatory)][string]$ProjectPath,
        [Parameter(Mandatory)][string]$RepoPath
    )

    $dir = Split-Path $ProjectPath -Parent
    $targets = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    $text = Get-Content -LiteralPath $ProjectPath -Raw
    foreach ($m in [regex]::Matches($text, 'ProjectReference\s+Include="([^"]+)"')) {
        $raw = $m.Groups[1].Value -replace '/', '\'
        $resolved = [IO.Path]::GetFullPath((Join-Path $dir $raw))
        if ($resolved.StartsWith($RepoPath, [StringComparison]::OrdinalIgnoreCase)) {
            [void]$targets.Add($resolved)
        }
    }
    return @($targets)
}

function Get-NovolisReposWithTests {
    param(
        [Parameter(Mandatory)]
        [string]$Root,
        [string[]]$Exclude = @(),
        [string[]]$Include = @()
    )

    $repos = [System.Collections.Generic.List[object]]::new()
    foreach ($repo in (Get-NovolisRepoDirectories -Root $Root -Exclude $Exclude -Include $Include)) {
        $testProjects = @(Get-NovolisTestHostProjects -RepoPath $repo.Path)
        if ($testProjects.Count -eq 0) { continue }

        $slnx = Get-ChildItem -LiteralPath $repo.Path -Filter '*.slnx' -File -ErrorAction SilentlyContinue |
            Select-Object -First 1

        $repos.Add([pscustomobject]@{
            Name         = $repo.Name
            Path         = $repo.Path
            Solution     = if ($slnx) { $slnx.FullName } else { $null }
            TestProjects = $testProjects
        })
    }

    return $repos
}

function Get-NovolisPlatformSlnxPath {
    param(
        [Parameter(Mandatory)]
        [string]$Root
    )

    $buildCopy = Join-Path $Root 'novolis-governance\build\Novolis.Platform.slnx'
    if (Test-Path -LiteralPath $buildCopy) {
        return (Resolve-Path -LiteralPath $buildCopy).Path
    }

    $rootCopy = Join-Path $Root 'Novolis.Platform.slnx'
    if (Test-Path -LiteralPath $rootCopy) {
        return (Resolve-Path -LiteralPath $rootCopy).Path
    }

    throw "Novolis.Platform.slnx not found under $Root (expected novolis-governance\build\Novolis.Platform.slnx)."
}

function Get-NovolisGeneratePlatformSlnxScript {
    param(
        [Parameter(Mandatory)]
        [string]$Root
    )

    $script = Join-Path $Root 'novolis-governance\build\Generate-Platform-Slnx.ps1'
    if (-not (Test-Path -LiteralPath $script)) {
        throw "Generate-Platform-Slnx.ps1 not found: $script"
    }
    return (Resolve-Path -LiteralPath $script).Path
}

function Get-NovolisTestHostsFromPlatformSlnx {
    param(
        [Parameter(Mandatory)]
        [string]$Root,
        [Parameter(Mandatory)]
        [string]$SlnxPath,
        [string[]]$Exclude = @(),
        [string[]]$Include = @()
    )

    $excludeSet = [System.Collections.Generic.HashSet[string]]::new(
        [string[]]($Exclude | Where-Object { $_ }),
        [StringComparer]::OrdinalIgnoreCase)
    $includeSet = $null
    if ($Include -and $Include.Count -gt 0) {
        $includeSet = [System.Collections.Generic.HashSet[string]]::new(
            [string[]]($Include | Where-Object { $_ }),
            [StringComparer]::OrdinalIgnoreCase)
    }

    $slnxDir = Split-Path $SlnxPath -Parent
    # Paths in Novolis.Platform.slnx are relative to the workspace root, not the build folder.
    $workspaceRoot = $Root
    if ((Split-Path $slnxDir -Leaf) -eq 'build' -and
        (Split-Path (Split-Path $slnxDir -Parent) -Leaf) -eq 'novolis-governance') {
        $workspaceRoot = Split-Path (Split-Path $slnxDir -Parent) -Parent
    }

    $byRepo = [System.Collections.Generic.Dictionary[string, object]]::new([StringComparer]::OrdinalIgnoreCase)
    $text = Get-Content -LiteralPath $SlnxPath -Raw
    foreach ($m in [regex]::Matches($text, 'Project\s+Path="([^"]+\.csproj)"')) {
        $rel = ($m.Groups[1].Value -replace '/', '\')
        if ($rel -notmatch '(?i)(^|[\\/])tests([\\/])') { continue }

        $repoName = ($rel -split '[\\/]')[0]
        if (-not $repoName.StartsWith('novolis-', [StringComparison]::OrdinalIgnoreCase)) { continue }
        if ($excludeSet.Contains($repoName)) { continue }
        if ($includeSet -and -not $includeSet.Contains($repoName)) { continue }

        $full = [IO.Path]::GetFullPath((Join-Path $workspaceRoot $rel))
        if (-not (Test-Path -LiteralPath $full)) { continue }
        if (-not (Test-NovolisTestHostProject -ProjectPath $full)) { continue }

        if (-not $byRepo.ContainsKey($repoName)) {
            $byRepo[$repoName] = [pscustomobject]@{
                Name         = $repoName
                Path         = (Join-Path $workspaceRoot $repoName)
                Solution     = $SlnxPath
                TestProjects = [System.Collections.Generic.List[string]]::new()
            }
        }
        $list = $byRepo[$repoName].TestProjects
        if (-not ($list -contains $full)) {
            $list.Add($full)
        }
    }

    $repos = [System.Collections.Generic.List[object]]::new()
    foreach ($key in ($byRepo.Keys | Sort-Object)) {
        $entry = $byRepo[$key]
        $repos.Add([pscustomobject]@{
            Name         = $entry.Name
            Path         = $entry.Path
            Solution     = $entry.Solution
            TestProjects = @($entry.TestProjects)
        })
    }
    return $repos
}

function Get-CoberturaSummary {
    param(
        [Parameter(Mandatory)]
        [string]$CoberturaPath
    )

    [xml]$xml = Get-Content -LiteralPath $CoberturaPath -Raw
    $coverage = $xml.coverage
    $lineRate = [double]$coverage.'line-rate'
    $branchRate = [double]$coverage.'branch-rate'
    $linesCovered = [int]$coverage.'lines-covered'
    $linesValid = [int]$coverage.'lines-valid'
    $branchesCovered = [int]$coverage.'branches-covered'
    $branchesValid = [int]$coverage.'branches-valid'

    return [pscustomobject]@{
        LinePercent     = [math]::Round($lineRate * 100, 1)
        BranchPercent   = [math]::Round($branchRate * 100, 1)
        LinesCovered    = $linesCovered
        LinesValid      = $linesValid
        BranchesCovered = $branchesCovered
        BranchesValid   = $branchesValid
    }
}

function Ensure-ReportGenerator {
    if (Get-Command reportgenerator -ErrorAction SilentlyContinue) {
        return
    }

    Write-Host 'Installing dotnet-reportgenerator-globaltool...' -ForegroundColor Yellow
    dotnet tool install -g dotnet-reportgenerator-globaltool | Out-Host
    if ($LASTEXITCODE -ne 0) {
        throw 'Failed to install reportgenerator. Install manually: dotnet tool install -g dotnet-reportgenerator-globaltool'
    }

    if (-not (Get-Command reportgenerator -ErrorAction SilentlyContinue)) {
        $tools = Join-Path $env:USERPROFILE '.dotnet\tools'
        if (Test-Path (Join-Path $tools 'reportgenerator.exe')) {
            $env:PATH = "$tools$([IO.Path]::PathSeparator)$env:PATH"
        }
    }

    if (-not (Get-Command reportgenerator -ErrorAction SilentlyContinue)) {
        throw 'reportgenerator not found on PATH after install.'
    }
}
