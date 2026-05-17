# Enforces Math → Physics → Simulation boundary rules (see docs/library-boundaries.md).
$ErrorActionPreference = 'Stop'
$root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$hits = [System.Collections.Generic.List[string]]::new()

function Add-Hit($path, $message) {
    $hits.Add("${path}: ${message}")
}

$stackRepos = @('novolis-math', 'novolis-physics', 'novolis-simulation')
$stackRoots = $stackRepos | ForEach-Object { Join-Path $root $_ }

# Raylib <-> Simulation project references
$raylibRoot = Join-Path $root 'novolis-raylib'
if (Test-Path $raylibRoot) {
    Get-ChildItem -Path $raylibRoot -Recurse -Filter '*.csproj' -File |
        Where-Object { $_.FullName -notmatch '\\(bin|obj)\\' } |
        ForEach-Object {
            $content = Get-Content $_.FullName -Raw
            if ($content -match 'Novolis\.Simulation') {
                Add-Hit $_.FullName 'Raylib project must not reference Novolis.Simulation.*'
            }
        }
}

foreach ($repoRoot in $stackRoots) {
    if (-not (Test-Path $repoRoot)) { continue }
    $repoName = Split-Path $repoRoot -Leaf

    Get-ChildItem -Path $repoRoot -Recurse -Filter '*.csproj' -File |
        Where-Object { $_.FullName -notmatch '\\(bin|obj)\\' } |
        ForEach-Object {
            $content = Get-Content $_.FullName -Raw
            if ($content -match 'Novolis\.Raylib') {
                Add-Hit $_.FullName 'Stack project must not reference Novolis.Raylib.*'
            }
        }

    $srcRoot = Join-Path $repoRoot 'src'
    if (-not (Test-Path $srcRoot)) { continue }

    Get-ChildItem -Path $srcRoot -Recurse -Filter '*.cs' -File |
        ForEach-Object {
            $rel = $_.FullName.Substring($repoRoot.Length + 1)
            if ($rel -match '\\(bin|obj)\\') { return }
            $content = Get-Content $_.FullName -Raw

            if ($content -match '\bVector2\b') {
                Add-Hit $rel 'Vector2 is forbidden in stack src (use Vector3 with Y=0 for planar XZ)'
            }

            if ($rel -notmatch 'ObsoleteNumericsForwards\.cs$') {
                if ($content -match '\b(struct|readonly struct|record struct)\s+Vector3d\b') {
                    Add-Hit $rel 'Custom Vector3d duplicates BCL Vector3'
                }
                if ($content -match '\b(struct|readonly struct|record struct)\s+Quaterniond\b') {
                    Add-Hit $rel 'Custom Quaterniond duplicates BCL Quaternion'
                }
                if ($content -match '\b(struct|readonly struct|record struct)\s+Vector3D\b') {
                    Add-Hit $rel 'Custom Vector3D duplicates BCL Vector3'
                }
            }
        }

    if ($repoName -eq 'novolis-math') {
        $cameraPath = Join-Path $srcRoot 'Novolis.Math.Geometry\Camera.cs'
        if ((Test-Path $cameraPath) -and -not (Select-String -Path $cameraPath -Pattern '\[Obsolete' -Quiet)) {
            Add-Hit 'novolis-math/src/Novolis.Math.Geometry/Camera.cs' 'Camera must live in Novolis.Simulation.View (obsolete shim allowed)'
        }
    }
}

if ($hits.Count -gt 0) {
    Write-Error ("Stack boundary verification failed:`n" + ($hits -join "`n"))
}

Write-Host "Stack boundary verification passed for novolis-math, novolis-physics, novolis-simulation."
