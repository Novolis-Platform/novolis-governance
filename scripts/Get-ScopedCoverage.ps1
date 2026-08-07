#Requires -Version 7.0
param(
    [Parameter(Mandatory)][string[]]$CoberturaPaths,
    [string[]]$ExcludeAssembly = @()
)

function Test-ExcludedAssembly {
    param([string]$Name, [string[]]$Patterns)
    foreach ($p in $Patterns) {
        if ($Name -like $p) { return $true }
    }
    return $false
}

$linesHit = 0
$linesValid = 0

foreach ($path in $CoberturaPaths) {
    if (-not (Test-Path -LiteralPath $path)) {
        Write-Warning "Missing: $path"
        continue
    }

    [xml]$xml = Get-Content -LiteralPath $path -Raw
    foreach ($pkg in $xml.coverage.packages.package) {
        $asm = [string]$pkg.name
        if (Test-ExcludedAssembly $asm $ExcludeAssembly) { continue }

        foreach ($cls in $pkg.classes.class) {
            $clsName = [string]$cls.name
            if ($clsName -like '*MessagePack*' -or $clsName -like '*.g.cs*') { continue }

            foreach ($line in $cls.lines.line) {
                $linesValid++
                if ([int]$line.hits -gt 0) { $linesHit++ }
            }
        }
    }
}

$pct = if ($linesValid -gt 0) { [math]::Round(100.0 * $linesHit / $linesValid, 1) } else { 0.0 }
[pscustomobject]@{
    LinePct     = $pct
    LinesHit    = $linesHit
    LinesValid  = $linesValid
}
