#Requires -Version 7.0
param(
    [Parameter(Mandatory = $true)][string]$RepoRoot,
    [switch]$RequireDocumentationProps
)
$ErrorActionPreference = 'Stop'
$cs = Join-Path $PSScriptRoot 'doc-audit.cs'
$forward = @('--repo', $RepoRoot)
if ($RequireDocumentationProps) { $forward += '--require-docs' }
& dotnet run --file $cs -- @forward
exit $LASTEXITCODE
