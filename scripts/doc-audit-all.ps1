#Requires -Version 7.0
param(
    [string]$WorkspaceRoot = '',
    [switch]$RequireDocumentationProps
)
$ErrorActionPreference = 'Stop'
$cs = Join-Path $PSScriptRoot 'doc-audit-all.cs'
$forward = @()
if ($WorkspaceRoot) { $forward += @('--workspace-root', $WorkspaceRoot) }
if ($RequireDocumentationProps) { $forward += '--require-docs' }
& dotnet run --file $cs -- @forward
exit $LASTEXITCODE
