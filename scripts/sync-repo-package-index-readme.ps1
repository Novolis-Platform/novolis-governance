#Requires -Version 7.0
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$RepoRoot,
    [switch]$Replace
)
$ErrorActionPreference = 'Stop'
$cs = Join-Path $PSScriptRoot 'sync-repo-package-index-readme.cs'
$forward = @('--repo', $RepoRoot)
if ($Replace) { $forward += '--replace' }
& dotnet run --file $cs -- @forward
exit $LASTEXITCODE
