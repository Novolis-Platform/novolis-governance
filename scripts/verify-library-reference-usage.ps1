#Requires -Version 7.0
[CmdletBinding()]
param([string]$Root = '')
$ErrorActionPreference = 'Stop'
$cs = Join-Path $PSScriptRoot 'verify-library-reference-usage.cs'
$forward = @()
if ($Root) { $forward += @('--root', $Root) }
& dotnet run --file $cs -- @forward
exit $LASTEXITCODE
