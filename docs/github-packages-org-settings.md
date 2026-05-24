# GitHub Packages — organization settings (Novolis-Platform)

Published Novolis NuGet packages should be **public** so any authenticated GitHub user (`gh` token) and CI `GITHUB_TOKEN` can restore them without an org-wide `NOVOLIS_GPR_TOKEN`. **Public does not mean anonymous**: the NuGet feed still requires authentication on every request.

## Required one-time org setting (makes new publishes public by default)

Open: [Novolis-Platform → Settings → Packages](https://github.com/organizations/Novolis-Platform/settings/packages)

Under **Package creation**:

- Enable **Public**
- Disable **Private** (and **Internal** unless you need it)

GitHub documents this as choosing the visibility members publish **by default**. After this change, **new** package versions published from CI should be public without using the UI per package.

Under **Default package settings**:

- Enable **Inherit access from source repository**

## Existing private packages

GitHub’s [Packages REST API](https://docs.github.com/en/rest/packages/packages) has **no** endpoint to change NuGet visibility (`PATCH .../packages/nuget/{name}/visibility` returns 404; there is no `gh package` command). Visibility is UI-only, or delete + republish.

After enabling **Public** package creation above (disable **Private** / **Internal** if you want new publishes to default to public):

1. [Packages](https://github.com/orgs/Novolis-Platform/packages?ecosystem=nuget) → package → **Package settings** → **Change visibility** → **Public**, or  
2. Delete the private package and merge to `main` again so CI republishes (with org **Public** creation enabled).

Local bulk delete (then merge/republish per repo):

```powershell
gh auth refresh -h github.com -s read:packages,write:packages,delete:packages
.\novolis-governance\scripts\set-org-nuget-packages-public.ps1 -ListOnly
.\novolis-governance\scripts\set-org-nuget-packages-public.ps1 -DeletePrivate
```

## CI

Merge publish (`merge.yml`) pushes to GitHub Packages. Package visibility is set in the org UI (the REST visibility API is not available for org NuGet packages).

Publishing sets `RepositoryUrl` via `Novolis.GitHubPackages.props` so packages link to their source repo.

## Dogfooding restore

- CI: `GITHUB_TOKEN` with `packages: read` (no `NOVOLIS_GPR_TOKEN` when packages are public and linked).
- Local: `.\novolis-governance\scripts\configure-gpr-user-nuget.ps1` (user `%APPDATA%\NuGet\NuGet.Config`, not repo `nuget.config`)

## References

- [Configuring package access and visibility](https://docs.github.com/en/packages/learn-github-packages/configuring-a-packages-access-control-and-visibility)
- [Working with the NuGet registry](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-nuget-registry)
