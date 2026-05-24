# Package publishing setup (GitHub Packages)

Novolis packages are published to **[GitHub Packages](https://github.com/orgs/Novolis-Platform/packages)**, not nuget.org.

## Feed URL

```text
https://nuget.pkg.github.com/Novolis-Platform/index.json
```

## CI

Each package repo uses a single **`CI`** workflow:

- **Pull requests** — build and test only
- **Push to `main`** — build, test, pack, push to GitHub Packages, bump `.novolis/version.props` build segment

Publishing uses `GITHUB_TOKEN` (`packages: write`) for packages **in that repository**.

### Cross-repo dependencies

`GITHUB_TOKEN` cannot restore packages published from **other** Novolis repos. For repos that reference `Novolis.*` from GitHub Packages (e.g. `novolis-rendering` → `Novolis.Math.Geometry`), add an organization secret:

| Secret | Scopes | Purpose |
|--------|--------|---------|
| `NOVOLIS_GPR_TOKEN` | `read:packages` | CI restore of Novolis packages from other repos |

Public packages can often be restored **without** a token; if restore returns 403, add `NOVOLIS_GPR_TOKEN` or ensure package visibility is public.

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
