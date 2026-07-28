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

function Get-NovolisReposWithTests {
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

    $repos = [System.Collections.Generic.List[object]]::new()
    Get-ChildItem -LiteralPath $Root -Directory -Filter 'novolis-*' | Sort-Object Name | ForEach-Object {
        $name = $_.Name
        if ($excludeSet.Contains($name)) { return }
        if ($includeSet -and -not $includeSet.Contains($name)) { return }

        $testProjects = @(
            Get-ChildItem -LiteralPath $_.FullName -Recurse -Filter '*.csproj' -ErrorAction SilentlyContinue |
                Where-Object {
                    $_.FullName -match '[\\/]tests[\\/]' -and
                    (Select-String -LiteralPath $_.FullName -Pattern 'TUnit|Microsoft\.NET\.Test\.Sdk|xunit|NUnit' -Quiet)
                }
        )
        if ($testProjects.Count -eq 0) { return }

        $slnx = Get-ChildItem -LiteralPath $_.FullName -Filter '*.slnx' -File -ErrorAction SilentlyContinue |
            Select-Object -First 1

        $repos.Add([pscustomobject]@{
            Name         = $name
            Path         = $_.FullName
            Solution     = if ($slnx) { $slnx.FullName } else { $null }
            TestProjects = @($testProjects | ForEach-Object { $_.FullName })
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
