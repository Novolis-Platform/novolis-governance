#Requires -Version 7.0
# Adapted from agent-contracts-standard (MIT) for novolis-governance.
$ErrorActionPreference = 'Stop'
$Root = Split-Path $PSScriptRoot -Parent

$required = @(
    (Join-Path $Root 'AGENTS.md'),
    (Join-Path $Root '.ai\index.md')
)

$missing = $required | Where-Object { -not (Test-Path $_) }
if ($missing.Count -gt 0) {
    Write-Error ("ACS layout missing: " + ($missing -join ', '))
}

Write-Host 'ACS verification passed for novolis-governance.'
