[CmdletBinding()]
param(
    [string]$WorkspaceRoot = (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
)

$ErrorActionPreference = 'Stop'
$governanceRoot = Join-Path $WorkspaceRoot 'novolis-governance'
$appsRoot = Join-Path $WorkspaceRoot 'novolis-apps'
$exporter = Join-Path $governanceRoot 'scripts\Export-GraphicalProfile.ps1'
$failures = [System.Collections.Generic.List[string]]::new()

& $exporter -Check
if (-not $?) {
    $failures.Add('Generated graphical profile token sources are stale.')
}

$githubRoot = Join-Path $WorkspaceRoot '.github'
$bannerDir = Join-Path $githubRoot 'brand\banners'
$catalogPath = Join-Path $githubRoot 'site\repo-catalog.json'
$requiredStems = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)

if (-not (Test-Path $catalogPath)) {
    $failures.Add("Missing generated catalog: $catalogPath")
} else {
    $catalog = Get-Content -Raw -Path $catalogPath | ConvertFrom-Json
    foreach ($property in $catalog.psobject.Properties) {
        $stem = if ($property.Name -eq '.github') { 'github-org' } else { $property.Name }
        [void]$requiredStems.Add($stem)
    }
}

try {
    $repos = gh repo list Novolis-Platform --limit 200 --json name,isArchived,visibility 2>$null | ConvertFrom-Json
    foreach ($repo in @($repos)) {
        if ($repo.isArchived) { continue }
        if ($repo.visibility -and $repo.visibility -ne 'PUBLIC') { continue }
        $stem = if ($repo.name -eq '.github') { 'github-org' } else { $repo.name }
        [void]$requiredStems.Add($stem)
    }
} catch {
    Write-Host 'verify-graphical-profile: skipped live org repo list (gh unavailable).'
}

foreach ($stem in ($requiredStems | Sort-Object)) {
    $bannerPath = Join-Path $bannerDir "$stem.svg"
    if (-not (Test-Path $bannerPath)) {
        $failures.Add("Missing banner: $bannerPath")
    }
}

if (Test-Path $appsRoot) {
    foreach ($project in Get-ChildItem -Path (Join-Path $appsRoot 'src') -Filter '*.csproj' -Recurse) {
        $text = Get-Content -Raw -Path $project.FullName
        if ($text -match '<IsTestProject>\s*true\s*</IsTestProject>') {
            continue
        }

        $isMaui = $text -match '<UseMaui>\s*true\s*</UseMaui>'
        $isAvalonia = $text -match '<PackageReference\s+Include="Avalonia'
        if (-not ($isMaui -or $isAvalonia)) {
            continue
        }

        $expected = if ($isMaui) {
            'Novolis.Maui.GraphicalProfile'
        } else {
            'Novolis.Avalonia.GraphicalProfile'
        }

        if ($text -notmatch [regex]::Escape($expected)) {
            $failures.Add("$($project.FullName) is missing $expected.")
        }
    }
}

if ($failures.Count -gt 0) {
    Write-Host 'verify-graphical-profile: FAILED' -ForegroundColor Red
    $failures | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
    exit 1
}

Write-Host 'verify-graphical-profile: OK' -ForegroundColor Green
