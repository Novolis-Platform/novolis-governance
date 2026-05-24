# Package publishing setup (GitHub Packages)

Novolis packages are published to **[GitHub Packages](https://github.com/orgs/Novolis-Platform/packages)**, not nuget.org.

## Feed URL

```text
https://nuget.pkg.github.com/Novolis-Platform/index.json
```

## CI

Each package repo uses `merge.yml` → `dotnet-merge-publish.yml`:

- Authenticates with `GITHUB_TOKEN` (`packages: write`)
- Pushes `artifacts/packages/*.nupkg` to the org feed
- Bumps `.novolis/version.props` build segment after a successful push

No NuGet.org API keys or trusted publishing setup is required.

## Consuming packages

Add a `nuget.config` (or user-level config) with a GitHub PAT that has `read:packages`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<configuration>
  <packageSources>
    <clear />
    <add key="nuget.org" value="https://api.nuget.org/v3/index.json" />
    <add key="github" value="https://nuget.pkg.github.com/Novolis-Platform/index.json" />
  </packageSources>
  <packageSourceCredentials>
    <github>
      <add key="Username" value="YOUR_GITHUB_USERNAME" />
      <add key="ClearTextPassword" value="YOUR_PAT_WITH_READ_PACKAGES" />
    </github>
  </packageSourceCredentials>
</configuration>
```

## Future: nuget.org

When ready for public nuget.org releases, re-enable `publish-nuget` and trusted publishing per repo. Until then, workflows intentionally avoid nuget.org.
