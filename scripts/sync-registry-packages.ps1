#Requires -Version 7.0
# Generate novolis-registry/packages/*.json for every IsPackable project.
$ErrorActionPreference = 'Stop'
$Root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$RegistryDir = Join-Path $Root 'novolis-registry\packages'
$VersionJson = Join-Path $PSScriptRoot '..\build\version.json'
$v = Get-Content $VersionJson -Raw | ConvertFrom-Json
$year = [int]($v.year ?? $v.sdkYear)
$major = [int]($v.major ?? $v.apiBreak)
$minor = [int]($v.minor ?? $v.feature)
$stable = "$year.$major.$minor.0"

function To-RegistryId([string]$PackageId) {
    ($PackageId -replace '^Novolis\.', 'novolis.' -replace '\.', '.').ToLowerInvariant()
}

function To-FileSlug([string]$PackageId) {
    ($PackageId -replace '\.', '-').ToLowerInvariant()
}

New-Item -ItemType Directory -Force -Path $RegistryDir | Out-Null

$entries = @()
Get-ChildItem $Root -Directory -Filter 'novolis-*' |
    Where-Object { $_.Name -notmatch 'workflows|governance|registry|dogfooding|installer' } |
    ForEach-Object {
        $repoName = $_.Name
        Get-ChildItem $_.FullName -Recurse -Filter '*.csproj' |
            Where-Object { $_.FullName -notmatch '\\obj\\|\\bin\\' } |
            ForEach-Object {
                $text = Get-Content $_.FullName -Raw
                if ($text -notmatch '<IsPackable>true</IsPackable>') { return }
                $packageId = if ($text -match '<PackageId>([^<]+)</PackageId>') { $matches[1].Trim() }
                             else { [IO.Path]::GetFileNameWithoutExtension($_.Name) }
                $entries += [pscustomobject]@{
                    packageId = $packageId
                    repo      = $repoName
                }
            }
    }

$entries = $entries | Sort-Object packageId -Unique
$written = 0
foreach ($e in $entries) {
    $slug = To-FileSlug $e.packageId
    $doc = [ordered]@{
        id         = To-RegistryId $e.packageId
        name       = $e.packageId
        type       = 'nuget'
        version    = $stable
        repository = "https://github.com/Novolis-Platform/$($e.repo)"
        packageId  = $e.packageId
    } | ConvertTo-Json -Depth 5
    Set-Content -Path (Join-Path $RegistryDir "$slug.json") -Value $doc -Encoding utf8NoBOM
    $written++
}

Write-Host "Wrote $written registry entries at version $stable"
