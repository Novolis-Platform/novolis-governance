# Updates *.slnx and .novolis/packages.json after test consolidation.

param(
    [Parameter(Mandatory)]
    [string]$RepoRoot,
    [Parameter(Mandatory)]
    [string]$Domain
)

$ErrorActionPreference = 'Stop'
$unitName = "$Domain.Unit"
$unitPath = "tests/$unitName/$unitName.csproj"

# slnx
$slnxFiles = Get-ChildItem $RepoRoot -Filter '*.slnx'
foreach ($slnx in $slnxFiles) {
    $content = Get-Content $slnx.FullName -Raw
    $original = $content
    $content = [regex]::Replace(
        $content,
        '<Project Path="tests/' + [regex]::Escape($Domain) + '[^"]*\.Tests/[^"]+\.csproj"\s*/>\s*',
        '')
    if ($content -notmatch [regex]::Escape($unitPath)) {
        $content = $content -replace '(<Folder Name="/tests/">)', "`$1`n    <Project Path=`"$unitPath`" />"
        if ($content -eq $original) {
            $content = $content -replace '(</Solution>)', "  <Folder Name=`"/tests/`">`n    <Project Path=`"$unitPath`" />`n  </Folder>`n`$1"
        }
    }
    if ($content -ne $original) {
        Set-Content $slnx.FullName $content -NoNewline
        Write-Host "Updated $($slnx.Name)"
    }
}

# packages.json
$pkgJson = Join-Path $RepoRoot '.novolis/packages.json'
if (-not (Test-Path $pkgJson)) { return }

$json = Get-Content $pkgJson -Raw | ConvertFrom-Json
$changed = $false
foreach ($prop in $json.packages.PSObject.Properties) {
    $entry = $prop.Value
    $newPaths = [System.Collections.Generic.List[string]]::new()
    foreach ($path in $entry.paths) {
        if ($path -match "^tests/$([regex]::Escape($Domain))\.(.+)\.Tests/\*\*$") {
            $facet = $Matches[1]
            $newPaths.Add("tests/$unitName/$facet/**")
            $changed = $true
        }
        elseif ($path -match "^tests/$([regex]::Escape($Domain))\.Tests/\*\*$") {
            $facet = ($Domain -split '\.')[-1]
            $newPaths.Add("tests/$unitName/$facet/**")
            $changed = $true
        }
        else {
            $newPaths.Add($path)
        }
    }
    $entry.paths = $newPaths
}
if ($changed) {
    $json | ConvertTo-Json -Depth 10 | Set-Content $pkgJson
    Write-Host "Updated packages.json"
}
