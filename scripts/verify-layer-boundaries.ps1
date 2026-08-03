#Requires -Version 7
<#
.SYNOPSIS
  Fail if Novolis libraries violate Avalonia isolation or (lightweight) upward spine PackageReferences.

.DESCRIPTION
  Scans *.csproj under the Novolis workspace (sibling of novolis-governance).

  NOV2006 (PackageReference form):
    Only projects under novolis-avalonia (Novolis.Avalonia.*) may PackageReference Avalonia / Avalonia.*.
    Product apps (novolis-apps, dogfooding, templates, treffly, experimental app hosts, geopolitics apps) may.

  NOV2007 (PackageReference form, spine only):
    Math must not reference Physics/Simulation/Game/Avalonia packages, etc.

  Exit 0 on success, 1 on violations.
#>
[CmdletBinding()]
param(
  [string]$WorkspaceRoot = ''
)

$ErrorActionPreference = 'Stop'

if (-not $WorkspaceRoot) {
  $WorkspaceRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
}

$violations = [System.Collections.Generic.List[string]]::new()

function Get-PackageRefs([string]$csprojPath) {
  [xml]$xml = Get-Content -LiteralPath $csprojPath -Raw
  $ns = @{ msb = 'http://schemas.microsoft.com/developer/msbuild/2003' }
  # SDK-style projects usually have no xmlns
  $nodes = @($xml.SelectNodes('//PackageReference'))
  if ($nodes.Count -eq 0 -and $xml.DocumentElement.NamespaceURI) {
    $nsmgr = New-Object System.Xml.XmlNamespaceManager($xml.NameTable)
    $nsmgr.AddNamespace('msb', $xml.DocumentElement.NamespaceURI)
    $nodes = @($xml.SelectNodes('//msb:PackageReference', $nsmgr))
  }
  foreach ($n in $nodes) {
    $id = $n.GetAttribute('Include')
    if (-not $id) { $id = $n.GetAttribute('Update') }
    if ($id) { $id }
  }
}

function Test-IsAvaloniaPackage([string]$id) {
  return $id -eq 'Avalonia' -or $id.StartsWith('Avalonia.')
}

function Get-SpineRank([string]$packageOrProjectName) {
  if ($packageOrProjectName -match '^Novolis\.Math(\.|$)') { return 0 }
  if ($packageOrProjectName -match '^Novolis\.Physics(\.|$)') { return 1 }
  if ($packageOrProjectName -match '^Novolis\.Simulation(\.|$)') { return 2 }
  if ($packageOrProjectName -match '^Novolis\.Game(\.|$)') { return 3 }
  if ($packageOrProjectName -match '^Novolis\.Avalonia(\.|$)') { return 4 }
  return $null
}

function Test-IsAppHostPath([string]$fullPath) {
  $p = $fullPath.Replace('/', '\')
  return $p -match '\\novolis-apps\\' `
    -or $p -match '\\novolis-dogfooding\\' `
    -or $p -match '\\novolis-templates\\' `
    -or $p -match '\\treffly-app\\' `
    -or $p -match '\\novolis-experimental\\' `
    -or $p -match '\\artifacts\\'
}

$csprojs = Get-ChildItem -LiteralPath $WorkspaceRoot -Recurse -Filter '*.csproj' -File -ErrorAction SilentlyContinue |
  Where-Object {
    $_.FullName -notmatch '\\(obj|bin|artifacts|TestResults|\.git)\\' -and
    $_.FullName -match '\\novolis-[^\\]+\\'
  }

foreach ($proj in $csprojs) {
  $name = [System.IO.Path]::GetFileNameWithoutExtension($proj.Name)
  if ($name -notlike 'Novolis.*') { continue }
  if ($name -like '*.Unit' -or $name -like '*.Tests' -or $name -like '*.Unit.*') { continue }
  if (Test-IsAppHostPath $proj.FullName) { continue }

  $refs = @(Get-PackageRefs $proj.FullName)
  $selfRank = Get-SpineRank $name
  $isAvaloniaLayer = $name -like 'Novolis.Avalonia*'

  foreach ($ref in $refs) {
    if ((Test-IsAvaloniaPackage $ref) -and -not $isAvaloniaLayer) {
      $violations.Add("NOV2006 $($proj.FullName): library '$name' PackageReference '$ref' (Avalonia reserved for Novolis.Avalonia.*)")
    }

    $refRank = Get-SpineRank $ref
    if ($null -ne $selfRank -and $null -ne $refRank -and $selfRank -lt $refRank) {
      $violations.Add("NOV2007 $($proj.FullName): '$name' (rank $selfRank) → '$ref' (rank $refRank) upward spine reference")
    }
  }
}

if ($violations.Count -gt 0) {
  Write-Host "Layer boundary violations ($($violations.Count)):" -ForegroundColor Red
  $violations | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
  exit 1
}

Write-Host "verify-layer-boundaries: OK ($($csprojs.Count) Novolis library projects scanned under $WorkspaceRoot)" -ForegroundColor Green
exit 0
