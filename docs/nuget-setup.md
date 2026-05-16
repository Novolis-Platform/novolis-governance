# NuGet organization setup

Before publishing packages:

1. Create a NuGet.org organization for Novolis.
2. Reserve `Novolis.*` package IDs where practical.
3. Configure [trusted publishing](https://learn.microsoft.com/nuget/nuget-org/publish-a-package#trusted-publishing) (OIDC) for `Novolis-Platform/novolis-smoketest`.
4. Create GitHub Environment `nuget.org` with required reviewer approval.
5. Validate with `Novolis.TemplateSmokeTest` only — do not publish migrated libraries yet.

## GitHub Environment

Repository: `novolis-smoketest` (and later package repos)

Environment name: `nuget.org`

- Required reviewers: at least one maintainer
- Deployment branches: tagged releases only
- No environment secrets exposed to fork PRs
