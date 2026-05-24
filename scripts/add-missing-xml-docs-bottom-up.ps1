# Adds /// <summary> for CS1591 by inserting bottom-up within each file (stable line numbers).
param(
    [Parameter(Mandatory = $true)]
    [string]$RepoRoot,
    [int]$MaxPasses = 10
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-SummaryText([string]$member) {
    if ($member -match '\.ctor') {
        $type = ($member -split '\.')[0]
        if ($member -match '^([^.]+)\.') { $type = $Matches[1] }
        return "Initializes a new instance of the <see cref=`"$type`"/> class."
    }
    if ($member -match '\(') {
        $name = ($member -split '\.')[-1] -replace '\(.*', ''
        switch -Regex ($name) {
            '^Get' { return "Gets $($name.Substring(3))." }
            '^Set' { return "Sets a value." }
            '^Add' { return "Adds an item." }
            '^Create' { return "Creates a resource." }
            '^Build' { return "Builds the configured instance." }
            '^Execute' { return "Executes the operation." }
            '^Start' { return "Starts the resource." }
            '^Stop' { return "Stops the resource." }
            '^Initialize' { return "Initializes the instance." }
            '^Dispose' { return "Releases resources." }
            '^Try' { return "Attempts the operation and reports whether it succeeded." }
            '^Sample' { return "Samples a value at the given coordinates." }
            '^Project' { return "Projects a point onto the surface." }
            default { return "$name operation." }
        }
    }
    if ($member -match '\.') {
        $name = ($member -split '\.')[-1]
        return "$name."
    }
    return "Represents $member."
}

function Expand-InlineEnumDocs([string]$filePath) {
    $text = [IO.File]::ReadAllText($filePath)
  if ($text -notmatch 'public\s+enum\s+(\w+)\s*\{([^}]+)\}') { return $false }
    $enumName = $Matches[1]
    $body = $Matches[2]
    $values = [regex]::Matches($body, '(\w+)\s*=\s*(\d+)')
    if ($values.Count -eq 0) { return $false }
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.AppendLine("/// <summary>Represents $enumName.</summary>")
    [void]$sb.AppendLine("public enum $enumName")
    [void]$sb.AppendLine("{")
    foreach ($v in $values) {
        $name = $v.Groups[1].Value
        $num = $v.Groups[2].Value
        [void]$sb.AppendLine("    /// <summary>$name.</summary>")
        [void]$sb.AppendLine("    $name = $num,")
    }
    [void]$sb.AppendLine("}")
    $newEnum = $sb.ToString().TrimEnd()
    $newText = [regex]::Replace($text, "public\s+enum\s+$enumName\s*\{[^}]+\}", $newEnum, 1)
    if ($newText -eq $text) { return $false }
    [IO.File]::WriteAllText($filePath, $newText)
    return $true
}

function Add-DocComment([string]$filePath, [int]$lineNumber, [string]$member) {
    if ($member -match '\.(\w+)$' -and $member -notmatch '\(') {
        $enumName = ($member -split '\.')[0]
        $valueName = ($member -split '\.')[-1]
        $text = [IO.File]::ReadAllText($filePath)
        if ($text -match "public\s+enum\s+$enumName\s*\{") {
            return Expand-InlineEnumDocs $filePath
        }
    }

    $lines = [System.Collections.Generic.List[string]]::new()
    $lines.AddRange([IO.File]::ReadAllLines($filePath))
    $index = $lineNumber - 1
    if ($index -lt 0 -or $index -ge $lines.Count) { return $false }

    for ($j = $index - 1; $j -ge [Math]::Max(0, $index - 3); $j--) {
        $trim = $lines[$j].Trim()
        if ($trim -eq '') { continue }
        if ($trim.StartsWith('///')) { return $false }
        break
    }

    $indent = ($lines[$index] -replace '^(\s*).*$', '$1')
    $summary = Get-SummaryText $member
    $lines.Insert($index, "$indent/// <summary>$summary</summary>")
    [IO.File]::WriteAllLines($filePath, $lines)
    return $true
}

Push-Location $RepoRoot
try {
    for ($pass = 1; $pass -le $MaxPasses; $pass++) {
        $output = dotnet build 2>&1 | Out-String
        if ($output -match 'Build succeeded') {
            Write-Host "Build succeeded on pass $pass for $RepoRoot"
            return
        }

        $pattern = '([^\s:]+\.cs)\((\d+),\d+\): error CS1591:.*?member ''([^'']+)'''
        $found = [regex]::Matches($output, $pattern)
        if ($found.Count -eq 0) {
            Write-Host "No CS1591 on pass $pass; build may have other errors."
            break
        }

        $byFile = @{}
        foreach ($m in $found) {
            $fileName = Split-Path $m.Groups[1].Value -Leaf
            $line = [int]$m.Groups[2].Value
            $member = $m.Groups[3].Value
            $filePath = Get-ChildItem -Path $RepoRoot -Recurse -Filter $fileName -File | Select-Object -First 1 -ExpandProperty FullName
            if (-not $filePath) { continue }
            if (-not $byFile[$filePath]) { $byFile[$filePath] = [System.Collections.Generic.List[object]]::new() }
            $byFile[$filePath].Add([pscustomobject]@{ Line = $line; Member = $member })
        }

        $changed = 0
        foreach ($filePath in $byFile.Keys) {
            $items = $byFile[$filePath] | Sort-Object -Property Line -Descending
            $seen = @{}
            foreach ($item in $items) {
                $key = "$($item.Line):$($item.Member)"
                if ($seen[$key]) { continue }
                $seen[$key] = $true
                if (Add-DocComment $filePath $item.Line $item.Member) { $changed++ }
            }
        }
        Write-Host "Pass $pass : inserted $changed comments (bottom-up)"
        if ($changed -eq 0) { break }
    }
}
finally {
    Pop-Location
}
