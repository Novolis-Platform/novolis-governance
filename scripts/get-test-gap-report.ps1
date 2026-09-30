#Requires -Version 7.0
[CmdletBinding()]
param(
    [string]$Root = '',
    [string[]]$Exclude = @(),
    [string]$ExcludeFile = '',
    [string[]]$Include = @(),
    [switch]$IncludeExecutables,
    [switch]$IncludeNonPackable,
    [int]$ThrottleLimit = 0,
    [string]$OutputDir = '',
    [bool]$FailOnGaps = $true
)

$ErrorActionPreference = 'Stop'
$workspace = if ($Root) { $Root } elseif ($env:NOVOLIS_ROOT) { $env:NOVOLIS_ROOT } else { Split-Path (Split-Path $PSScriptRoot -Parent) -Parent }
$cli = Join-Path $workspace 'novolis-tools/src/Novolis.Tools.Coverage.Cli/Novolis.Tools.Coverage.Cli.csproj'
$forward = @('test-gaps', '--root', $workspace)
if ($OutputDir) { $forward += @('--out', $OutputDir) }
if ($ExcludeFile) { $forward += @('--exclude-file', $ExcludeFile) }
foreach ($name in $Exclude) { if ($name) { $forward += @('--exclude', $name) } }
foreach ($name in $Include) { if ($name) { $forward += @('--include', $name) } }
if ($ThrottleLimit -gt 0) { $forward += @('--throttle', "$ThrottleLimit") }
if ($IncludeExecutables) { $forward += '--include-executables' }
if ($IncludeNonPackable) { $forward += '--include-non-packable' }
if (-not $FailOnGaps) { $forward += '--no-fail' }
& dotnet run --project $cli --no-launch-profile -- @forward
exit $LASTEXITCODE
