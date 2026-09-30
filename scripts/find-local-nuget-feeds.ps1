#Requires -Version 7.0
param([string]$Root = '')
$ErrorActionPreference = 'Stop'
$cs = Join-Path $PSScriptRoot 'find-local-nuget-feeds.cs'
$forward = @()
if ($Root) { $forward += @('--root', $Root) }
& dotnet run --file $cs -- @forward
exit $LASTEXITCODE
