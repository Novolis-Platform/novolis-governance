#Requires -Version 7.0
param(
    [string]$Org = 'Novolis-Platform',
    [switch]$UnlinkedOnly,
    [switch]$JunkLatestOnly
)
$ErrorActionPreference = 'Stop'
$cs = Join-Path $PSScriptRoot 'gpr-package-overview.cs'
$forward = @('--org', $Org)
if ($UnlinkedOnly) { $forward += '--unlinked-only' }
if ($JunkLatestOnly) { $forward += '--junk-latest-only' }
& dotnet run --file $cs -- @forward
exit $LASTEXITCODE
