# Adds /// <summary> stubs for CS1591 missing XML documentation errors.
param(
    [Parameter(Mandatory = $true)]
    [string]$RepoRoot,
    [int]$MaxPasses = 5
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
            '^Get' { return "Gets $(&{$name.Substring(3)})".Trim(); }
            '^Set' { return "Sets a value."; }
            '^Add' { return "Adds an item."; }
            '^Create' { return "Creates a resource."; }
            '^Build' { return "Builds the configured instance."; }
            '^Execute' { return "Executes the operation."; }
            '^Start' { return "Starts the resource."; }
            '^Stop' { return "Stops the resource."; }
            '^Initialize' { return "Initializes the instance."; }
            '^Dispose' { return "Releases resources."; }
            default { return "$name operation."; }
        }
    }
    if ($member -match '\.') {
        $name = ($member -split '\.')[-1]
        return "$name."
    }
    return "Represents $member."
}

function Add-DocComment([string]$filePath, [int]$lineNumber, [string]$member) {
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

        $changed = 0
        $seen = @{}
        foreach ($m in $found) {
            $key = "$($m.Groups[1].Value):$($m.Groups[2].Value):$($m.Groups[3].Value)"
            if ($seen[$key]) { continue }
            $seen[$key] = $true
            $fileName = Split-Path $m.Groups[1].Value -Leaf
            $line = [int]$m.Groups[2].Value
            $member = $m.Groups[3].Value
            $filePath = Get-ChildItem -Path $RepoRoot -Recurse -Filter $fileName -File | Select-Object -First 1 -ExpandProperty FullName
            if (-not $filePath) { continue }
            if (Add-DocComment $filePath $line $member) { $changed++ }
        }
        Write-Host "Pass $pass : inserted $changed comments"
        if ($changed -eq 0) { break }
    }
}
finally {
    Pop-Location
}
