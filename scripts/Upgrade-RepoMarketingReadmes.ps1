#Requires -Version 7.0
<#
.SYNOPSIS
  Thin shim to novolis-docs marketing (banners, repo-catalog.json, README upgrades).
#>
param(
    [string] $WorkspaceRoot = '',
    [string] $GitHubBrandRoot = '',
    [switch] $ApplyGitHubMeta,
    [switch] $SkipBanners,
    [switch] $SkipReadmes
)

$ErrorActionPreference = 'Stop'

$cliProject = 'd:\novolis\novolis-tools\src\Novolis.Tools.Docs.Cli\Novolis.Tools.Docs.Cli.csproj'
$argsList = @(
    'run'
    '--project'
    $cliProject
    '--no-launch-profile'
    '--'
    'marketing'
)

if ($WorkspaceRoot) { $argsList += @('--root', $WorkspaceRoot) }
if ($GitHubBrandRoot) { $argsList += @('--brand-root', $GitHubBrandRoot) }
if ($ApplyGitHubMeta) { $argsList += '--apply-github-meta' }
if ($SkipBanners) { $argsList += '--skip-banners' }
if ($SkipReadmes) { $argsList += '--skip-readmes' }

& dotnet @argsList
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
