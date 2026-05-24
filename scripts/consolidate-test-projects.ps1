# Consolidates per-facet *.Tests projects into a single Novolis.{Domain}.Unit project.
# Usage: ./consolidate-test-projects.ps1 -RepoRoot d:\novolis\novolis-commands -Domain Novolis.Commands

param(
    [Parameter(Mandatory)]
    [string]$RepoRoot,
    [Parameter(Mandatory)]
    [string]$Domain,
    [string[]]$ExcludeProjects = @()
)

$ErrorActionPreference = 'Stop'
$testsDir = Join-Path $RepoRoot 'tests'
$targetName = "$Domain.Unit"
$targetDir = Join-Path $testsDir $targetName
$targetCsproj = Join-Path $targetDir "$targetName.csproj"

if (-not (Test-Path $testsDir)) {
    throw "No tests folder: $testsDir"
}

$testsSuffix = [regex]::Escape("$Domain") + '(\..+)?\.Tests$'
$sourceProjects = Get-ChildItem $testsDir -Directory |
    Where-Object {
        $_.Name -match $testsSuffix -and
        $_.Name -notlike '*.TestSupport*' -and
        $_.Name -ne $targetName -and
        ($ExcludeProjects -notcontains $_.Name)
    }

if ($sourceProjects.Count -eq 0) {
    Write-Host "No source test projects to merge in $RepoRoot"
    exit 0
}

New-Item -ItemType Directory -Force -Path $targetDir | Out-Null

$allRefs = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
$allPackages = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
$compileRemoves = @()
$noneIncludes = @()

foreach ($projDir in $sourceProjects) {
    $csprojPath = Join-Path $projDir.FullName "$($projDir.Name).csproj"
    if (-not (Test-Path $csprojPath)) { continue }

    [xml]$xml = Get-Content $csprojPath
    foreach ($pr in $xml.Project.ItemGroup.ProjectReference) {
        if ($pr.Include) { [void]$allRefs.Add($pr.Include) }
    }
    foreach ($pkg in $xml.Project.ItemGroup.PackageReference) {
        if ($pkg.Include) { [void]$allPackages.Add($pkg.Include) }
    }
    foreach ($cr in $xml.SelectNodes('//Compile[@Remove]')) {
        $compileRemoves += $cr.Remove
    }
    foreach ($ni in $xml.SelectNodes("//None[@Include]")) {
        if ($ni.'CopyToOutputDirectory') {
            $noneIncludes += @{ Include = $ni.Include; Copy = $ni.'CopyToOutputDirectory' }
        }
    }

    if ($projDir.Name -eq "$Domain.Tests") {
        $facet = ($Domain -split '\.')[-1]
    }
    else {
        $facet = $projDir.Name.Substring($Domain.Length + 1)
        $facet = $facet.Substring(0, $facet.Length - '.Tests'.Length)
    }
    $destFacetDir = Join-Path $targetDir $facet
    New-Item -ItemType Directory -Force -Path $destFacetDir | Out-Null

    Get-ChildItem $projDir.FullName -Force | Where-Object {
        $_.Name -notin @('bin', 'obj') -and -not $_.Name.EndsWith('.csproj')
    } | ForEach-Object {
        $dest = Join-Path $destFacetDir $_.Name
        if (Test-Path $dest) { Remove-Item $dest -Recurse -Force }
        Move-Item $_.FullName $dest
    }

    Write-Host "  merged $($projDir.Name) -> $facet/"
}

# Resolve project references to absolute paths from repo
$refLines = $allRefs | Sort-Object | ForEach-Object {
    $rel = $_ -replace '\\', '/'
    if ($rel -notmatch '^\.\./') {
        $rel = "../../$rel"
    }
    "    <ProjectReference Include=`"$rel`" />"
}

$pkgLines = $allPackages | Sort-Object | ForEach-Object {
    "    <PackageReference Include=`"$_`" />"
}

$extraItems = ''
if ($compileRemoves.Count -gt 0) {
    $extraItems += "`n  <ItemGroup>`n"
    foreach ($r in ($compileRemoves | Select-Object -Unique)) {
        $extraItems += "    <Compile Remove=`"$r`" />`n"
    }
    $extraItems += "  </ItemGroup>"
}
if ($noneIncludes.Count -gt 0) {
    $extraItems += "`n  <ItemGroup>`n"
    foreach ($n in $noneIncludes) {
        $extraItems += "    <None Include=`"$($n.Include)`" CopyToOutputDirectory=`"$($n.Copy)`" />`n"
    }
    $extraItems += "  </ItemGroup>"
}

$csprojContent = @"
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <RootNamespace>$targetName</RootNamespace>
    <IsPackable>false</IsPackable>
    <IsTestProject>true</IsTestProject>
  </PropertyGroup>
  <ItemGroup>
$($pkgLines -join "`n")
  </ItemGroup>
  <ItemGroup>
$($refLines -join "`n")
  </ItemGroup>$extraItems
</Project>
"@

Set-Content -Path $targetCsproj -Value $csprojContent -Encoding UTF8
Write-Host "Created $targetCsproj"

# Remove empty source project directories (bin/obj may remain)
foreach ($projDir in $sourceProjects) {
    $remaining = Get-ChildItem $projDir.FullName -Force -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -notin @('bin', 'obj') }
    if (-not $remaining) {
        Remove-Item $projDir.FullName -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "  removed $($projDir.Name)/"
    }
}

Write-Host "Done: $($sourceProjects.Count) projects -> $targetName"
