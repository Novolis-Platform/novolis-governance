#Requires -Version 7.0
[CmdletBinding()]
param(
    [string]$WorkspaceRoot,
    [string[]]$ExcludeRepos = @(),
    [string]$OutputPath,
    [bool]$ValidateProjectReferences = $true
)

$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $WorkspaceRoot) {
    $WorkspaceRoot = Split-Path -Parent (Split-Path -Parent $scriptDir)
}
$tool = Join-Path $WorkspaceRoot 'novolis-tools/src/Novolis.Solution.Tool/Novolis.Solution.Tool.csproj'
$unsupported = @()
if ($ExcludeRepos.Count -gt 0) { $unsupported += '-ExcludeRepos' }
if (-not $ValidateProjectReferences) { $unsupported += '-ValidateProjectReferences' }
if ($unsupported.Count -gt 0) {
    throw "The installed Novolis.Solution.Tool does not support $($unsupported -join ', '). Remove these options or update the solution tool before retrying."
}

$forward = @('generate', '--root', $WorkspaceRoot)
if ($OutputPath) { $forward += @('--out', $OutputPath) }
if ($VerbosePreference -eq 'Continue') { Write-Verbose "dotnet run --project $tool --no-launch-profile -- $($forward -join ' ')" }
& dotnet run --project $tool --no-launch-profile -- @forward
exit $LASTEXITCODE
