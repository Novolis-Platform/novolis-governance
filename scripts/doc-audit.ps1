#Requires -Version 7.0
<#
.SYNOPSIS
  Audits packable library projects for package README and documentation MSBuild settings.

.PARAMETER RepoRoot
  Root of a novolis-* repository (contains src/).

.PARAMETER RequireDocumentationProps
  When set, fails if GenerateDocumentationFile is not enabled for packable src projects.
#>
param(
    [Parameter(Mandatory = $true)]
    [string] $RepoRoot,

    [switch] $RequireDocumentationProps
)

$ErrorActionPreference = 'Stop'
$RepoRoot = (Resolve-Path $RepoRoot).Path
$src = Join-Path $RepoRoot 'src'
if (-not (Test-Path $src)) {
    Write-Error "No src/ under $RepoRoot"
}

$marker = Join-Path $RepoRoot 'build\.novolis-documentation-complete'
$enforceDocs = $RequireDocumentationProps -or (Test-Path $marker)

$failures = [System.Collections.Generic.List[string]]::new()
$projects = Get-ChildItem -Path $src -Recurse -Filter '*.csproj' -File

foreach ($proj in $projects) {
    [xml]$xml = Get-Content -LiteralPath $proj.FullName -Raw
    $ns = New-Object System.Xml.XmlNamespaceManager($xml.NameTable)
    $isPackable = $true
    $packableNode = $xml.Project.PropertyGroup.IsPackable | Select-Object -First 1
    if ($packableNode -and $packableNode -eq 'false') { $isPackable = $false }
    if ($proj.FullName -match '[\\/]tests[\\/]') { $isPackable = $false }
    if ($proj.FullName -match '[\\/]content[\\/]') { continue }
    if (-not $isPackable) { continue }

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
        $hasGenDoc = $false
        foreach ($pg in $xml.Project.PropertyGroup) {
            if ($pg.GenerateDocumentationFile -eq 'true') { $hasGenDoc = $true }
        }
        if (-not $hasGenDoc) {
            # May be inherited from Directory.Build.props — dotnet msbuild evaluation is heavy; check repo marker + build props
            $repoBuild = Join-Path $RepoRoot 'build'
            $dbp = Join-Path $src 'Directory.Build.props'
            $text = ''
            if (Test-Path $dbp) { $text += Get-Content $dbp -Raw }
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

Write-Host "doc-audit OK: $($projects.Count) csproj scanned under $RepoRoot"
exit 0
