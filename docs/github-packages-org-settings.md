# GitHub Packages — organization settings (Novolis-Platform)

Published Novolis NuGet packages should be **public** so dogfooding and other repos can restore them with `GITHUB_TOKEN` / `gh` (no org PAT).

## Required one-time org setting (makes new publishes public by default)

Open: [Novolis-Platform → Settings → Packages](https://github.com/organizations/Novolis-Platform/settings/packages)

Under **Package creation**:

- Enable **Public**
- Disable **Private** (and **Internal** unless you need it)

GitHub documents this as choosing the visibility members publish **by default**. After this change, **new** package versions published from CI should be public without using the UI per package.

Under **Default package settings**:

- Enable **Inherit access from source repository**

## Existing private packages

GitHub does **not** expose a working REST `PATCH` for org-scoped **NuGet** visibility (returns 404). After enabling **Public** package creation above:

1. In each package repo, run **Actions → Republish NuGet as public** (`republish-public.yml`), or  
2. Manually: [Packages](https://github.com/orgs/Novolis-Platform/packages?ecosystem=nuget) → **Package settings** → **Change visibility** → **Public**.

The republish workflow deletes the org NuGet package(s) for that repo and pushes again; with org **Public** creation enabled, the new package should be public. CI verifies visibility at the end of that workflow.

## CI (automatic after each publish)

Merge publish runs `set-github-packages-public` after `publish-github-packages`. It succeeds when GitHub accepts the visibility API; otherwise it logs a warning and the org steps above are required.

Publishing also sets `RepositoryUrl` via `Novolis.GitHubPackages.props` so packages link to their source repo.

## Dogfooding restore

- CI: `GITHUB_TOKEN` with `packages: read` (no `NOVOLIS_GPR_TOKEN` when packages are public and linked).
- Local: `gh auth refresh -h github.com -s read:packages`

## References

- [Configuring package access and visibility](https://docs.github.com/en/packages/learn-github-packages/configuring-a-packages-access-control-and-visibility)
- [Working with the NuGet registry](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-nuget-registry)
