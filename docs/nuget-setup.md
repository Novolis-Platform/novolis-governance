# NuGet.org setup for Novolis

Use a **NuGet.org organization**, not a personal account alone, so package ownership matches [Novolis-Platform](https://github.com/Novolis-Platform) on GitHub.

## 1. Sign in and create the org

1. Sign in at [nuget.org](https://www.nuget.org/) with your Microsoft account (the one you already use is fine).
2. Create an organization: [Add organization](https://www.nuget.org/organizations/add).
   - Suggested name: **Novolis** (profile URL becomes `https://www.nuget.org/profiles/Novolis` or similar).
3. Add at least one other maintainer as org member when available (governance requires two people with access).

Your personal account stays the admin who created the org; packages should be owned by the **organization**.

## 2. Reserve the package ID prefix (recommended)

Request prefix reservation so only your org can publish `Novolis.*`:

- [ID prefix reservation](https://learn.microsoft.com/nuget/nuget-org/id-prefix-reservation)
- Apply for prefix: `Novolis`
- Point to your GitHub org and representative packages (e.g. `Novolis.TemplateSmokeTest` after first publish).

## 3. Trusted publishing (CI — no long-lived API keys)

Do **not** store a broad NuGet API key in GitHub. Use [trusted publishing](https://learn.microsoft.com/nuget/nuget-org/trusted-publishing).

On nuget.org (under the **organization**):

1. Open **Trusted Publishing** (account menu → your org → Trusted Publishing).
2. Add a policy **owned by the Novolis organization** (not your personal user, if possible).
3. For the smoke test repo, use:

| Field | Value |
|-------|--------|
| Repository owner | `Novolis-Platform` |
| Repository | `novolis-smoketest` |
| Workflow file | `release.yml` |
| Environment (optional) | `nuget.org` |

Repeat per repo when you add more package repositories.

> If Trusted Publishing is not visible yet, NuGet is still rolling it out. Use a **scoped** push API key temporarily (push only, `Novolis.*` glob), store it only in the `nuget.org` environment as `NUGET_API_KEY`, and switch to OIDC when available.

## 4. GitHub configuration

### Organization variable

Set once for all repos that publish:

| Variable | Example | Where |
|----------|---------|--------|
| `NUGET_USERNAME` | `Novolis` | [Org variables](https://github.com/organizations/Novolis-Platform/settings/variables/actions) |

Use your **nuget.org profile name** (organization slug), not your email.

### Environment `nuget.org` (per publishing repo)

On `novolis-smoketest` (and later package repos):

- Environment name: `nuget.org`
- Required reviewers: at least one maintainer
- Deployment branches: release tags only (`v*`)

The release workflow uses `environment: nuget.org` and `NuGet/login@v1` with OIDC.

## 5. Validate with smoke test only

1. Ensure `Novolis.TemplateSmokeTest` builds on `main`.
2. Create a GitHub release with tag `v0.1.0` matching the package version in the `.csproj`.
3. Approve the `nuget.org` environment deployment when prompted.
4. Confirm the package appears under the **org** on nuget.org.

Do not publish migrated production libraries until this path is verified.

## 6. Local development (optional)

Trusted publishing is for CI. For local `dotnet nuget push`:

1. Create a **scoped** API key on nuget.org (Push, glob `Novolis.TemplateSmokeTest` or `Novolis.*`).
2. Store it locally only (never commit):

```powershell
dotnet nuget push .\artifacts\packages\*.nupkg `
  --source https://api.nuget.org/v3/index.json `
  --api-key YOUR_SCOPED_KEY
```

Or set `NUGET_API_KEY` in your user environment for the current session.

Prefer testing publish via GitHub Release + trusted publishing so CI matches production.

## Checklist

- [ ] NuGet.org organization created
- [ ] Second maintainer invited (when available)
- [ ] `Novolis` prefix reservation requested
- [ ] Trusted publishing policy for `novolis-smoketest` / `release.yml` / `nuget.org`
- [ ] GitHub org variable `NUGET_USERNAME` set
- [ ] Smoke test release `v0.1.0` published successfully
