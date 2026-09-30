#Requires -Version 7.0
param(
    [Parameter(Mandatory = $true)][string]$NupkgPath,
    [Parameter(Mandatory = $true)][string]$ExpectedPackageId
)
$ErrorActionPreference = 'Stop'
$cs = Join-Path $PSScriptRoot 'verify-nupkg-package-readme.cs'
& dotnet run --file $cs -- --nupkg $NupkgPath --id $ExpectedPackageId
exit $LASTEXITCODE
