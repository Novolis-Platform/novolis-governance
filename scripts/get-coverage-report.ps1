#Requires -Version 7.0
<#
.SYNOPSIS
  Collect test coverage across novolis-* repos in parallel and emit a nice report.

.DESCRIPTION
  Uses the .NET SDK / Microsoft Testing Platform built-in coverage flags
  (`dotnet test --coverage`) — no coverlet package required on test projects.

  Per-repo Cobertura files are merged with ReportGenerator into HTML + Markdown
  under the output directory.

  Platform mode (-PlatformSlnx) regenerates/uses Novolis.Platform.slnx and runs
  test hosts with NovolisUseProjectReferences=true (local source coverage gate).

.PARAMETER Root
  Org checkout root (default NOVOLIS_ROOT or parent of governance).

.PARAMETER Exclude
  Extra repo folder names to skip (merged with -ExcludeFile).

.PARAMETER ExcludeFile
  Text file of excluded repo names (default scripts/coverage-excludes.txt).

.PARAMETER Include
  If set, only these repos run (still respects -Exclude).

.PARAMETER ThrottleLimit
  Max parallel repos (default: ProcessorCount - 1, min 1).

.PARAMETER Configuration
  Build/test configuration (default Release).

.PARAMETER OutputDir
  Coverage artifacts root (default <Root>/artifacts/coverage).

.PARAMETER SkipBuild
  Skip `dotnet build` (use when already built).

.PARAMETER ListRepos
  Print selected repos and exit.

.PARAMETER FailBelow
  Fail if aggregate line OR branch coverage is below this percent (0 = disabled).
  When -PlatformSlnx is set and FailBelow is left at 0, defaults to 95.

.PARAMETER OpenReport
  Open the HTML index after generation (Windows).

.PARAMETER PlatformSlnx
  Evaluate coverage against Novolis.Platform.slnx with ProjectReference mode.

.PARAMETER RegenerateSlnx
  With -PlatformSlnx, run Generate-Platform-Slnx.ps1 before collecting coverage.

.PARAMETER PlatformSlnxPath
  Explicit path to Novolis.Platform.slnx (default: workspace-root copy).

.EXAMPLE
  pwsh -File novolis-governance/scripts/get-coverage-report.ps1

.EXAMPLE
  pwsh -File novolis-governance/scripts/get-coverage-report.ps1 -Include novolis-astro,novolis-io -OpenReport

.EXAMPLE
  pwsh -File novolis-governance/scripts/get-coverage-report.ps1 -Exclude novolis-raylib,novolis-audio -ThrottleLimit 6

.EXAMPLE
  pwsh -File novolis-governance/scripts/get-coverage-report.ps1 -PlatformSlnx -RegenerateSlnx
#>
param(
    [string]$Root = '',
    [string[]]$Exclude = @(),
    [string]$ExcludeFile = '',
    [string[]]$Include = @(),
    [int]$ThrottleLimit = 0,
    [string]$Configuration = 'Release',
    [string]$OutputDir = '',
    [switch]$SkipBuild,
    [switch]$ListRepos,
    [double]$FailBelow = 0,
    [switch]$OpenReport,
    [switch]$PlatformSlnx,
    [switch]$RegenerateSlnx,
    [string]$PlatformSlnxPath = ''
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
    $OutputDir = Join-Path $Root 'artifacts\coverage'
}

# Platform org gate defaults to 95% when caller did not set FailBelow.
if ($PlatformSlnx -and $FailBelow -eq 0) {
    $FailBelow = 95
}

$excludeList = Read-CoverageExcludeList -ExcludeFile $ExcludeFile -Exclude $Exclude
$includeList = Expand-NameList $Include

$projectRef = 'false'
$platformSolution = $null

if ($PlatformSlnx) {
    if ($RegenerateSlnx) {
        $gen = Get-NovolisGeneratePlatformSlnxScript -Root $Root
        Write-Host "Regenerating Novolis.Platform.slnx..." -ForegroundColor Cyan
        & pwsh -NoProfile -File $gen -WorkspaceRoot $Root
        if ($LASTEXITCODE -ne 0) {
            throw "Generate-Platform-Slnx.ps1 failed (exit $LASTEXITCODE)"
        }
    }

    if ($PlatformSlnxPath) {
        $platformSolution = (Resolve-Path -LiteralPath $PlatformSlnxPath).Path
    }
    else {
        $platformSolution = Get-NovolisPlatformSlnxPath -Root $Root
    }

    $projectRef = 'true'
    $repos = @(Get-NovolisTestHostsFromPlatformSlnx -Root $Root -SlnxPath $platformSolution -Exclude $excludeList -Include $includeList)
}
else {
    if ($RegenerateSlnx) {
        Write-Warning '-RegenerateSlnx is ignored unless -PlatformSlnx is set.'
    }
    $repos = @(Get-NovolisReposWithTests -Root $Root -Exclude $excludeList -Include $includeList)
}

Write-Host "Coverage root: $Root" -ForegroundColor White
Write-Host "Output:        $OutputDir"
Write-Host "Throttle:      $ThrottleLimit"
Write-Host "Mode:          $(if ($PlatformSlnx) { 'Platform.slnx ProjectRef' } else { 'NuGet per-repo' })"
if ($platformSolution) {
    Write-Host "Solution:      $platformSolution"
}
Write-Host "ProjectRef:    $projectRef"
Write-Host "FailBelow:     $FailBelow"
Write-Host "Excluded:      $($excludeList -join ', ')"
Write-Host "Repos:         $($repos.Count)"
Write-Host ''

if ($ListRepos) {
    $repos | ForEach-Object {
        [pscustomobject]@{
            Repo         = $_.Name
            TestProjects = $_.TestProjects.Count
            Solution     = if ($_.Solution) { Split-Path $_.Solution -Leaf } else { '(none)' }
        }
    } | Format-Table -AutoSize
    exit 0
}

if ($repos.Count -eq 0) {
    Write-Host 'No repos with test projects matched (check -Include / -Exclude).' -ForegroundColor Yellow
    exit 0
}

New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null
$rawDir = Join-Path $OutputDir 'raw'
$reportDir = Join-Path $OutputDir 'report'
$logsDir = Join-Path $OutputDir 'logs'
New-Item -ItemType Directory -Force -Path $rawDir, $reportDir, $logsDir | Out-Null

# Fresh raw outputs for this run
Get-ChildItem -LiteralPath $rawDir -Filter '*.cobertura.xml' -Recurse -ErrorAction SilentlyContinue |
    Remove-Item -Force

$started = Get-Date

# Platform mode builds per-repo in the parallel loop (ProjectRef=true) so one host
# failure does not abort the entire org run. The platform slnx is used for host discovery.

$repoWork = $repos | ForEach-Object {
    [pscustomobject]@{
        Name         = $_.Name
        Path         = $_.Path
        Solution     = $_.Solution
        TestProjects = $_.TestProjects
        RepoRawDir   = (Join-Path $rawDir $_.Name)
        LogPath      = (Join-Path $logsDir "$($_.Name).log")
    }
}

$results = $repoWork | ForEach-Object -ThrottleLimit $ThrottleLimit -Parallel {
    $ErrorActionPreference = 'Continue'
    $repo = $_
    $cfg = $using:Configuration
    $skipBuild = $using:SkipBuild
    $projectRef = $using:projectRef

    New-Item -ItemType Directory -Force -Path $repo.RepoRawDir | Out-Null
    $log = [System.Collections.Generic.List[string]]::new()
    $sw = [System.Diagnostics.Stopwatch]::StartNew()

    $status = 'ok'
    $errorText = ''
    $coberturaFiles = [System.Collections.Generic.List[string]]::new()
    $testsPassed = 0
    $testsFailed = 0
    $testsTotal = 0

    try {
        Push-Location $repo.Path
        try {
            # NuGet mode: coverage measures published packages; build each test host.
            # Platform mode: same loop with ProjectRef=true (hosts discovered from Platform.slnx).
            # Do not pass --configfile: exclusive repo nuget.config drops user GPR credentials.

            if (-not $skipBuild) {
                $log.Add(("[{0:HH:mm:ss}] build test hosts {1} (ProjectRef={2})" -f (Get-Date), $cfg, $projectRef))
                foreach ($proj in $repo.TestProjects) {
                    $buildOut = & dotnet build $proj -c $cfg --nologo "-p:NovolisUseProjectReferences=$projectRef" 2>&1 | Out-String
                    $log.Add($buildOut)
                    if ($LASTEXITCODE -ne 0) {
                        throw "build failed for $([IO.Path]::GetFileNameWithoutExtension($proj)) (exit $LASTEXITCODE)"
                    }
                }
            }

            $index = 0
            foreach ($proj in $repo.TestProjects) {
                $index++
                $leaf = [IO.Path]::GetFileNameWithoutExtension($proj)
                $outFile = Join-Path $repo.RepoRawDir ("{0:D2}-{1}.cobertura.xml" -f $index, $leaf)
                $log.Add(("[{0:HH:mm:ss}] test+coverage {1}" -f (Get-Date), $leaf))

                # Do not pass --nologo: MTP treats it as an unknown arg and runs zero tests (exit 5).
                $testArgs = @(
                    'test'
                    '--project', $proj
                    '-c', $cfg
                    "-p:NovolisUseProjectReferences=$projectRef"
                    '--coverage'
                    '--coverage-output-format', 'cobertura'
                    '--coverage-output', $outFile
                )
                if ($skipBuild) {
                    $testArgs += '--no-build'
                }

                $testOut = & dotnet @testArgs 2>&1 | Out-String
                $log.Add($testOut)

                if ($testOut -match 'total:\s*(\d+)') { $testsTotal += [int]$Matches[1] }
                if ($testOut -match 'succeeded:\s*(\d+)') { $testsPassed += [int]$Matches[1] }
                if ($testOut -match 'failed:\s*(\d+)') { $testsFailed += [int]$Matches[1] }

                if ($LASTEXITCODE -ne 0) {
                    throw "dotnet test failed for $leaf (exit $LASTEXITCODE)"
                }

                if (Test-Path -LiteralPath $outFile) {
                    $coberturaFiles.Add($outFile)
                }
                else {
                    $alt = $outFile -replace '\.cobertura\.xml$', ''
                    if (Test-Path -LiteralPath $alt) {
                        Move-Item -LiteralPath $alt -Destination $outFile -Force
                        $coberturaFiles.Add($outFile)
                    }
                    else {
                        $log.Add(("[{0:HH:mm:ss}] WARN: coverage file missing for {1}" -f (Get-Date), $leaf))
                    }
                }
            }

            if ($coberturaFiles.Count -eq 0) {
                throw 'no cobertura files produced'
            }
        }
        finally {
            Pop-Location
        }
    }
    catch {
        $status = 'fail'
        $errorText = $_.Exception.Message
        if (-not $errorText) { $errorText = "$_" }
        $log.Add("[$(Get-Date -Format 'HH:mm:ss')] ERROR: $errorText")
    }
    finally {
        $sw.Stop()
        ($log -join [Environment]::NewLine) | Set-Content -LiteralPath $repo.LogPath -Encoding utf8
    }

    [pscustomobject]@{
        Repo            = $repo.Name
        Status          = $status
        Error           = $errorText
        Seconds         = [math]::Round($sw.Elapsed.TotalSeconds, 1)
        CoberturaFiles  = @($coberturaFiles)
        TestsTotal      = $testsTotal
        TestsPassed     = $testsPassed
        TestsFailed     = $testsFailed
        LogPath         = $repo.LogPath
    }
}

# Per-repo merged cobertura via ReportGenerator (HtmlSummary optional later)
Ensure-ReportGenerator

$repoRows = [System.Collections.Generic.List[object]]::new()
$allCobertura = [System.Collections.Generic.List[string]]::new()

foreach ($r in ($results | Sort-Object Repo)) {
    $linePct = $null
    $branchPct = $null
    $linesCovered = 0
    $linesValid = 0

    if ($r.Status -eq 'ok' -and $r.CoberturaFiles.Count -gt 0) {
        foreach ($f in $r.CoberturaFiles) { $allCobertura.Add($f) }

        $repoReport = Join-Path $reportDir $r.Repo
        New-Item -ItemType Directory -Force -Path $repoReport | Out-Null
        $merged = Join-Path $repoReport 'Cobertura.xml'
        $reportsArg = ($r.CoberturaFiles -join ';')
        $assemblyFilter = Get-RepoAssemblyFilter -RepoName $r.Repo
        & reportgenerator `
            "-reports:$reportsArg" `
            "-targetdir:$repoReport" `
            '-reporttypes:Cobertura;TextSummary' `
            "-title:$($r.Repo)" `
            "-filefilters:-*MessagePack.SourceGenerator*;-*.g.cs" `
            "-classfilters:-*.Tests*;-*Test;-*Tests;-MessagePack.*;-Frank.*" `
            "-assemblyfilters:$assemblyFilter" | Out-Null

        if (Test-Path -LiteralPath $merged) {
            $sum = Get-CoberturaSummary -CoberturaPath $merged
            $linePct = $sum.LinePercent
            $branchPct = $sum.BranchPercent
            $linesCovered = $sum.LinesCovered
            $linesValid = $sum.LinesValid
        }
        elseif ($r.CoberturaFiles.Count -eq 1) {
            $sum = Get-CoberturaSummary -CoberturaPath $r.CoberturaFiles[0]
            $linePct = $sum.LinePercent
            $branchPct = $sum.BranchPercent
            $linesCovered = $sum.LinesCovered
            $linesValid = $sum.LinesValid
        }
    }

    $repoRows.Add([pscustomobject]@{
        Repo          = $r.Repo
        Status        = $r.Status
        LinePct       = if ($null -eq $linePct) { $null } else { [double]$linePct }
        BranchPct     = if ($null -eq $branchPct) { $null } else { [double]$branchPct }
        LinePctText   = if ($null -eq $linePct) { '—' } else { $linePct.ToString('0.0', [Globalization.CultureInfo]::InvariantCulture) }
        BranchPctText = if ($null -eq $branchPct) { '—' } else { $branchPct.ToString('0.0', [Globalization.CultureInfo]::InvariantCulture) }
        Lines         = if ($linesValid -gt 0) { "$linesCovered/$linesValid" } else { '' }
        Tests         = if ($r.TestsTotal -gt 0) { "$($r.TestsPassed)/$($r.TestsTotal)" } else { '' }
        Seconds       = $r.Seconds
        Error         = $r.Error
    })
}

# Aggregate HTML report
$aggregateOk = $false
$aggLine = $null
$aggBranch = $null
if ($allCobertura.Count -gt 0) {
    $reportsArg = ($allCobertura -join ';')
    Write-Host ''
    Write-Host "Merging $($allCobertura.Count) cobertura file(s) with ReportGenerator..." -ForegroundColor Cyan
    & reportgenerator `
        "-reports:$reportsArg" `
        "-targetdir:$reportDir" `
        '-reporttypes:Html;HtmlSummary;MarkdownSummaryGithub;TextSummary;Cobertura' `
        '-title:Novolis coverage' `
        "-filefilters:-*MessagePack.SourceGenerator*;-*.g.cs" `
        "-classfilters:-*.Tests*;-*Test;-*Tests;-MessagePack.*;-Frank.*" `
        "-assemblyfilters:-Novolis.Analyzers.Licensing" | Out-Host

    $aggCob = Join-Path $reportDir 'Cobertura.xml'
    if (Test-Path -LiteralPath $aggCob) {
        $agg = Get-CoberturaSummary -CoberturaPath $aggCob
        $aggLine = $agg.LinePercent
        $aggBranch = $agg.BranchPercent
        $aggregateOk = $true
    }
}

$elapsed = [math]::Round(((Get-Date) - $started).TotalSeconds, 1)
$failedRepos = @($repoRows | Where-Object Status -eq 'fail')

# Console report
Write-Host ''
Write-Host '=== Coverage by repo ===' -ForegroundColor Cyan
$repoRows |
    Sort-Object @{ Expression = { if ($null -eq $_.LinePct) { -1 } else { $_.LinePct } }; Descending = $true } |
    Format-Table Repo, Status, LinePctText, BranchPctText, Lines, Tests, Seconds -AutoSize

# Markdown summary for agents / PRs
$mdPath = Join-Path $OutputDir 'SUMMARY.md'
$md = [System.Collections.Generic.List[string]]::new()
$md.Add('# Novolis coverage report')
$md.Add('')
$md.Add("Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
$modeLabel = if ($PlatformSlnx) { 'Platform.slnx ProjectRef' } else { 'NuGet per-repo' }
$md.Add("Duration: ${elapsed}s  |  Repos: $($repoRows.Count)  |  Throttle: $ThrottleLimit  |  Mode: $modeLabel")
if ($platformSolution) {
    $md.Add("Solution: $platformSolution")
}
if ($aggregateOk) {
    $aggLineText = $aggLine.ToString('0.0', [Globalization.CultureInfo]::InvariantCulture)
    $aggBranchText = $aggBranch.ToString('0.0', [Globalization.CultureInfo]::InvariantCulture)
    $md.Add("**Aggregate line: ${aggLineText}%**  |  **branch: ${aggBranchText}%**")
}
$md.Add('')
$md.Add('| Repo | Status | Line % | Branch % | Lines | Tests | Seconds |')
$md.Add('|------|--------|--------|----------|-------|-------|---------|')
foreach ($row in ($repoRows | Sort-Object Repo)) {
    $md.Add("| $($row.Repo) | $($row.Status) | $($row.LinePctText) | $($row.BranchPctText) | $($row.Lines) | $($row.Tests) | $($row.Seconds) |")
}
if ($failedRepos.Count -gt 0) {
    $md.Add('')
    $md.Add('## Failures')
    foreach ($f in $failedRepos) {
        $md.Add("- **$($f.Repo)**: $($f.Error) (log: `logs/$($f.Repo).log`)")
    }
}
$md.Add('')
$md.Add("HTML report: [report/index.html](report/index.html)")
($md -join [Environment]::NewLine) | Set-Content -LiteralPath $mdPath -Encoding utf8

# JSON for tooling
$jsonPath = Join-Path $OutputDir 'summary.json'
[pscustomobject]@{
    GeneratedUtc    = (Get-Date).ToUniversalTime().ToString('o')
    DurationSeconds = $elapsed
    ThrottleLimit   = $ThrottleLimit
    Mode            = $modeLabel
    PlatformSlnx    = $platformSolution
    FailBelow       = $FailBelow
    AggregateLine   = $aggLine
    AggregateBranch = $aggBranch
    Repos           = @($repoRows)
} | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $jsonPath -Encoding utf8

Write-Host ''
Write-Host "Summary:  $mdPath" -ForegroundColor Green
Write-Host "JSON:     $jsonPath"
Write-Host "HTML:     $(Join-Path $reportDir 'index.html')"
if ($aggregateOk) {
    Write-Host "Aggregate line coverage: ${aggLine}%  branch: ${aggBranch}%" -ForegroundColor Green
}
Write-Host "Elapsed: ${elapsed}s"

if ($OpenReport) {
    $index = Join-Path $reportDir 'index.html'
    if (Test-Path -LiteralPath $index) {
        Start-Process $index
    }
}

if ($failedRepos.Count -gt 0) {
    Write-Host ''
    Write-Host "FAILED repos ($($failedRepos.Count)):" -ForegroundColor Red
    $failedRepos | ForEach-Object { Write-Host "  - $($_.Repo): $($_.Error)" }
    exit 1
}

if ($FailBelow -gt 0) {
    # Prefer per-repo filtered metrics (home assemblies only). The merged HTML aggregate
    # also contains ProjectRef transitive packages (e.g. Novolis.IO.*) and must not gate.
    $reposWithMetrics = @($repoRows | Where-Object { $null -ne $_.LinePct -or $null -ne $_.BranchPct })
    if ($reposWithMetrics.Count -gt 0) {
        $below = @($reposWithMetrics | Where-Object {
            ($null -ne $_.LinePct -and $_.LinePct -lt $FailBelow) -or
            ($null -ne $_.BranchPct -and $_.BranchPct -lt $FailBelow)
        })
        if ($below.Count -gt 0) {
            foreach ($b in $below) {
                Write-Host ("Repo {0} coverage line={1}% branch={2}% is below FailBelow={3}%." -f `
                    $b.Repo, $b.LinePctText, $b.BranchPctText, $FailBelow) -ForegroundColor Red
            }
            exit 1
        }
    }
    elseif ($aggregateOk) {
        if ($null -ne $aggLine -and $aggLine -lt $FailBelow) {
            Write-Host "Aggregate line coverage ${aggLine}% is below FailBelow=${FailBelow}%." -ForegroundColor Red
            exit 1
        }
        if ($null -ne $aggBranch -and $aggBranch -lt $FailBelow) {
            Write-Host "Aggregate branch coverage ${aggBranch}% is below FailBelow=${FailBelow}%." -ForegroundColor Red
            exit 1
        }
    }
}

exit 0
