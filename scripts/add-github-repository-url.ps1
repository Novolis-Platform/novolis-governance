#Requires -Version 7.0
$ErrorActionPreference = 'Stop'
$Root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent

$githubImport = @'
  <Import Project="$(MSBuildThisFileDirectory)..\novolis-governance\build\Novolis.GitHubPackages.props"
          Condition="Exists('$(MSBuildThisFileDirectory)..\novolis-governance\build\Novolis.GitHubPackages.props')" />
'@

$repos = Get-ChildItem $Root -Directory -Filter 'novolis-*' |
    Where-Object { $_.Name -notmatch 'dogfooding|workflows|governance|registry|installer' }

foreach ($repo in $repos) {
    $name = $repo.Name
    $props = Join-Path $repo.FullName 'Directory.Build.props'
    if (-not (Test-Path $props)) { continue }

    Push-Location $repo.FullName
    $restored = $false
    if (Test-Path .git) {
        git checkout -- Directory.Build.props 2>$null
        if ($LASTEXITCODE -eq 0) { $restored = $true }
    }
    Pop-Location
    if (-not $restored) { Write-Warning "Skip (no git restore): $name"; continue }

    $text = Get-Content $props -Raw
    if ($text -notmatch 'NovolisGitHubRepository') {
        $block = "  <PropertyGroup>`r`n    <NovolisGitHubRepository>$name</NovolisGitHubRepository>`r`n  </PropertyGroup>`r`n"
        $text = $text -replace '(<Project>\s*)', "`$1$block"
    }
    if ($text -notmatch 'Novolis\.GitHubPackages\.props') {
        $text = $text -replace '\s*</Project>\s*$', "`r`n$githubImport`r`n</Project>`r`n"
    }
    $text = $text -replace '(?s)\s*<Import Project="\$\(MSBuildThisFileDirectory\)\.\.\\novolis-governance\\build\\Novolis\.GitHubPackages\.props"[^/]*/>\s*</Project>\s*<Import Project="\$\(MSBuildThisFileDirectory\)\.\.\\novolis-governance\\build\\Novolis\.GitHubPackages\.props"[^/]*/>\s*</Project>', "`r`n$githubImport`r`n</Project>"
    Set-Content $props $text.TrimEnd() -Encoding utf8NoBOM
    Write-Host $name
}
Write-Host 'Done.'
