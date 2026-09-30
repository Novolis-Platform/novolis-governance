#Requires -Version 7.0
$ErrorActionPreference = 'Stop'
$cs = Join-Path $PSScriptRoot 'verify-acs-repo.cs'
& dotnet run --file $cs -- @args
exit $LASTEXITCODE
