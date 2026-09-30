#Requires -Version 7.0
param(
    [string]$Org = 'Novolis-Platform',
    [string]$Package = '',
    [int]$MaxPackages = 0
)
$ErrorActionPreference = 'Stop'
$cs = Join-Path $PSScriptRoot 'gpr-find-broken-deps.cs'
$forward = @('--org', $Org)
if ($Package) { $forward += @('--package', $Package) }
if ($MaxPackages -gt 0) { $forward += @('--max', "$MaxPackages") }
& dotnet run --file $cs -- @forward
exit $LASTEXITCODE
