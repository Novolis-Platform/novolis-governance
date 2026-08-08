---
name: Landing CI table
overview: Add a concise Build / Package / Release table to the GitHub org landing page (`profile/README.md`), mirroring the canonical three-stage NuGet pipeline already documented in governance.
todos:
  - id: add-pipeline-section
    content: Add Build/Package/Release section + table to .github/profile/README.md
    status: completed
  - id: extend-policies-links
    content: Add nuget-setup, release-policy, and novolis-workflows links to Policies & docs table
    status: completed
isProject: false
---

# Build / package / release table on org landing page

## Target

Update the org home README at [`.github/profile/README.md`](.github/profile/README.md) (this is what GitHub shows for [Novolis-Platform](https://github.com/Novolis-Platform)). No change to [`.github/README.md`](.github/README.md) beyond an optional one-line pointer if useful — the landing page is `profile/README.md`.

## Content

Insert a new section **after Ecosystem** (or after Design Ideas) and **before Brand**, titled something like `## Build, package & release`, matching the existing emoji section style.

**Primary table** (package libraries — the org default):

| Stage | Trigger | What happens |
|-------|---------|--------------|
| Build | PR to `main` (`pull-request.yml`) | Restore, build, test — no publish |
| Package | Push to `main` (`merge.yml`) | Pack `YEAR.MAJOR.MINOR.{run}` → [GitHub Packages](https://github.com/orgs/Novolis-Platform/packages) |
| Release | GitHub Release published (`release.yml`) | Same version shape → [nuget.org](https://www.nuget.org/) + release assets |

One short note under the table:

- Versions are four-part numeric only (`2026.1.1.351`) — see [nuget-versioning.md](https://github.com/Novolis-Platform/.github/blob/main/docs/nuget-versioning.md).
- Desktop apps (`novolis-apps`) ship zip/installers via GitHub Releases instead of nuget.org.

Do **not** invent a large per-repo matrix on the landing page; keep that in governance docs.

## Policy links

Extend the existing **Policies & docs** table with:

| Resource | Link |
|----------|------|
| CI & package publishing | [nuget-setup.md](https://github.com/Novolis-Platform/novolis-governance/blob/main/docs/nuget-setup.md) |
| Release & versioning | [release-policy.md](https://github.com/Novolis-Platform/novolis-governance/blob/main/docs/release-policy.md) |
| Reusable workflows | [novolis-workflows](https://github.com/Novolis-Platform/novolis-workflows) |

## Source of truth (no new policy docs)

Wording stays aligned with:

- [`novolis-governance/docs/nuget-setup.md`](novolis-governance/docs/nuget-setup.md)
- [`novolis-governance/docs/release-policy.md`](novolis-governance/docs/release-policy.md)
- [`novolis-workflows/README.md`](novolis-workflows/README.md)

## Out of scope

- Changing reusable workflows or consumer `*.yml` files
- Fixing gaps (`novolis-io` missing `release.yml`, repos without CI)
- Rewriting `.github/docs/nuget-versioning.md` (still has legacy workflow examples)
