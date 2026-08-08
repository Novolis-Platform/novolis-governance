#Requires -Version 7.0
# Fail if any novolis-* repo references banned NuGet packages (Markdig, QuestPDF).
$ErrorActionPreference = 'Stop'
$Root = if ($env:NOVOLIS_ROOT) { $env:NOVOLIS_ROOT } else { Split-Path (Split-Path $PSScriptRoot -Parent) -Parent }

$bannedIds = @('Markdig', 'QuestPDF')
$packageRef = [regex]'<PackageReference\s+Include="(?<id>[^"]+)"'
$packageVersion = [regex]'<PackageVersion\s+Include="(?<id>[^"]+)"'
$usingBanned = [regex]'(?m)^\s*using\s+(Markdig|QuestPDF)(\.|;)'

$violations = [System.Collections.Generic.List[string]]::new()

Get-ChildItem $Root -Directory -Filter 'novolis-*' | ForEach-Object {
    $repo = $_.Name
    Get-ChildItem $_.FullName -Recurse -Include '*.csproj', 'Directory.Packages.props', 'Packages.props' -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -notmatch '[\\/](bin|obj)[\\/]' } |
        ForEach-Object {
            $rel = $_.FullName.Substring($Root.Length).TrimStart('\', '/')
            $text = Get-Content $_.FullName -Raw
            foreach ($m in $packageRef.Matches($text)) {
                $id = $m.Groups['id'].Value
                if ($bannedIds -contains $id) {
                    $violations.Add("$rel : PackageReference $id")
                }
            }
            foreach ($m in $packageVersion.Matches($text)) {
                $id = $m.Groups['id'].Value
                if ($bannedIds -contains $id) {
                    $violations.Add("$rel : PackageVersion $id")
                }
            }
        }

    Get-ChildItem $_.FullName -Recurse -Filter '*.cs' -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -notmatch '[\\/](bin|obj)[\\/]' } |
        ForEach-Object {
            $rel = $_.FullName.Substring($Root.Length).TrimStart('\', '/')
            $text = Get-Content $_.FullName -Raw
            if ($usingBanned.IsMatch($text)) {
                $violations.Add("$rel : using Markdig/QuestPDF")
            }
        }
}

if ($violations.Count -gt 0) {
    $lines = @('Banned package policy violations (Markdig / QuestPDF):')
    foreach ($v in $violations) {
        $lines += "  - $v"
    }
    $lines += 'See novolis-governance/docs/markdown-and-pdf-policy.md'
    Write-Error ($lines -join [Environment]::NewLine)
    exit 1
}

Write-Host "verify-banned-packages: OK ($((Get-ChildItem $Root -Directory -Filter 'novolis-*').Count) repos scanned)"
exit 0
