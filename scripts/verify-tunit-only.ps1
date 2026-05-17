# Fails if novolis-* repos reference forbidden test packages or patterns in source/proj files.
$ErrorActionPreference = 'Stop'
$root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$patterns = @(
    'FluentAssertions',
    'PackageReference Include="xunit"',
    'PackageVersion Include="xunit"',
    'using Xunit',
    '\[Fact\]'
)
$hits = @()
Get-ChildItem -Path $root -Directory -Filter 'novolis-*' | ForEach-Object {
    $repo = $_.FullName
    Get-ChildItem -Path $repo -Recurse -Include '*.cs','*.csproj','Directory.Packages.props' -File |
        Where-Object { $_.FullName -notmatch '\\(bin|obj|artifacts|\.git)\\' } |
        ForEach-Object {
            $content = Get-Content $_.FullName -Raw -ErrorAction SilentlyContinue
            if (-not $content) { return }
            foreach ($p in $patterns) {
                if ($content -match $p) {
                    $hits += "$($_.FullName): $p"
                }
            }
        }
}
if ($hits.Count -gt 0) {
    Write-Error ("TUnit-only verification failed:`n" + ($hits -join "`n"))
}
Write-Host "TUnit-only verification passed for novolis-* repos."
