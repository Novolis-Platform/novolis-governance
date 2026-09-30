#Requires -Version 7.0
[CmdletBinding()]
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
$workspace = if ($Root) { $Root } elseif ($env:NOVOLIS_ROOT) { $env:NOVOLIS_ROOT } else { Split-Path (Split-Path $PSScriptRoot -Parent) -Parent }
$cli = Join-Path $workspace 'novolis-tools/src/Novolis.Tools.Coverage.Cli/Novolis.Tools.Coverage.Cli.csproj'
$verb = if ($ListRepos) { 'list' } else { 'collect' }
$forward = @($verb, '--root', $workspace, '--configuration', $Configuration)
if ($OutputDir) { $forward += @('--out', $OutputDir) }
if ($ExcludeFile) { $forward += @('--exclude-file', $ExcludeFile) }
foreach ($name in $Exclude) { if ($name) { $forward += @('--exclude', $name) } }
foreach ($name in $Include) { if ($name) { $forward += @('--include', $name) } }
if ($ThrottleLimit -gt 0) { $forward += @('--throttle', "$ThrottleLimit") }
if ($SkipBuild) { $forward += '--skip-build' }
if ($FailBelow -ne 0) { $forward += @('--fail-below', "$FailBelow") }
if ($OpenReport) { $forward += '--open' }
if ($PlatformSlnx) { $forward += '--platform' }
if ($RegenerateSlnx) { $forward += '--regenerate-slnx' }
if ($PlatformSlnxPath) { $forward += @('--platform-slnx', $PlatformSlnxPath) }
& dotnet run --project $cli --no-launch-profile -- @forward
exit $LASTEXITCODE
