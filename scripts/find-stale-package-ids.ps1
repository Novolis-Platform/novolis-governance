#Requires -Version 7.0
param(
    [string]$Root = '',
    [string[]]$ExtraIds = @()
)
$ErrorActionPreference = 'Stop'
$cs = Join-Path $PSScriptRoot 'find-stale-package-ids.cs'
$forward = [System.Collections.Generic.List[string]]::new()
if ($Root) { $forward.Add('--root'); $forward.Add($Root) }
foreach ($id in $ExtraIds) { $forward.Add('--extra'); $forward.Add($id) }
& dotnet run --file $cs -- @forward
exit $LASTEXITCODE
