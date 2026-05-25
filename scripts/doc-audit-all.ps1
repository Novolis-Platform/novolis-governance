#Requires -Version 7.0
<#
.SYNOPSIS
  Runs doc-audit.ps1 on every novolis-* repository under a workspace root.

.PARAMETER WorkspaceRoot
  Monorepo root containing novolis-* folders (default: parent of novolis-governance).

.PARAMETER RequireDocumentationProps
  Passed through to doc-audit.ps1 for each repo.
#>
param(
    [string] $WorkspaceRoot = (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent),

    [switch] $RequireDocumentationProps
)

$ErrorActionPreference = 'Stop'
$WorkspaceRoot = (Resolve-Path $WorkspaceRoot).Path
$auditScript = Join-Path $PSScriptRoot 'doc-audit.ps1'
if (-not (Test-Path $auditScript)) {
    Write-Error "Not found: $auditScript"
}

$repos = Get-ChildItem -Path $WorkspaceRoot -Directory -Filter 'novolis-*' |
    Where-Object { Test-Path (Join-Path $_.FullName 'src') -or Test-Path (Join-Path $_.FullName 'codegen') } |
    Sort-Object Name

$failed = [System.Collections.Generic.List[string]]::new()
foreach ($repo in $repos) {
    Write-Host "doc-audit: $($repo.Name)" -ForegroundColor Cyan
    $args = @{ RepoRoot = $repo.FullName }
    if ($RequireDocumentationProps) { $args.RequireDocumentationProps = $true }
    & $auditScript @args
    if ($LASTEXITCODE -ne 0) {
        $failed.Add($repo.Name)
    }
}

if ($failed.Count -gt 0) {
    Write-Host "doc-audit-all FAILED in: $($failed -join ', ')" -ForegroundColor Red
    exit 1
}

Write-Host "doc-audit-all OK: $($repos.Count) repos"
exit 0
