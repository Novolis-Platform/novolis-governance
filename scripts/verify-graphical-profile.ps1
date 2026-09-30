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
