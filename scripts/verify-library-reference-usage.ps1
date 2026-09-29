#Requires -Version 7.0
<#
.SYNOPSIS
  Reject ordinary Novolis PackageReferences in governed project files.

.DESCRIPTION
  Managed dependencies on another Novolis repository should use LibraryReference.
  Governance expands that item to a sibling ProjectReference when the project is
  present and to a GitHub Packages PackageReference otherwise.

  A small set of package references is intentionally exempt:
    - Raylib packages carry native runtime assets and buildTransitive targets.
    - The Inno package supplies packaged installer MSBuild targets.
    - Explicit external-host package allowlists cover hosts that have not opted
      into the governance packaging import yet.

  Scratch probes and generated artifacts are outside the governed repository
  scan and are intentionally not inspected here.
#>
[CmdletBinding()]
param(
    [string]$Root
)

$ErrorActionPreference = 'Stop'

if (-not $Root) {
    $Root = if ($env:NOVOLIS_ROOT) {
        $env:NOVOLIS_ROOT
    }
    else {
        Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    }
}

$globalPackageExceptions = [System.Collections.Generic.HashSet[string]]::new(
    [StringComparer]::OrdinalIgnoreCase
)
foreach ($packageId in @(
    'Novolis.Raylib',
    'Novolis.Raylib.Native',
    'Novolis.Avalonia.Packaging.Inno'
)) {
    [void]$globalPackageExceptions.Add($packageId)
}

$externalHostPackageAllowlist = @{
    merglyph = @(
        'Novolis.Maui.Markdown'
    )
    'treffly-app' = @(
        'Novolis.Avalonia.Mobile',
        'Novolis.Avalonia.Mobile.Android',
        'Novolis.Avalonia.Mobile.Desktop'
    )
}

$violations = [System.Collections.Generic.List[string]]::new()
$repoDirectories = @(
    Get-ChildItem -LiteralPath $Root -Directory -Filter 'novolis-*' -ErrorAction SilentlyContinue
    Get-ChildItem -LiteralPath $Root -Directory -ErrorAction SilentlyContinue |
        Where-Object { $externalHostPackageAllowlist.ContainsKey($_.Name) }
) | Sort-Object -Property FullName -Unique

foreach ($repo in $repoDirectories) {
    $projects = Get-ChildItem -LiteralPath $repo.FullName -Recurse -File -Filter '*.csproj' -ErrorAction SilentlyContinue |
        Where-Object {
            $_.FullName -notmatch '[\\/](obj|bin|artifacts|_scratch|_docprobe|submodules)[\\/]'
        }

    foreach ($project in $projects) {
        $relativePath = $project.FullName.Substring($Root.Length).TrimStart('\', '/')
        try {
            $xml = [System.Xml.XmlDocument]::new()
            $xml.LoadXml((Get-Content -LiteralPath $project.FullName -Raw))
        }
        catch {
            $violations.Add("$relativePath : invalid project XML ($($_.Exception.Message))")
            continue
        }

        foreach ($packageReference in $xml.SelectNodes("//*[local-name()='PackageReference']")) {
            $packageId = [string]$packageReference.GetAttribute('Include')
            if ([string]::IsNullOrWhiteSpace($packageId)) {
                $packageId = [string]$packageReference.GetAttribute('Update')
            }

            if ($packageId -notmatch '^Novolis\.') {
                continue
            }

            if ($globalPackageExceptions.Contains($packageId)) {
                continue
            }

            if ($externalHostPackageAllowlist.ContainsKey($repo.Name) -and
                $externalHostPackageAllowlist[$repo.Name] -contains $packageId) {
                continue
            }

            $violations.Add(
                "$relativePath : $packageId must use LibraryReference " +
                '(or receive a reviewed exception in verify-library-reference-usage.ps1)'
            )
        }
    }
}

if ($violations.Count -gt 0) {
    $lines = @('LibraryReference usage violations:')
    foreach ($violation in $violations) {
        $lines += "  - $violation"
    }
    $lines += 'See novolis-governance/docs/nuget-only-policy.md'
    Write-Error ($lines -join [Environment]::NewLine)
    exit 1
}

Write-Host "verify-library-reference-usage: OK ($($repoDirectories.Count) repos scanned)"
exit 0
