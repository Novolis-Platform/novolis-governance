#Requires -Version 7.0
param([string]$Org = 'Novolis-Platform')
$ErrorActionPreference = 'Stop'
$cs = Join-Path $PSScriptRoot 'gpr-find-junk-versions.cs'
& dotnet run --file $cs -- --org $Org
exit $LASTEXITCODE
