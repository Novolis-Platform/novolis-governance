#Requires -Version 7.0
[CmdletBinding()]
param([string]$RepoPath = '.')
$ErrorActionPreference = 'Stop'
$cs = Join-Path $PSScriptRoot 'sync-version-props.cs'
& dotnet run --file $cs -- --repo $RepoPath
exit $LASTEXITCODE
