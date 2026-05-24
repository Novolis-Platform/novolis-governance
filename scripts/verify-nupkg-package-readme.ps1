#Requires -Version 7.0
<#
.SYNOPSIS
  Verifies a packed .nupkg README H1 matches the package id (per-package docs, not repo README).
#>
param(
    [Parameter(Mandatory = $true)]
    [string] $NupkgPath,

    [Parameter(Mandatory = $true)]
    [string] $ExpectedPackageId
)

$ErrorActionPreference = 'Stop'
if (-not (Test-Path $NupkgPath)) { throw "Not found: $NupkgPath" }

Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip = [System.IO.Compression.ZipFile]::OpenRead((Resolve-Path $NupkgPath).Path)
try {
    $entry = $zip.GetEntry('README.md')
    if (-not $entry) { throw "README.md missing from package $NupkgPath" }
    $reader = New-Object System.IO.StreamReader($entry.Open())
    $text = $reader.ReadToEnd()
    $reader.Close()
}
finally {
    $zip.Dispose()
}

if ($text -match '(?m)^#\s+Novolis\.Raylib\s*$' -and $ExpectedPackageId -ne 'Novolis.Raylib') {
    throw "Package $ExpectedPackageId contains repo/meta README (# Novolis.Raylib), not package-specific docs."
}

if ($text -notmatch "(?m)^#\s+$([regex]::Escape($ExpectedPackageId))\s*(\r?\n|$)") {
    throw "Package $ExpectedPackageId README H1 does not match. First line: $($text.Split("`n")[0])"
}

Write-Host "OK: $ExpectedPackageId readme in $NupkgPath"
