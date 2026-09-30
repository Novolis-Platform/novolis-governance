#Requires -Version 7.0
[CmdletBinding()]
param([string]$WorkspaceRoot = '')
$ErrorActionPreference = 'Stop'
$cs = Join-Path $PSScriptRoot 'verify-executable-placement.cs'
$forward = @()
if ($WorkspaceRoot) { $forward += @('--workspace-root', $WorkspaceRoot) }
& dotnet run --file $cs -- @forward
exit $LASTEXITCODE
