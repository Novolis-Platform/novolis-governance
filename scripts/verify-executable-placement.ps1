#Requires -Version 7.0
<#
.SYNOPSIS
  Verify that shipped executable hosts are in the executable repositories.

.DESCRIPTION
  Library repositories may contain packable libraries and private, non-packable
  maintenance/code-generation tools. They may not contain PackAsTool projects
  or packable CLI/Tool executable hosts. `novolis-tools` is the only repository
  allowed to contain PackAsTool projects.
#>
[CmdletBinding()]
param(
    [string]$WorkspaceRoot
)

$ErrorActionPreference = 'Stop'
$WorkspaceRoot = if ($WorkspaceRoot) {
    (Resolve-Path $WorkspaceRoot).Path
}
else {
    (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
}

$allowedToolRepo = 'novolis-tools'
$nonLibraryRepos = @(
    'novolis-tools',
    'novolis-utilities',
    'novolis-apps',
    'novolis-lab',
    'novolis-experimental',
    'novolis-smoketest',
    'novolis-template-dotnet',
    'novolis-templates',
    'novolis-governance',
    'novolis-workflows',
    'novolis-registry'
)

$violations = [System.Collections.Generic.List[string]]::new()

function Get-Property([xml]$Xml, [string]$Name) {
    foreach ($group in @($Xml.Project.PropertyGroup)) {
        if ($null -eq $group) { continue }
        $node = $group.$Name
        if ($node -is [array]) { $node = $node | Select-Object -First 1 }
        if ($null -ne $node -and "$node".Trim()) { return "$node".Trim() }
    }
    return $null
}

Get-ChildItem $WorkspaceRoot -Directory -Filter 'novolis-*' | ForEach-Object {
    $repo = $_
    if ($repo.Name -in $nonLibraryRepos) { return }

    Get-ChildItem $repo.FullName -Recurse -Filter '*.csproj' -File |
        Where-Object { $_.FullName -notmatch '[\\/](obj|bin|artifacts|TestResults)[\\/]' } |
        ForEach-Object {
            try { [xml]$xml = Get-Content $_.FullName -Raw }
            catch {
                $violations.Add("$($_.FullName): invalid project XML")
                return
            }

            $packAsTool = Get-Property $xml 'PackAsTool'
            if ($packAsTool -eq 'true') {
                $violations.Add("$($_.FullName): PackAsTool is only allowed in $allowedToolRepo")
            }

            $isPackable = Get-Property $xml 'IsPackable'
            $outputType = Get-Property $xml 'OutputType'
            if ($isPackable -eq 'true' -and $outputType -eq 'Exe' -and $_.BaseName -match '(?i)(\.Cli|\.Tool)$') {
                $violations.Add("$($_.FullName): packable CLI/Tool host belongs in $allowedToolRepo")
            }
        }
}

if ($violations.Count -gt 0) {
    Write-Host "Executable placement violations ($($violations.Count)):" -ForegroundColor Red
    $violations | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
    exit 1
}

Write-Host "verify-executable-placement: OK" -ForegroundColor Green
exit 0
