#Requires -Version 7.0
$ErrorActionPreference = 'Continue'
$Root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$repos = @(
    'novolis-workflows', 'novolis-governance',
    'novolis-math', 'novolis-rendering', 'novolis-raylib',
    'novolis-analyzers', 'novolis-aspire', 'novolis-avalonia', 'novolis-codegen',
    'novolis-commands', 'novolis-gaming', 'novolis-install', 'novolis-machinelearning', 'novolis-markup',
    'novolis-messaging', 'novolis-physics', 'novolis-security', 'novolis-simulation',
    'novolis-smoketest', 'novolis-storage', 'novolis-template-dotnet', 'novolis-templates',
    'novolis-testing', 'novolis-transports', 'novolis-wirefish'
)
foreach ($name in $repos) {
    $repo = Join-Path $Root $name
    if (-not (Test-Path (Join-Path $repo '.git'))) { continue }
    Push-Location $repo
    $status = git status --porcelain 2>$null
    if (-not $status) { Pop-Location; continue }
    Write-Host "=== $name ==="
    git add -A
    git commit -m "ci: single CI workflow; GPR publish and version fixes"
    git push origin main 2>&1
    Pop-Location
}
