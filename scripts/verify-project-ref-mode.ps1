#Requires -Version 7.0
[CmdletBinding()]
param(
    [string]$WorkspaceRoot,
    [switch]$SkipMsBuild,
    [switch]$SkipBuild
)

$ErrorActionPreference = 'Stop'
$govRoot = Split-Path $PSScriptRoot -Parent
if (-not $WorkspaceRoot) {
    $WorkspaceRoot = if ($env:NOVOLIS_ROOT) { $env:NOVOLIS_ROOT } else { Split-Path $govRoot -Parent }
}
$tool = Join-Path $WorkspaceRoot 'novolis-tools/src/Novolis.Solution.Tool/Novolis.Solution.Tool.csproj'
& dotnet run --project $tool --no-launch-profile -- verify --root $WorkspaceRoot
exit $LASTEXITCODE
