#Requires -Version 7.0
[CmdletBinding()]
param(
    [switch]$Check
)

$ErrorActionPreference = 'Stop'
$cs = Join-Path $PSScriptRoot 'Export-GraphicalProfile.cs'
$forward = [System.Collections.Generic.List[string]]::new()
if ($Check) {
    $forward.Add('--check')
}
foreach ($arg in $args) {
    $forward.Add([string]$arg)
}
& dotnet run --file $cs -- @forward
exit $LASTEXITCODE
