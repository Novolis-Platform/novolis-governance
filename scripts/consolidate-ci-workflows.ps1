#Requires -Version 7.0
# Deprecated: use apply-pr-merge-release-workflows.ps1 (PR + merge + release, not a single ci.yml).
Write-Warning 'consolidate-ci-workflows.ps1 is deprecated. Running apply-pr-merge-release-workflows.ps1 instead.'
& (Join-Path $PSScriptRoot 'apply-pr-merge-release-workflows.ps1')
