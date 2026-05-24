#Requires -Version 7.0
<#
.SYNOPSIS
  Prepends a GitHub Packages notice and package index table to a multi-package repo README.
.PARAMETER RepoRoot
  Path to novolis-* repository.
.PARAMETER Replace
  When set, replaces auto-generated index block on re-run.
#>
param(
    [Parameter(Mandatory = $true)]
    [string] $RepoRoot,
    [switch] $Replace
)

$ErrorActionPreference = 'Stop'
$RepoRoot = (Resolve-Path $RepoRoot).Path
$readmePath = Join-Path $RepoRoot 'README.md'
if (-not (Test-Path $readmePath)) { throw "Missing README.md at repo root: $RepoRoot" }

$repoName = Split-Path $RepoRoot -Leaf
$org = 'Novolis-Platform'
$packages = [System.Collections.Generic.List[object]]::new()

@('src', 'codegen') | ForEach-Object {
    $base = Join-Path $RepoRoot $_
    if (-not (Test-Path $base)) { return }
    Get-ChildItem $base -Recurse -Filter '*.csproj' -File | ForEach-Object {
        [xml]$xml = Get-Content $_.FullName -Raw
        $packable = $true
        $n = $xml.Project.PropertyGroup.IsPackable | Select-Object -First 1
        if ($n -eq 'false') { $packable = $false }
        if (-not $packable) { return }
        $id = ($xml.Project.PropertyGroup.PackageId | Select-Object -First 1)
        if (-not $id) { $id = $_.Directory.Name }
        $pkgReadme = Join-Path $_.DirectoryName 'README.md'
        if (-not (Test-Path $pkgReadme)) { return }
        $relReadme = $pkgReadme.Replace($RepoRoot, '').TrimStart('\', '/').Replace('\', '/')
        $packages.Add([pscustomobject]@{
                Id      = $id
                Readme  = $relReadme
                Install = "dotnet add package $id"
            })
    }
}

if ($packages.Count -eq 0) { throw "No packable projects under $RepoRoot" }

$index = @"
<!-- novolis-package-index:start -->
> **GitHub Packages shows this repository README on every package page** (upstream limitation).
> Open the **package README** for install and quick start — embedded in each `.nupkg` and linked below.

## Published packages

| Package | Install | Package README |
|---------|---------|----------------|
"@ + [Environment]::NewLine

foreach ($p in ($packages | Sort-Object Id)) {
    $pkgReadmeRel = "$($p.Readme)".Replace('\', '/')
    $url = "https://github.com/$org/$repoName/blob/main/$pkgReadmeRel"
    $index += "| ``$($p.Id)`` | ``$($p.Install)`` | [README]($url) |" + [Environment]::NewLine
}

$index += @"

For NuGet.org and Visual Studio, the **embedded** `README.md` inside each package is authoritative.

<!-- novolis-package-index:end -->

"@

$body = Get-Content $readmePath -Raw
if ($body -match '(?s)<!-- novolis-package-index:start -->.*?<!-- novolis-package-index:end -->') {
    if ($Replace) {
        $body = $body -replace '(?s)<!-- novolis-package-index:start -->.*?<!-- novolis-package-index:end -->\s*', $index
    }
}
else {
    $body = $index + "`n" + $body.TrimStart()
}

$out = $body.TrimEnd() + [Environment]::NewLine
Set-Content -Path $readmePath -Value $out -Encoding utf8NoBOM
Write-Host "Updated $readmePath ($($packages.Count) packages indexed)"
