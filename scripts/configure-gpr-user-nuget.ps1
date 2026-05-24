<#
.SYNOPSIS
  Configure GitHub Packages credentials in the user-level NuGet.Config (machine-wide for your account).

.DESCRIPTION
  Repo nuget.config files only declare feed URLs and packageSourceMapping (Novolis.* -> github).
  Credentials belong in %APPDATA%\NuGet\NuGet.Config so every Novolis repo restores without per-clone setup.

  Uses the current `gh auth token` as-is (no scope refresh). Run once per machine; re-run after token rotation.

.EXAMPLE
  .\configure-gpr-user-nuget.ps1
#>
param(
    [string]$FeedUrl = 'https://nuget.pkg.github.com/Novolis-Platform/index.json',
    [string]$SourceName = 'github'
)

$ErrorActionPreference = 'Stop'

if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    throw 'GitHub CLI (gh) is required. Install from https://cli.github.com/'
}

gh auth status 2>&1 | Out-Null

$token = (gh auth token).Trim()
if ([string]::IsNullOrWhiteSpace($token)) {
    throw 'gh auth token returned empty. Run: gh auth login'
}

$userConfig = Join-Path $env:APPDATA 'NuGet\NuGet.Config'
$configDir = Split-Path $userConfig -Parent
if (-not (Test-Path $configDir)) {
    New-Item -ItemType Directory -Path $configDir -Force | Out-Null
}

$hasSource = $false
if (Test-Path $userConfig) {
    $hasSource = (dotnet nuget list source 2>&1 | Out-String) -match [regex]::Escape($SourceName)
}

if ($hasSource) {
    dotnet nuget update source $SourceName `
        --source $FeedUrl `
        --username 'x-access-token' `
        --password $token `
        --store-password-in-clear-text | Out-Null
    Write-Host "Updated source '$SourceName' in $userConfig"
}
else {
    dotnet nuget add source $FeedUrl `
        --name $SourceName `
        --username 'x-access-token' `
        --password $token `
        --store-password-in-clear-text | Out-Null
    Write-Host "Added source '$SourceName' to $userConfig"
}

Write-Host 'Done. Repo nuget.config files need no credentials.'
