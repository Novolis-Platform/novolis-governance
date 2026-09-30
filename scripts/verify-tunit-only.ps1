#Requires -Version 7.0
$ErrorActionPreference = 'Stop'
$cs = Join-Path $PSScriptRoot 'verify-tunit-only.cs'
& dotnet run --file $cs -- @args
exit $LASTEXITCODE
