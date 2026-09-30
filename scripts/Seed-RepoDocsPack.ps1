#Requires -Version 7.0
<#
.SYNOPSIS
  Thin shim to novolis-docs seed; optional git commit/push stays in PowerShell.
#>
param(
    [string] $WorkspaceRoot = '',
    [string] $GitHubBrandRoot = '',
    [switch] $CommitPush,
    [switch] $OverwriteThin,
    [switch] $SkipMarketing,
    [string[]] $OnlyRepos = @()
)

$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$governanceRoot = (Resolve-Path (Join-Path $scriptDir '..')).Path
if (-not $WorkspaceRoot) {
    $WorkspaceRoot = (Resolve-Path (Join-Path $governanceRoot '..')).Path
}
if (-not $GitHubBrandRoot) {
    $GitHubBrandRoot = Join-Path $WorkspaceRoot '.github'
}
$GitHubBrandRoot = (Resolve-Path $GitHubBrandRoot).Path

$cliProject = 'd:\novolis\novolis-tools\src\Novolis.Tools.Docs.Cli\Novolis.Tools.Docs.Cli.csproj'
$argsList = @(
    'run'
    '--project'
    $cliProject
    '--no-launch-profile'
    '--'
    'seed'
    '--root'
    $WorkspaceRoot
    '--brand-root'
    $GitHubBrandRoot
)

if ($OverwriteThin) { $argsList += '--overwrite-thin' }
if ($SkipMarketing) { $argsList += '--skip-marketing' }
foreach ($repo in $OnlyRepos) {
    if ($repo) { $argsList += @('--only', $repo) }
}

& dotnet @argsList
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

if (-not $CommitPush) { return }

$org = 'Novolis-Platform'
$docsSiteRoot = "https://$($org.ToLowerInvariant()).github.io/.github"
$skipLocalOnly = @('novolis-experimental', 'novolis-mapping', 'novolis-scheduling', 'novolis-wirefish')

$repoDirs = @(Get-ChildItem -LiteralPath $WorkspaceRoot -Directory | Where-Object {
        ($_.Name -like 'novolis-*' -or $_.Name -eq '.github') -and ($_.Name -notin $skipLocalOnly)
    })

if ($OnlyRepos.Count -gt 0) {
    $repoDirs = @($repoDirs | Where-Object { $_.Name -in $OnlyRepos })
}

foreach ($dir in ($repoDirs | Sort-Object Name)) {
    $name = $dir.Name
    Push-Location $dir.FullName
    try {
        if (-not (Test-Path -LiteralPath (Join-Path $dir.FullName '.git'))) {
            Write-Warning "  skip push (not a git repo)"
            continue
        }
        git add docs README.md 2>$null
        $pending = git status --porcelain -- docs README.md
        if (-not $pending) {
            Write-Host "==> $name (no git changes)"
            continue
        }
        $msg = @"
Seed docs pack and link the org docs site.

Add missing docs/README + policy guides when absent, and point the README at https://novolis-platform.github.io/.github/$name/.
"@
        if ($name -eq '.github') {
            $msg = @"
Seed docs pack and link the org docs site.

Add missing docs/README + policy guides when absent, and point the README at the portfolio docs home.
"@
        }
        git commit -m $msg
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "  commit failed for $name"
            continue
        }
        git push origin HEAD
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "  push failed for $name"
            continue
        }
        Write-Host "==> $name pushed"
    }
    finally {
        Pop-Location
    }
}
