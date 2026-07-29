# Package publishing policy

- Prefer NuGet Trusted Publishing (OIDC). Do not store broad NuGet API keys.
- Do not publish from pull requests or forks.
- Publish only from GitHub Release, signed version tag, or approved `nuget.org` environment.
- Environment `nuget.org`: maintainer approval required; no secret exposure to PRs.

Required package metadata:

```xml
<PackageId>Novolis.X</PackageId>
<Title>Novolis X</Title>
<Description>...</Description>
<Authors>Novolis</Authors>
<RepositoryUrl>...</RepositoryUrl>
<RepositoryType>git</RepositoryType>
<PackageLicenseExpression>MIT</PackageLicenseExpression>
<PackageReadmeFile>README.md</PackageReadmeFile>
<PackageIcon>icon.png</PackageIcon>
<PublishRepositoryUrl>true</PublishRepositoryUrl>
<ContinuousIntegrationBuild>true</ContinuousIntegrationBuild>
<EmbedUntrackedSources>true</EmbedUntrackedSources>
<EnableSourceLink>true</EnableSourceLink>
<IncludeSymbols>true</IncludeSymbols>
<SymbolPackageFormat>snupkg</SymbolPackageFormat>
```

SourceLink (via `Microsoft.SourceLink.GitHub` in `Directory.Build.props` / `Directory.Packages.props`) maps published assemblies to GitHub source for debugger stepping.
