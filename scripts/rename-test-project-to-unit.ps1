# Renames a single *.Tests project folder/csproj to Novolis.{Domain}.Unit

param(
    [Parameter(Mandatory)]
    [string]$RepoRoot,
    [Parameter(Mandatory)]
    [string]$Domain,
    [Parameter(Mandatory)]
    [string]$OldProjectName
)

$ErrorActionPreference = 'Stop'
$testsDir = Join-Path $RepoRoot 'tests'
$oldDir = Join-Path $testsDir $OldProjectName
$newName = "$Domain.Unit"
$newDir = Join-Path $testsDir $newName

if (-not (Test-Path $oldDir)) {
    throw "Project not found: $oldDir"
}

if (Test-Path $newDir) {
    throw "Target already exists: $newDir"
}

Rename-Item $oldDir $newName
$oldCsproj = Join-Path $newDir "$OldProjectName.csproj"
$newCsproj = Join-Path $newDir "$newName.csproj"
Rename-Item $oldCsproj "$newName.csproj"

[xml]$xml = Get-Content $newCsproj
$rootNs = $xml.Project.PropertyGroup.RootNamespace
if ($rootNs) {
    $xml.Project.PropertyGroup.RootNamespace = $newName
}
$xml.Save($newCsproj)
Write-Host "Renamed $OldProjectName -> $newName"
