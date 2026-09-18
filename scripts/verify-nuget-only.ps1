#Requires -Version 7.0
# Fail if any .csproj uses cross-repo ProjectReference or sibling-src MSBuild hacks.
# Does NOT flag MSBuild ProjectReference mode (Novolis.ProjectReferenceMode.targets) —
# that substitutes at build time when SolutionName is Novolis.Platform; committed csproj stay PackageReference-only.
# LibraryReference (Novolis.MSBuild.LibraryReference) is allowed in committed csproj: it expands at
# build time to ProjectReference or PackageReference and must not be rewritten as dual-ref blocks.
$ErrorActionPreference = 'Stop'
$Root = if ($env:NOVOLIS_ROOT) { $env:NOVOLIS_ROOT } else { Split-Path (Split-Path $PSScriptRoot -Parent) -Parent }

$crossRepoRef = [regex]::new('<ProjectReference\s+Include="[^"]*[/\\]novolis-[^"\\]+[/\\]')
$srcHack = [regex]::new('<Novolis\w+Src\b')
$dualRef = [regex]::new('ItemGroup\s+Condition="[^"]*Novolis\w+Src')
$packAsTool = [regex]::new('<PackAsTool>\s*true\s*</PackAsTool>')
$packable = [regex]::new('<IsPackable>\s*true\s*</IsPackable>')

$violations = [System.Collections.Generic.List[string]]::new()
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

Get-ChildItem $Root -Directory -Filter 'novolis-*' | ForEach-Object {
    $repoName = $_.Name
    Get-ChildItem $_.FullName -Recurse -Filter '*.csproj' -ErrorAction SilentlyContinue | ForEach-Object {
        $rel = $_.FullName.Substring($Root.Length).TrimStart('\', '/')
        $text = Get-Content $_.FullName -Raw
        if ($crossRepoRef.IsMatch($text)) {
            if ($repoName -eq 'novolis-lab' -and $text -match '(?i)<ProjectReference[^>]*submodules[/\\]novolis-') {
                $violations.Add("$rel : lab submodule ProjectReference is forbidden; use ProjectReference mode mapping")
            }
            else {
                $violations.Add("$rel : cross-repo ProjectReference")
            }
        }
        if ($srcHack.IsMatch($text)) {
            $violations.Add("$rel : sibling-src MSBuild property (Novolis*Src)")
        }
        if ($dualRef.IsMatch($text)) {
            $violations.Add("$rel : conditional ProjectReference/PackageReference by Novolis*Src")
        }

        if ($repoName -notin $nonLibraryRepos) {
            if ($packAsTool.IsMatch($text)) {
                $violations.Add("$rel : PackAsTool is only allowed in novolis-tools")
            }

            if ($packable.IsMatch($text) -and $_.BaseName -match '(?i)(\.Cli|\.Tool)$') {
                $violations.Add("$rel : packable CLI/tool host is only allowed in novolis-tools")
            }
        }
    }
}

if ($violations.Count -gt 0) {
    $lines = @('NuGet-only policy violations:')
    foreach ($v in $violations) {
        $lines += "  - $v"
    }
    $lines += 'See novolis-governance/docs/nuget-only-policy.md'
    Write-Error ($lines -join [Environment]::NewLine)
    exit 1
}

Write-Host "verify-nuget-only: OK ($((Get-ChildItem $Root -Directory -Filter 'novolis-*').Count) repos scanned)"
exit 0
