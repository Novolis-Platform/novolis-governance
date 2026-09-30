#Requires -Version 7.0
$ErrorActionPreference = 'Stop'
$cs = Join-Path $PSScriptRoot 'verify-nuget-only.cs'
& dotnet run --file $cs -- @args
exit $LASTEXITCODE
