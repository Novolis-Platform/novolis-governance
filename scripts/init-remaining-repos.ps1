#Requires -Version 7.0
$ErrorActionPreference = 'Stop'

function Remove-FrankCsproj { param([string]$Root); Get-ChildItem $Root -Recurse -Filter 'Frank.*.csproj' | Remove-Item -Force }
function W { param([string]$Path,[string]$Content); $d=Split-Path $Path -Parent; if($d){ni -ItemType Directory -Force -Path $d|Out-Null}; Set-Content $Path $Content.TrimEnd() -Encoding utf8 }
function Strip-Ver { param([string]$Root); Get-ChildItem $Root -Recurse -Filter *.csproj | % { (gc $_.FullName -Raw) -replace ' Version="[^"]+"','' | sc $_.FullName -Encoding utf8 } }

# --- TESTING ---
$t = 'D:\novolis\novolis-testing'
Remove-FrankCsproj $t
W "$t\Directory.Packages.props" @'
<Project>
  <PropertyGroup><ManagePackageVersionsCentrally>true</ManagePackageVersionsCentrally></PropertyGroup>
  <ItemGroup>
    <PackageVersion Include="ConsoleTableExt" Version="3.3.0" />
    <PackageVersion Include="JetBrains.Annotations" Version="2024.3.0" />
    <PackageVersion Include="Microsoft.CodeAnalysis.CSharp" Version="4.14.0" />
    <PackageVersion Include="Microsoft.Extensions.Logging" Version="10.0.5" />
    <PackageVersion Include="Microsoft.Extensions.Options" Version="10.0.5" />
    <PackageVersion Include="Microsoft.NET.Test.Sdk" Version="17.14.0" />
    <PackageVersion Include="Testcontainers" Version="4.3.0" />
    <PackageVersion Include="TUnit.Core" Version="0.19.74" />
    <PackageVersion Include="VarDump" Version="1.0.0" />
    <PackageVersion Include="xunit" Version="2.9.3" />
    <PackageVersion Include="xunit.runner.visualstudio" Version="3.0.2" />
  </ItemGroup>
</Project>
'@
$testingProjects = @(
  @{Id='Novolis.Testing.TestBases';Desc='Test host bases for integration tests'},
  @{Id='Novolis.Testing.Logging';Desc='Test logging for xUnit/TUnit'},
  @{Id='Novolis.Testing.Xunit';Desc='xUnit test output extensions';RootNs='Xunit.Abstractions'},
  @{Id='Novolis.Testing.Testcontainers';Desc='Testcontainers helpers'},
  @{Id='Novolis.Testing.TestServer';Desc='In-memory test server helpers'}
)
foreach ($p in $testingProjects) {
  $extra = ''
  if ($p.Id -eq 'Novolis.Testing.Xunit') {
    $extra = @'
    <PropertyGroup><RootNamespace>Xunit.Abstractions</RootNamespace></PropertyGroup>
    <ItemGroup>
      <PackageReference Include="ConsoleTableExt" />
      <PackageReference Include="Microsoft.CodeAnalysis.CSharp" />
      <PackageReference Include="TUnit.Core" />
      <PackageReference Include="VarDump" />
    </ItemGroup>
'@
  } elseif ($p.Id -eq 'Novolis.Testing.Logging') {
    $extra = @'
    <ItemGroup>
      <PackageReference Include="JetBrains.Annotations" />
      <PackageReference Include="Microsoft.Extensions.Logging" />
      <PackageReference Include="Microsoft.Extensions.Options" />
      <PackageReference Include="TUnit.Core" />
      <ProjectReference Include="..\Novolis.Testing.TestBases\Novolis.Testing.TestBases.csproj" />
    </ItemGroup>
'@
  } elseif ($p.Id -eq 'Novolis.Testing.Testcontainers') {
    $extra = '<ItemGroup><PackageReference Include="Testcontainers" /></ItemGroup>'
  } elseif ($p.Id -eq 'Novolis.Testing.TestServer') {
    $extra = '<ItemGroup><FrameworkReference Include="Microsoft.AspNetCore.App" /></ItemGroup>'
  }
  W "$t\src\$($p.Id)\$($p.Id).csproj" @"
<Project Sdk=`"Microsoft.NET.Sdk`">
  <PropertyGroup>
    <PackageId>$($p.Id)</PackageId>
    <Version>0.1.0-preview.1</Version>
    <Description>$($p.Desc)</Description>
    <IsPackable>true</IsPackable>
  </PropertyGroup>
  $extra
</Project>
"@
}
W "$t\Novolis.Testing.slnx" @'
<Solution>
  <Folder Name="/src/">
    <Project Path="src/Novolis.Testing.TestBases/Novolis.Testing.TestBases.csproj" />
    <Project Path="src/Novolis.Testing.Logging/Novolis.Testing.Logging.csproj" />
    <Project Path="src/Novolis.Testing.Xunit/Novolis.Testing.Xunit.csproj" />
    <Project Path="src/Novolis.Testing.Testcontainers/Novolis.Testing.Testcontainers.csproj" />
    <Project Path="src/Novolis.Testing.TestServer/Novolis.Testing.TestServer.csproj" />
  </Folder>
</Solution>
'@
W "$t\.novolis\packages.json" '{"packages":{"Novolis.Testing.TestBases":{"project":"src/Novolis.Testing.TestBases/Novolis.Testing.TestBases.csproj","paths":["src/Novolis.Testing.TestBases/**"]},"Novolis.Testing.Logging":{"project":"src/Novolis.Testing.Logging/Novolis.Testing.Logging.csproj","paths":["src/Novolis.Testing.Logging/**"]},"Novolis.Testing.Xunit":{"project":"src/Novolis.Testing.Xunit/Novolis.Testing.Xunit.csproj","paths":["src/Novolis.Testing.Xunit/**"]},"Novolis.Testing.Testcontainers":{"project":"src/Novolis.Testing.Testcontainers/Novolis.Testing.Testcontainers.csproj","paths":["src/Novolis.Testing.Testcontainers/**"]},"Novolis.Testing.TestServer":{"project":"src/Novolis.Testing.TestServer/Novolis.Testing.TestServer.csproj","paths":["src/Novolis.Testing.TestServer/**"]}}}'

# Fix usings in testing
Get-ChildItem $t\src -Recurse -Filter *.cs | ForEach-Object {
  $c = gc $_.FullName -Raw
  $c = $c -replace 'using Frank\.Reflection\.Dump','using Novolis.Testing.Xunit.Dump'
  $c = $c -replace 'using Frank\.Reflection','using Novolis.Testing.Internal'
  sc $_.FullName $c -Encoding utf8
}
# Fix TestOutputCSharpExtensions namespace for Dump
$cs = "$t\src\Novolis.Testing.Xunit\TestOutputCSharpExtensions.cs"
if (Test-Path $cs) { (gc $cs -Raw) -replace 'using VarDump;','using Novolis.Testing.Xunit.Dump;`nusing VarDump;' | sc $cs -Encoding utf8 }

# --- TRANSPORTS ---
$tr = 'D:\novolis\novolis-transports'
Remove-FrankCsproj $tr
W "$tr\Directory.Packages.props" @'
<Project>
  <PropertyGroup><ManagePackageVersionsCentrally>true</ManagePackageVersionsCentrally></PropertyGroup>
  <ItemGroup>
    <PackageVersion Include="FluentAssertions" Version="8.9.0" />
    <PackageVersion Include="Microsoft.Extensions.Http" Version="10.0.5" />
    <PackageVersion Include="Microsoft.NET.Test.Sdk" Version="17.14.0" />
    <PackageVersion Include="xunit" Version="2.9.3" />
    <PackageVersion Include="xunit.runner.visualstudio" Version="3.0.2" />
  </ItemGroup>
</Project>
'@
W "$tr\src\Novolis.Transports.Tcp.Cryptography\Novolis.Transports.Tcp.Cryptography.csproj" '<Project Sdk="Microsoft.NET.Sdk"><PropertyGroup><IsPackable>false</IsPackable></PropertyGroup></Project>'
W "$tr\src\Novolis.Transports.Tcp.Server\Novolis.Transports.Tcp.Server.csproj" @'
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup><PackageId>Novolis.Transports.Tcp.Server</PackageId><Version>0.1.0-preview.1</Version><IsPackable>true</IsPackable></PropertyGroup>
  <ItemGroup><FrameworkReference Include="Microsoft.AspNetCore.App" /><ProjectReference Include="..\Novolis.Transports.Tcp.Cryptography\Novolis.Transports.Tcp.Cryptography.csproj" /></ItemGroup>
</Project>
'@
W "$tr\src\Novolis.Transports.Tcp.Client\Novolis.Transports.Tcp.Client.csproj" '<Project Sdk="Microsoft.NET.Sdk"><PropertyGroup><PackageId>Novolis.Transports.Tcp.Client</PackageId><Version>0.1.0-preview.1</Version><IsPackable>true</IsPackable></PropertyGroup></Project>'
W "$tr\src\Novolis.Transports.Http.Abstractions\Novolis.Transports.Http.Abstractions.csproj" '<Project Sdk="Microsoft.NET.Sdk"><PropertyGroup><PackageId>Novolis.Transports.Http.Abstractions</PackageId><Version>0.1.0-preview.1</Version><IsPackable>true</IsPackable></PropertyGroup></Project>'
W "$tr\src\Novolis.Transports.Http\Novolis.Transports.Http.csproj" @'
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup><PackageId>Novolis.Transports.Http</PackageId><Version>0.1.0-preview.1</Version><IsPackable>true</IsPackable></PropertyGroup>
  <ItemGroup>
    <PackageReference Include="Microsoft.Extensions.Http" />
    <ProjectReference Include="..\Novolis.Transports.Http.Abstractions\Novolis.Transports.Http.Abstractions.csproj" />
    <ProjectReference Include="..\Novolis.Transports.Http.Authentication\Novolis.Transports.Http.Authentication.csproj" />
    <ProjectReference Include="..\Novolis.Transports.Http.Extensions\Novolis.Transports.Http.Extensions.csproj" />
  </ItemGroup>
</Project>
'@
W "$tr\src\Novolis.Transports.Http.Authentication\Novolis.Transports.Http.Authentication.csproj" '<Project Sdk="Microsoft.NET.Sdk"><PropertyGroup><PackageId>Novolis.Transports.Http.Authentication</PackageId><Version>0.1.0-preview.1</Version><IsPackable>true</IsPackable></PropertyGroup><ItemGroup><ProjectReference Include="..\Novolis.Transports.Http.Abstractions\Novolis.Transports.Http.Abstractions.csproj" /></ItemGroup></Project>'
W "$tr\src\Novolis.Transports.Http.Extensions\Novolis.Transports.Http.Extensions.csproj" '<Project Sdk="Microsoft.NET.Sdk"><PropertyGroup><PackageId>Novolis.Transports.Http.Extensions</PackageId><Version>0.1.0-preview.1</Version><IsPackable>true</IsPackable></PropertyGroup><ItemGroup><ProjectReference Include="..\Novolis.Transports.Http.Abstractions\Novolis.Transports.Http.Abstractions.csproj" /></ItemGroup></Project>'
W "$tr\tests\Novolis.Transports.Tcp.Tests\Novolis.Transports.Tcp.Tests.csproj" @'
<Project Sdk="Microsoft.NET.Sdk"><PropertyGroup><IsPackable>false</IsPackable><IsTestProject>true</IsTestProject></PropertyGroup>
<ItemGroup><PackageReference Include="FluentAssertions" /><PackageReference Include="Microsoft.NET.Test.Sdk" /><PackageReference Include="xunit" /><PackageReference Include="xunit.runner.visualstudio" />
<ProjectReference Include="..\..\src\Novolis.Transports.Tcp.Server\Novolis.Transports.Tcp.Server.csproj" /><ProjectReference Include="..\..\src\Novolis.Transports.Tcp.Client\Novolis.Transports.Tcp.Client.csproj" /></ItemGroup></Project>
'@
W "$tr\tests\Novolis.Transports.Http.Tests\Novolis.Transports.Http.Tests.csproj" @'
<Project Sdk="Microsoft.NET.Sdk"><PropertyGroup><IsPackable>false</IsPackable><IsTestProject>true</IsTestProject></PropertyGroup>
<ItemGroup><PackageReference Include="Microsoft.NET.Test.Sdk" /><PackageReference Include="xunit" /><PackageReference Include="xunit.runner.visualstudio" />
<ProjectReference Include="..\..\src\Novolis.Transports.Http\Novolis.Transports.Http.csproj" /></ItemGroup></Project>
'@
W "$tr\Novolis.Transports.slnx" @'
<Solution>
  <Folder Name="/src/">
    <Project Path="src/Novolis.Transports.Tcp.Cryptography/Novolis.Transports.Tcp.Cryptography.csproj" />
    <Project Path="src/Novolis.Transports.Tcp.Server/Novolis.Transports.Tcp.Server.csproj" />
    <Project Path="src/Novolis.Transports.Tcp.Client/Novolis.Transports.Tcp.Client.csproj" />
    <Project Path="src/Novolis.Transports.Http.Abstractions/Novolis.Transports.Http.Abstractions.csproj" />
    <Project Path="src/Novolis.Transports.Http.Authentication/Novolis.Transports.Http.Authentication.csproj" />
    <Project Path="src/Novolis.Transports.Http.Extensions/Novolis.Transports.Http.Extensions.csproj" />
    <Project Path="src/Novolis.Transports.Http/Novolis.Transports.Http.csproj" />
  </Folder>
  <Folder Name="/tests/">
    <Project Path="tests/Novolis.Transports.Tcp.Tests/Novolis.Transports.Tcp.Tests.csproj" />
    <Project Path="tests/Novolis.Transports.Http.Tests/Novolis.Transports.Http.Tests.csproj" />
  </Folder>
</Solution>
'@

# --- STORAGE ---
$st = 'D:\novolis\novolis-storage'
Remove-FrankCsproj $st
W "$st\Directory.Packages.props" @'
<Project>
  <PropertyGroup><ManagePackageVersionsCentrally>true</ManagePackageVersionsCentrally></PropertyGroup>
  <ItemGroup>
    <PackageVersion Include="FluentAssertions" Version="8.9.0" />
    <PackageVersion Include="Microsoft.Data.Sqlite" Version="10.0.0" />
    <PackageVersion Include="Microsoft.Extensions.Options.ConfigurationExtensions" Version="10.0.5" />
    <PackageVersion Include="Microsoft.NET.Test.Sdk" Version="17.14.0" />
    <PackageVersion Include="xunit" Version="2.9.3" />
    <PackageVersion Include="xunit.runner.visualstudio" Version="3.0.2" />
  </ItemGroup>
</Project>
'@
W "$st\src\Novolis.Storage.Abstractions\Novolis.Storage.Abstractions.csproj" @'
<Project Sdk="Microsoft.NET.Sdk"><PropertyGroup><PackageId>Novolis.Storage.Abstractions</PackageId><Version>0.1.0-preview.1</Version><IsPackable>true</IsPackable></PropertyGroup>
<ItemGroup><PackageReference Include="Microsoft.Extensions.Options.ConfigurationExtensions" /></ItemGroup></Project>
'@
W "$st\src\Novolis.Storage.Json\Novolis.Storage.Json.csproj" '<Project Sdk="Microsoft.NET.Sdk"><PropertyGroup><PackageId>Novolis.Storage.Json</PackageId><Version>0.1.0-preview.1</Version><IsPackable>true</IsPackable></PropertyGroup><ItemGroup><ProjectReference Include="..\Novolis.Storage.Abstractions\Novolis.Storage.Abstractions.csproj" /></ItemGroup></Project>'
W "$st\src\Novolis.Storage.Sqlite\Novolis.Storage.Sqlite.csproj" @'
<Project Sdk="Microsoft.NET.Sdk"><PropertyGroup><PackageId>Novolis.Storage.Sqlite</PackageId><Version>0.1.0-preview.1</Version><IsPackable>true</IsPackable></PropertyGroup>
<ItemGroup><PackageReference Include="Microsoft.Data.Sqlite" /><ProjectReference Include="..\Novolis.Storage.Abstractions\Novolis.Storage.Abstractions.csproj" /></ItemGroup></Project>
'@
W "$st\tests\Novolis.Storage.Tests\Novolis.Storage.Tests.csproj" @'
<Project Sdk="Microsoft.NET.Sdk"><PropertyGroup><IsPackable>false</IsPackable><IsTestProject>true</IsTestProject></PropertyGroup>
<ItemGroup><PackageReference Include="FluentAssertions" /><PackageReference Include="Microsoft.NET.Test.Sdk" /><PackageReference Include="xunit" /><PackageReference Include="xunit.runner.visualstudio" />
<ProjectReference Include="..\..\src\Novolis.Storage.Json\Novolis.Storage.Json.csproj" /><ProjectReference Include="..\..\src\Novolis.Storage.Sqlite\Novolis.Storage.Sqlite.csproj" /></ItemGroup></Project>
'@
W "$st\Novolis.Storage.slnx" @'
<Solution>
  <Folder Name="/src/">
    <Project Path="src/Novolis.Storage.Abstractions/Novolis.Storage.Abstractions.csproj" />
    <Project Path="src/Novolis.Storage.Json/Novolis.Storage.Json.csproj" />
    <Project Path="src/Novolis.Storage.Sqlite/Novolis.Storage.Sqlite.csproj" />
  </Folder>
  <Folder Name="/tests/"><Project Path="tests/Novolis.Storage.Tests/Novolis.Storage.Tests.csproj" /></Folder>
</Solution>
'@
# Remove non-wave3 tests
Get-ChildItem "$st\tests\Novolis.Storage.Tests\Repositories" -ErrorAction SilentlyContinue | Where-Object { $_.Name -notmatch 'Json|Sqlite' } | Remove-Item -Recurse -Force
Remove-Item "$st\tests\Novolis.Storage.Tests\Shared\DataStorageTestBase.cs" -Force -ErrorAction SilentlyContinue

# --- SECURITY ---
$se = 'D:\novolis\novolis-security'
Remove-FrankCsproj $se
W "$se\Directory.Packages.props" @'
<Project>
  <PropertyGroup><ManagePackageVersionsCentrally>true</ManagePackageVersionsCentrally></PropertyGroup>
  <ItemGroup>
    <PackageVersion Include="FluentAssertions" Version="8.9.0" />
    <PackageVersion Include="Microsoft.Extensions.Options" Version="10.0.5" />
    <PackageVersion Include="Microsoft.NET.Test.Sdk" Version="17.14.0" />
    <PackageVersion Include="xunit" Version="2.9.3" />
    <PackageVersion Include="xunit.runner.visualstudio" Version="3.0.2" />
  </ItemGroup>
</Project>
'@
W "$se\src\Novolis.Security.Resources\Novolis.Security.Resources.csproj" '<Project Sdk="Microsoft.NET.Sdk"><PropertyGroup><IsPackable>false</IsPackable></PropertyGroup></Project>'
W "$se\src\Novolis.Security.Cryptography\Novolis.Security.Cryptography.csproj" @'
<Project Sdk="Microsoft.NET.Sdk"><PropertyGroup><PackageId>Novolis.Security.Cryptography</PackageId><Version>0.1.0-preview.1</Version><IsPackable>true</IsPackable></PropertyGroup>
<ItemGroup><PackageReference Include="Microsoft.Extensions.Options" /><ProjectReference Include="..\Novolis.Security.Resources\Novolis.Security.Resources.csproj" /></ItemGroup></Project>
'@
W "$se\src\Novolis.Security.HaveIBeenPwned\Novolis.Security.HaveIBeenPwned.csproj" '<Project Sdk="Microsoft.NET.Sdk"><PropertyGroup><PackageId>Novolis.Security.HaveIBeenPwned</PackageId><Version>0.1.0-preview.1</Version><IsPackable>true</IsPackable></PropertyGroup></Project>'
W "$se\tests\Novolis.Security.Tests\Novolis.Security.Tests.csproj" @'
<Project Sdk="Microsoft.NET.Sdk"><PropertyGroup><IsPackable>false</IsPackable><IsTestProject>true</IsTestProject></PropertyGroup>
<ItemGroup><PackageReference Include="FluentAssertions" /><PackageReference Include="Microsoft.NET.Test.Sdk" /><PackageReference Include="xunit" /><PackageReference Include="xunit.runner.visualstudio" />
<ProjectReference Include="..\..\src\Novolis.Security.Cryptography\Novolis.Security.Cryptography.csproj" /><ProjectReference Include="..\..\src\Novolis.Security.HaveIBeenPwned\Novolis.Security.HaveIBeenPwned.csproj" /></ItemGroup></Project>
'@
W "$se\Novolis.Security.slnx" @'
<Solution>
  <Folder Name="/src/">
    <Project Path="src/Novolis.Security.Resources/Novolis.Security.Resources.csproj" />
    <Project Path="src/Novolis.Security.Cryptography/Novolis.Security.Cryptography.csproj" />
    <Project Path="src/Novolis.Security.HaveIBeenPwned/Novolis.Security.HaveIBeenPwned.csproj" />
  </Folder>
  <Folder Name="/tests/"><Project Path="tests/Novolis.Security.Tests/Novolis.Security.Tests.csproj" /></Folder>
</Solution>
'@

Strip-Ver $t; Strip-Ver $tr; Strip-Ver $st; Strip-Ver $se
Write-Host 'Remaining repos scaffolded.'
