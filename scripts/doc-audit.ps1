#Requires -Version 7.0
<#
.SYNOPSIS
  Audits packable library projects for package README and documentation MSBuild settings.

.PARAMETER RepoRoot
  Root of a novolis-* repository (scans src/ and codegen/ when present).

.PARAMETER RequireDocumentationProps
  When set, fails if GenerateDocumentationFile is not enabled for packable projects.
#>
param(
    [Parameter(Mandatory = $true)]
    [string] $RepoRoot,

    [switch] $RequireDocumentationProps
)

$ErrorActionPreference = 'Stop'
$RepoRoot = (Resolve-Path $RepoRoot).Path

$scanRoots = [System.Collections.Generic.List[string]]::new()
$src = Join-Path $RepoRoot 'src'
$codegen = Join-Path $RepoRoot 'codegen'
if (Test-Path $src) { $scanRoots.Add($src) }
if (Test-Path $codegen) { $scanRoots.Add($codegen) }
if ($scanRoots.Count -eq 0) {
    Write-Error "No src/ or codegen/ under $RepoRoot"
}

$marker = Join-Path $RepoRoot 'build\.novolis-documentation-complete'
$enforceDocs = $RequireDocumentationProps -or (Test-Path $marker)

$failures = [System.Collections.Generic.List[string]]::new()
$projects = [System.Collections.Generic.List[System.IO.FileInfo]]::new()
foreach ($root in $scanRoots) {
    Get-ChildItem -Path $root -Recurse -Filter '*.csproj' -File | ForEach-Object { $projects.Add($_) }
}

function Test-IsPackableProject {
    param([System.IO.FileInfo] $Proj)
    if ($Proj.FullName -match '[\\/]tests[\\/]') { return $false }
    if ($Proj.FullName -match '[\\/]content[\\/]') { return $false }
    [xml]$xml = Get-Content -LiteralPath $Proj.FullName -Raw
    $packableNode = $xml.Project.PropertyGroup.IsPackable | Select-Object -First 1
    if ($packableNode -and $packableNode -eq 'false') { return $false }
    return $true
}

foreach ($proj in $projects) {
    if (-not (Test-IsPackableProject $proj)) { continue }

    $dir = $proj.DirectoryName
    $readme = Join-Path $dir 'README.md'
    if (-not (Test-Path $readme)) {
        $failures.Add("Missing README.md: $($proj.FullName)")
    }
    else {
        $readmeText = Get-Content $readme -Raw
        if ($readmeText -match 'See docs/getting-started\.md for integration') {
            $failures.Add("Placeholder quick start in README.md: $($proj.FullName)")
        }
        $hasInstall = $readmeText -match '## Install' -or $readmeText -match 'dotnet add package' -or $readmeText -match 'PackageReference Include='
        $hasQuickStart = $readmeText -match '## Quick start' -or $readmeText -match '## Example' -or $readmeText -match '## Getting started' -or $readmeText -match '## Usage'
        if (-not $hasInstall -or -not $hasQuickStart) {
            $failures.Add("README.md missing Install or Quick start section: $($proj.FullName)")
        }
    }

    if ($enforceDocs) {
        [xml]$xml = Get-Content -LiteralPath $proj.FullName -Raw
        $hasGenDoc = $false
        foreach ($pg in $xml.Project.PropertyGroup) {
            if ($pg.GenerateDocumentationFile -eq 'true') { $hasGenDoc = $true }
        }
        if (-not $hasGenDoc) {
            $repoBuild = Join-Path $RepoRoot 'build'
            $text = ''
            foreach ($root in $scanRoots) {
                $dbp = Join-Path $root 'Directory.Build.props'
                if (Test-Path $dbp) { $text += Get-Content $dbp -Raw }
            }
            Get-ChildItem -Path $repoBuild -Filter '*.props' -ErrorAction SilentlyContinue | ForEach-Object {
                $text += Get-Content $_.FullName -Raw
            }
            if ($text -match 'GenerateDocumentationFile\s*>\s*true') { $hasGenDoc = $true }
            if ($text -match 'Novolis\.Documentation\.props') { $hasGenDoc = $true }
        }
        if (-not $hasGenDoc) {
            $failures.Add("GenerateDocumentationFile not enabled: $($proj.FullName)")
        }
    }
}

if ($failures.Count -gt 0) {
    Write-Host "doc-audit FAILED ($($failures.Count) issue(s)) in $RepoRoot" -ForegroundColor Red
    $failures | ForEach-Object { Write-Host "  $_" }
    exit 1
}

Write-Host "doc-audit OK: $($projects.Count) csproj under src/ and codegen/ in $RepoRoot"
exit 0
