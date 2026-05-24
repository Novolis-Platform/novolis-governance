# GitHub Packages — organization settings (Novolis-Platform)

Dogfooding and other repos should restore `Novolis.*` from GitHub Packages **without a custom PAT secret**. GitHub’s NuGet registry still requires *some* credential on every restore (even for **public** packages), but that can be the built-in **`GITHUB_TOKEN` in Actions** or your existing **`gh` login** locally—not a hand-copied token.

Configure the org once as below, then publish libraries with `RepositoryUrl` set (see `Novolis.GitHubPackages.props`).

## 1. Organization package defaults

Open: [Novolis-Platform → Settings → Packages](https://github.com/organizations/Novolis-Platform/settings/packages)

Under **Default package settings**:

- Enable **Inherit access from source repository** (recommended).
- Do **not** enable “Disable automatic inheritance of access permissions” for new packages.

Under **Package creation**:

- Allow **Public** packages only (required so new publishes can be made public via CI).
- If **Private** is the only option, new packages stay private until changed manually.

CI (`set-github-packages-public` after each merge publish) calls  
`PATCH /orgs/Novolis-Platform/packages/nuget/{name}/visibility` with `GITHUB_TOKEN` (`packages: write`).

To fix **existing** private packages once:

```powershell
gh auth refresh -h github.com -s read:packages,write:packages
pwsh ./novolis-governance/scripts/set-org-nuget-packages-public.ps1
```

## 2. Per-package visibility (existing NuGet packages)

For each package under [Packages](https://github.com/orgs/Novolis-Platform/packages?ecosystem=nuget) (e.g. `Novolis.Math.Geometry`):

1. **Package settings** → **Danger zone** → **Change visibility** → **Public** (one-way; cannot revert to private).
2. **Connect repository** → link to the publishing repo (`novolis-math`, `novolis-rendering`, …).
3. Enable **Inherit access from repository** when offered.
4. **Manage Actions access** → add **`novolis-dogfooding`** (read) so dogfood CI can restore without `NOVOLIS_GPR_TOKEN`.

New publishes that include `RepositoryUrl` in the `.csproj` / pack metadata are linked automatically on first push.

## 3. What developers run locally

No org secret required. One-time:

```powershell
gh auth refresh -h github.com -s read:packages
```

Then:

```powershell
cd novolis-dogfooding
dotnet restore Novolis.Dogfooding.slnx --configfile nuget.config
```

`prepare-dogfood-packages.ps1` (Rider/MSBuild) calls the same auth helper.

## 4. CI (dogfooding and library repos)

- **Dogfooding** uses `GITHUB_TOKEN` (`packages: read`) after packages grant **`novolis-dogfooding`** Actions access.
- **Library repos** publish with the same token (`packages: write`) in their own repo.
- Cross-repo restore in **library** CI still needs either public packages + linked public repos, or org secret `NOVOLIS_GPR_TOKEN` until all packages are public and linked.

## References

- [Working with the NuGet registry](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-nuget-registry)
- [Configuring package access and visibility](https://docs.github.com/en/packages/learn-github-packages/configuring-a-packages-access-control-and-visibility)
