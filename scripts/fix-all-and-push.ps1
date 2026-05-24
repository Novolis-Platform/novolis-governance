#Requires -Version 7.0
# Apply CI fixes, sync version props, normalize floating refs, push all repos.
$ErrorActionPreference = 'Stop'
$Root = 'd:\novolis'
$Sync = Join-Path $Root 'novolis-governance\scripts\sync-version-props.ps1'
$ApplyWf = Join-Path $Root 'novolis-governance\scripts\apply-pr-merge-release-workflows.ps1'
$SyncRegistry = Join-Path $Root 'novolis-governance\scripts\sync-registry-packages.ps1'

& $ApplyWf
& $SyncRegistry

$repos = Get-ChildItem $Root -Directory -Filter 'novolis-*' |
    Where-Object { $_.Name -notmatch 'workflows|governance|registry|installer' }

foreach ($repo in $repos) {
    if (Test-Path (Join-Path $repo.FullName 'build\version.json')) {
        & $Sync -RepoPath $repo.FullName
    }
    $dp = Join-Path $repo.FullName 'Directory.Packages.props'
    if (Test-Path $dp) {
        $t = Get-Content $dp -Raw
        $n = $t -replace '(Include="Novolis\.[^"]+"\s+Version=")2026\.[0-9.]+[^"]*(")', '${1}2026.1.*${2}'
        if ($n -ne $t) { Set-Content $dp $n.TrimEnd() -Encoding utf8NoBOM }
    }
}

$dogDp = Join-Path $Root 'novolis-dogfooding\Directory.Packages.props'
if (Test-Path $dogDp) {
    $t = Get-Content $dogDp -Raw
    $n = $t -replace '(Include="Novolis\.[^"]+"\s+Version=")2026\.[0-9.]+[^"]*(")', '${1}2026.1.*${2}'
    if ($n -ne $t) { Set-Content $dogDp $n.TrimEnd() -Encoding utf8NoBOM }
}

Write-Host 'Local fixes done. Run git push separately.'
