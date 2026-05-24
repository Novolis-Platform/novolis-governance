#Requires -Version 7.0
# Replace ../../../novolis-*/src/... ProjectReference with PackageReference for standalone CI.
$ErrorActionPreference = 'Stop'
$Root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$novolisVersion = '0.0.1.1'

$repos = @('novolis-physics', 'novolis-simulation')

function Ensure-PackageVersion([string]$PropsPath, [string]$PackageId) {
    if (-not (Test-Path $PropsPath)) {
        $content = @"
<Project>
  <ItemGroup>
    <PackageVersion Include="$PackageId" Version="$novolisVersion" />
  </ItemGroup>
</Project>
"@
        Set-Content $PropsPath $content.TrimEnd() -Encoding utf8NoBOM
        return
    }
    $text = Get-Content $PropsPath -Raw
    if ($text -match "Include=`"$([regex]::Escape($PackageId))`"") {
        $text = $text -replace "(Include=`"$([regex]::Escape($PackageId))`"\s+Version=`")[^`"]+(`")", "`${1}$novolisVersion`${2}"
    }
    else {
        $text = $text -replace '(<ItemGroup>)', "`$1`n    <PackageVersion Include=`"$PackageId`" Version=`"$novolisVersion`" />"
    }
    Set-Content $PropsPath $text.TrimEnd() -Encoding utf8NoBOM
}

foreach ($repoName in $repos) {
    $repo = Join-Path $Root $repoName
    if (-not (Test-Path $repo)) { continue }
    $props = Join-Path $repo 'Directory.Packages.props'
    $changed = 0
    Get-ChildItem $repo -Recurse -Filter '*.csproj' | ForEach-Object {
        $text = Get-Content $_.FullName -Raw
        $new = [regex]::Replace($text, '(?m)^\s*<ProjectReference\s+Include="[^"]*novolis-[^\\]+\\src\\([^\\]+)\\[^"]+\.csproj"\s*/>\s*\r?\n', {
            param($m)
            $folder = $m.Groups[1].Value
            Ensure-PackageVersion $props $folder
            $changed++
            "    <PackageReference Include=`"$folder`" />`n"
        })
        if ($new -ne $text) {
            Set-Content $_.FullName $new.TrimEnd() -Encoding utf8NoBOM
        }
    }
    Write-Host "$repoName : updated $changed reference(s)"
}

Write-Host 'Done.'
