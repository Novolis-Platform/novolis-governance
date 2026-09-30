#Requires -Version 7.0
param(
    [Parameter(Mandatory = $true)][string]$RepoPath,
    [int]$ExpectedYear = 2026,
    [int]$ExpectedMajor = 1,
    [int]$ExpectedMinor = 1
)
$ErrorActionPreference = 'Stop'
$cs = Join-Path $PSScriptRoot 'verify-platform-version.cs'
& dotnet run --file $cs -- --repo $RepoPath --year $ExpectedYear --major $ExpectedMajor --minor $ExpectedMinor
exit $LASTEXITCODE
