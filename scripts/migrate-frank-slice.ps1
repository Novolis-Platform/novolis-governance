#Requires -Version 7.0
<#
.SYNOPSIS
  Copy a Frank project folder into Novolis src/tests layout and apply namespace renames.
.EXAMPLE
  .\migrate-frank-slice.ps1 -FrankRoot "D:\novolis\bootstrap\scratch\frank-eval\Frank.Channels.DependencyInjection\Frank.Channels.DependencyInjection" `
    -DestProject "D:\novolis\novolis-messaging\src\Novolis.Messaging.Channels" `
    -FromNamespace "Frank.Channels.DependencyInjection" -ToNamespace "Novolis.Messaging.Channels"
#>
param(
    [Parameter(Mandatory)][string]$FrankRoot,
    [Parameter(Mandatory)][string]$DestProject,
    [string]$FrankTestsRoot,
    [string]$DestTests,
    [string[]]$ExtraReplacements = @()
)

$ErrorActionPreference = 'Stop'

$replacements = @(
    'Frank.Reflection.Mermaid|Novolis.CodeGen.Reflection.Mermaid',
    'Frank.Reflection.Dump|Novolis.CodeGen.Reflection.Dump',
    'Frank.Reflection|Novolis.CodeGen.Reflection',
    'Frank.Analyzers.AutoMapper|Novolis.Analyzers.AutoMapper',
    'Frank.Analyzers.CodeLength|Novolis.Analyzers.CodeLength',
    'Frank.Channels.DependencyInjection|Novolis.Messaging.Channels',
    'Frank.PulseFlow.Internal|Novolis.Messaging.Internal',
    'Frank.PulseFlow|Novolis.Messaging',
    'Frank.Testing.TestOutputExtensions|Novolis.Testing.TUnit',
    'Frank.Testing.TestBases|Novolis.Testing.TestBases',
    'Frank.Testing.Testcontainers|Novolis.Testing.Testcontainers',
    'Frank.Testing.TestServer|Novolis.Testing.TestServer',
    'Frank.Testing.Logging|Novolis.Testing.Logging',
    'Frank.Testing|Novolis.Testing',
    'Frank.BedrockSlim.Server|Novolis.Transports.Tcp.Server',
    'Frank.BedrockSlim.Client|Novolis.Transports.Tcp.Client',
    'Frank.BedrockSlim|Novolis.Transports.Tcp',
    'Frank.Http.Abstractions|Novolis.Transports.Http.Abstractions',
    'Frank.Http.Authentication|Novolis.Transports.Http.Authentication',
    'Frank.Http.Extensions|Novolis.Transports.Http.Extensions',
    'Frank.Http|Novolis.Transports.Http',
    'Frank.DataStorage.Abstractions|Novolis.Storage.Abstractions',
    'Frank.DataStorage.Json|Novolis.Storage.Json',
    'Frank.DataStorage.Sqlite|Novolis.Storage.Sqlite',
    'Frank.DataStorage|Novolis.Storage',
    'Frank.Security.HaveIBeenPwned|Novolis.Security.HaveIBeenPwned',
    'Frank.Security.Cryptography|Novolis.Security.Cryptography',
    'Frank.Security|Novolis.Security'
) + $ExtraReplacements

function Copy-And-Rename {
    param([string]$Source, [string]$Destination)
    if (-not (Test-Path $Source)) { throw "Source not found: $Source" }
    New-Item -ItemType Directory -Force -Path $Destination | Out-Null
    Get-ChildItem $Source -Recurse -File | Where-Object {
        $_.Extension -in '.cs', '.csproj', '.props', '.targets', '.json', '.md'
    } | ForEach-Object {
        $rel = $_.FullName.Substring($Source.Length).TrimStart('\', '/')
        $target = Join-Path $Destination $rel
        $dir = Split-Path $target -Parent
        New-Item -ItemType Directory -Force -Path $dir | Out-Null
        $text = Get-Content $_.FullName -Raw -Encoding UTF8
        foreach ($pair in $replacements) {
            $from, $to = $pair -split '\|', 2
            $text = $text -replace [regex]::Escape($from), $to
        }
        $text = $text -replace 'Frank\.Reflection\.Dump', 'Novolis.CodeGen.Reflection.Dump'
        $text = $text -replace 'PackageReference Include="Frank\.[^"]+"', '# removed Frank package'
        Set-Content -Path $target -Value $text -Encoding UTF8 -NoNewline
    }
}

Copy-And-Rename -Source $FrankRoot -Destination $DestProject
if ($FrankTestsRoot -and $DestTests) {
    Copy-And-Rename -Source $FrankTestsRoot -Destination $DestTests
}

Write-Host "Migrated $FrankRoot -> $DestProject"
