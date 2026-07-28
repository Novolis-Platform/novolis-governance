#Requires -Version 7.0
# Fail if any .csproj uses cross-repo ProjectReference or sibling-src MSBuild hacks.
$ErrorActionPreference = 'Stop'
$Root = if ($env:NOVOLIS_ROOT) { $env:NOVOLIS_ROOT } else { Split-Path (Split-Path $PSScriptRoot -Parent) -Parent }

$crossRepoRef = [regex]'<ProjectReference\s+Include="[^"]*[/\\]novolis-[^"\\]+[/\\]'
$srcHack = [regex]'<Novolis\w+Src\b'
$dualRef = [regex]'ItemGroup\s+Condition="[^"]*Novolis\w+Src'

$violations = [System.Collections.Generic.List[string]]::new()

Get-ChildItem $Root -Directory -Filter 'novolis-*' | ForEach-Object {
    Get-ChildItem $_.FullName -Recurse -Filter '*.csproj' -ErrorAction SilentlyContinue | ForEach-Object {
        $rel = $_.FullName.Substring($Root.Length).TrimStart('\', '/')
        $text = Get-Content $_.FullName -Raw
        if ($crossRepoRef.IsMatch($text)) {
            $violations.Add("$rel : cross-repo ProjectReference")
        }
        if ($srcHack.IsMatch($text)) {
            $violations.Add("$rel : sibling-src MSBuild property (Novolis*Src)")
        }
        if ($dualRef.IsMatch($text)) {
            $violations.Add("$rel : conditional ProjectReference/PackageReference by Novolis*Src")
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
