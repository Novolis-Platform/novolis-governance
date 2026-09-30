#Requires -Version 7.0
param([string]$Root = '')
$ErrorActionPreference = 'Stop'
$cs = Join-Path $PSScriptRoot 'find-build-line-floats.cs'
$forward = @()
if ($Root) { $forward += @('--root', $Root) }
& dotnet run --file $cs -- @forward
exit $LASTEXITCODE
