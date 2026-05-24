#Requires -Version 7.0
$ErrorActionPreference = 'Stop'
$Root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent

$gprNugetConfig = @'
<?xml version="1.0" encoding="utf-8"?>
<configuration>
  <packageSources>
    <clear />
    <add key="nuget.org" value="https://api.nuget.org/v3/index.json" protocolVersion="3" />
    <add key="github" value="https://nuget.pkg.github.com/Novolis-Platform/index.json" />
  </packageSources>
  <packageSourceMapping>
    <packageSource key="github">
      <package pattern="Novolis.*" />
    </packageSource>
    <packageSource key="nuget.org">
      <package pattern="*" />
    </packageSource>
  </packageSourceMapping>
</configuration>
'@

$repos = Get-ChildItem $Root -Directory -Filter 'novolis-*' |
    Where-Object { $_.Name -notmatch 'dogfooding|workflows|governance|registry|installer' }

foreach ($repo in $repos) {
    foreach ($name in @('NuGet.config', 'nuget.config')) {
        $p = Join-Path $repo.FullName $name
        if (Test-Path $p) { Remove-Item $p -Force }
    }
    Set-Content (Join-Path $repo.FullName 'nuget.config') $gprNugetConfig.TrimEnd() -Encoding utf8NoBOM
    Write-Host $repo.Name
}
Write-Host 'Done.'
