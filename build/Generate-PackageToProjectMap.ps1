#Requires -Version 7.0
[CmdletBinding()]
param(
    [string]$WorkspaceRoot,
    [string]$OutputPath
)

$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $WorkspaceRoot) {
    $WorkspaceRoot = Split-Path -Parent (Split-Path -Parent $scriptDir)
}
$tool = Join-Path $WorkspaceRoot 'novolis-tools/src/Novolis.Solution.Tool/Novolis.Solution.Tool.csproj'
$forward = @('generate', '--root', $WorkspaceRoot)
if ($OutputPath) { $forward += @('--out', $OutputPath) }
if ($VerbosePreference -eq 'Continue') { Write-Verbose "dotnet run --project $tool --no-launch-profile -- $($forward -join ' ')" }
& dotnet run --project $tool --no-launch-profile -- @forward
exit $LASTEXITCODE
