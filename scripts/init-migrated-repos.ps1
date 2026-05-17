#Requires -Version 7.0
# Post-migration: remove Frank csproj files, write Novolis csproj/slnx, fix usings.
$ErrorActionPreference = 'Stop'

function Remove-FrankCsproj {
    param([string]$Root)
    Get-ChildItem $Root -Recurse -Filter 'Frank.*.csproj' | Remove-Item -Force
}

function Write-Utf8 {
    param([string]$Path, [string]$Content)
    $dir = Split-Path $Path -Parent
    if ($dir) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    Set-Content -Path $Path -Value $Content.TrimEnd() -Encoding UTF8
}

# --- Messaging ---
$messaging = 'D:\novolis\novolis-messaging'
Remove-FrankCsproj $messaging

Write-Utf8 "$messaging\src\Novolis.Messaging.Channels\Novolis.Messaging.Channels.csproj" @'
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <PackageId>Novolis.Messaging.Channels</PackageId>
    <Version>0.1.0-preview.1</Version>
    <Description>System.Threading.Channels registration for Microsoft.Extensions.DependencyInjection.</Description>
    <IsPackable>true</IsPackable>
  </PropertyGroup>
  <ItemGroup>
    <PackageReference Include="Microsoft.Extensions.DependencyInjection" Version="10.0.5" />
  </ItemGroup>
</Project>
'@

Write-Utf8 "$messaging\src\Novolis.Messaging\Novolis.Messaging.csproj" @'
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <PackageId>Novolis.Messaging</PackageId>
    <Version>0.1.0-preview.1</Version>
    <Description>In-process pulse messaging (PulseFlow) over channels with DI.</Description>
    <IsPackable>true</IsPackable>
  </PropertyGroup>
  <ItemGroup>
    <ProjectReference Include="..\Novolis.Messaging.Channels\Novolis.Messaging.Channels.csproj" />
    <PackageReference Include="Microsoft.Extensions.Hosting.Abstractions" Version="10.0.5" />
    <PackageReference Include="Microsoft.Extensions.Options" Version="10.0.5" />
  </ItemGroup>
</Project>
'@

Write-Utf8 "$messaging\tests\Novolis.Messaging.Channels.Tests\Novolis.Messaging.Channels.Tests.csproj" @'
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <IsPackable>false</IsPackable>
    <IsTestProject>true</IsTestProject>
    <RootNamespace>Novolis.Messaging.Channels.Tests</RootNamespace>
  </PropertyGroup>
  <ItemGroup>
    <PackageReference Include="FluentAssertions" Version="8.9.0" />
    <PackageReference Include="Microsoft.Extensions.Hosting" Version="10.0.5" />
    <PackageReference Include="Microsoft.NET.Test.Sdk" Version="17.14.0" />
    <PackageReference Include="xunit" Version="2.9.3" />
    <PackageReference Include="xunit.runner.visualstudio" Version="3.0.2" />
    <ProjectReference Include="..\..\src\Novolis.Messaging.Channels\Novolis.Messaging.Channels.csproj" />
    <ProjectReference Include="..\..\..\novolis-testing\src\Novolis.Testing.TestBases\Novolis.Testing.TestBases.csproj" />
  </ItemGroup>
</Project>
'@

Write-Utf8 "$messaging\tests\Novolis.Messaging.Tests\Novolis.Messaging.Tests.csproj" @'
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <IsPackable>false</IsPackable>
    <IsTestProject>true</IsTestProject>
    <RootNamespace>Novolis.Messaging.Tests</RootNamespace>
  </PropertyGroup>
  <ItemGroup>
    <PackageReference Include="FluentAssertions" Version="8.9.0" />
    <PackageReference Include="Microsoft.Extensions.Hosting" Version="10.0.5" />
    <PackageReference Include="Microsoft.NET.Test.Sdk" Version="17.14.0" />
    <PackageReference Include="xunit" Version="2.9.3" />
    <PackageReference Include="xunit.runner.visualstudio" Version="3.0.2" />
    <ProjectReference Include="..\..\src\Novolis.Messaging\Novolis.Messaging.csproj" />
    <ProjectReference Include="..\..\..\novolis-testing\src\Novolis.Testing.TestBases\Novolis.Testing.TestBases.csproj" />
    <ProjectReference Include="..\..\..\novolis-testing\src\Novolis.Testing.Xunit\Novolis.Testing.Xunit.csproj" />
  </ItemGroup>
</Project>
'@

Write-Utf8 "$messaging\Novolis.Messaging.slnx" @'
<Solution>
  <Folder Name="/src/">
    <Project Path="src/Novolis.Messaging.Channels/Novolis.Messaging.Channels.csproj" />
    <Project Path="src/Novolis.Messaging/Novolis.Messaging.csproj" />
  </Folder>
  <Folder Name="/tests/">
    <Project Path="tests/Novolis.Messaging.Channels.Tests/Novolis.Messaging.Channels.Tests.csproj" />
    <Project Path="tests/Novolis.Messaging.Tests/Novolis.Messaging.Tests.csproj" />
  </Folder>
</Solution>
'@

Write-Utf8 "$messaging\Directory.Packages.props" @'
<Project>
  <PropertyGroup>
    <ManagePackageVersionsCentrally>true</ManagePackageVersionsCentrally>
  </PropertyGroup>
  <ItemGroup>
    <PackageVersion Include="FluentAssertions" Version="8.9.0" />
    <PackageVersion Include="Microsoft.Extensions.DependencyInjection" Version="10.0.5" />
    <PackageVersion Include="Microsoft.Extensions.Hosting" Version="10.0.5" />
    <PackageVersion Include="Microsoft.Extensions.Hosting.Abstractions" Version="10.0.5" />
    <PackageVersion Include="Microsoft.Extensions.Options" Version="10.0.5" />
    <PackageVersion Include="Microsoft.NET.Test.Sdk" Version="17.14.0" />
    <PackageVersion Include="xunit" Version="2.9.3" />
    <PackageVersion Include="xunit.runner.visualstudio" Version="3.0.2" />
  </ItemGroup>
</Project>
'@

Write-Utf8 "$messaging\.novolis\packages.json" @'
{
  "packages": {
    "Novolis.Messaging.Channels": {
      "project": "src/Novolis.Messaging.Channels/Novolis.Messaging.Channels.csproj",
      "paths": [
        "src/Novolis.Messaging.Channels/**",
        "tests/Novolis.Messaging.Channels.Tests/**",
        "Directory.Build.props",
        "Directory.Packages.props",
        "global.json",
        "Novolis.Messaging.slnx"
      ]
    },
    "Novolis.Messaging": {
      "project": "src/Novolis.Messaging/Novolis.Messaging.csproj",
      "paths": [
        "src/Novolis.Messaging/**",
        "src/Novolis.Messaging.Channels/**",
        "tests/Novolis.Messaging.Tests/**",
        "Directory.Build.props",
        "Directory.Packages.props",
        "global.json",
        "Novolis.Messaging.slnx"
      ]
    }
  }
}
'@

Write-Host 'Messaging scaffold written.'
