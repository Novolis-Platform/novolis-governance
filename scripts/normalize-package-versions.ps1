#Requires -Version 7.0
# Remove per-project Version tags and -preview/-local suffixes; rely on .novolis/version.props + Novolis.Version.targets.
$ErrorActionPreference = 'Stop'
$Root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent

function Strip-CsprojVersion([string]$Path) {
    $text = Get-Content $Path -Raw
    $new = $text -replace '\s*<Version>[^<]+</Version>\s*', "`n"
    if ($new -ne $text) {
        Set-Content $Path $new.TrimEnd() -Encoding utf8NoBOM -NoNewline
        return $true
    }
    return $false
}

$repos = Get-ChildItem $Root -Directory -Filter 'novolis-*' | Where-Object { $_.Name -notmatch 'dogfooding|workflows|governance|registry|installer' }
foreach ($repo in $repos) {
    $changed = 0
    Get-ChildItem $repo.FullName -Recurse -Filter '*.csproj' |
        Where-Object { $_.FullName -notmatch '\\obj\\|\\bin\\' } |
        ForEach-Object {
            if (Strip-CsprojVersion $_.FullName) { $changed++ }
        }
    $dp = Join-Path $repo.FullName 'Directory.Packages.props'
    if (Test-Path $dp) {
        $t = Get-Content $dp -Raw
        $n = $t -replace '(Include="Novolis\.[^"]+"\s+Version=")0\.[0-9.]+(-local|-preview[^"]*)(")', '${1}0.0.1.1${3}'
        if ($n -ne $t) {
            Set-Content $dp $n.TrimEnd() -Encoding utf8NoBOM
            $changed++
        }
    }
    if ($changed -gt 0) { Write-Host "$($repo.Name): $changed file(s)" }
}

Write-Host 'Done.'
