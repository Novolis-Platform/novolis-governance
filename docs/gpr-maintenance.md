# GitHub Packages (GPR) maintenance

Operational runbook for keeping the Novolis org NuGet feed healthy. Floats (`2026.1.*`) only work when the feed has no throwaway versions and packages are linked to their publishing repos.

## Quick overview

```powershell
# Full health check (GPR + local checkout)
pwsh -File novolis-governance/scripts/gpr-health-check.ps1

# Local-only (floats, local feeds, stale ids, ProjectReference leaks, project-ref mode)
pwsh -File novolis-governance/scripts/gpr-health-check.ps1 -SkipRemote

# Also verify latest nuspecs do not require missing Novolis dependency versions (slow)
pwsh -File novolis-governance/scripts/gpr-health-check.ps1 -CheckBrokenDeps

# Inventory table (latest version, repo link, junk flags)
pwsh -File novolis-governance/scripts/gpr-package-overview.ps1
```

Requires `gh` authenticated with `read:packages` (delete needs `delete:packages` / org admin).

## Scripts

| Script | Purpose | Exit |
|--------|---------|------|
| [`gpr-health-check.ps1`](../scripts/gpr-health-check.ps1) | One-shot: overview + junk + floats + local feeds + stale ids + nuget-only + project-ref mode | 1 if any hard check fails |
| [`gpr-package-overview.ps1`](../scripts/gpr-package-overview.ps1) | Package inventory (latest, versions, linked repo, visibility) | 1 if unlinked or junk present |
| [`gpr-find-junk-versions.ps1`](../scripts/gpr-find-junk-versions.ps1) | List throwaway versions that poison `2026.1.*` | 1 if any found |
| [`gpr-remove-junk-versions.ps1`](../scripts/gpr-remove-junk-versions.ps1) | Delete junk versions (`-WhatIf` first) | 1 on API failure |
| [`gpr-find-broken-deps.ps1`](../scripts/gpr-find-broken-deps.ps1) | Latest nuspec depends on a Novolis version missing from GPR | 1 if broken edges found |
| [`gpr-delete-package-version.ps1`](../scripts/gpr-delete-package-version.ps1) | Delete one package version by id+version (`-WhatIf` first) | 1 on API failure |
| [`find-build-line-floats.ps1`](../scripts/find-build-line-floats.ps1) | Scan `Directory.Packages.props` for `2026.1.N.*` floats | 1 if found |
| [`find-local-nuget-feeds.ps1`](../scripts/find-local-nuget-feeds.ps1) | Scan `nuget.config` for `novolis-local` / folder feeds | 1 if found |
| [`find-stale-package-ids.ps1`](../scripts/find-stale-package-ids.ps1) | Scan for renamed ids (`Host.NAudio`, `Live.Repl`, …) | 1 if found |
| [`fix-novolis-platform-floats.ps1`](../scripts/fix-novolis-platform-floats.ps1) | Rewrite build-line floats (and optional pins) to `2026.1.*` | 0 |
| [`verify-nuget-only.ps1`](../scripts/verify-nuget-only.ps1) | Cross-repo `ProjectReference` / sibling-src hacks in committed `.csproj` | 1 if found |
| [`verify-layer-boundaries.ps1`](../scripts/verify-layer-boundaries.ps1) | Avalonia isolation + Math→…→Avalonia upward `PackageReference` scan | 1 if found |
| [`verify-project-ref-mode.ps1`](../scripts/verify-project-ref-mode.ps1) | Package→project map + intersect-only MSBuild smoke | 1 if map/substitution wrong |
| [`set-org-nuget-packages-public.ps1`](../scripts/set-org-nuget-packages-public.ps1) | List package visibility (public via UI only) | 1 if any private |
| [`configure-gpr-user-nuget.ps1`](../scripts/configure-gpr-user-nuget.ps1) | Local restore credentials | 0 |

Shared helpers: [`scripts/lib/Gpr.ps1`](../scripts/lib/Gpr.ps1).

## What counts as junk

Real CI versions are **four** segments: `YEAR.MAJOR.MINOR.BUILD` (e.g. `2026.1.6.53`).

Junk (delete on sight):

- `1.0.0`
- `2026.1.99`, `2026.1.100`
- Three-segment `2026.1.N` with `N >= 90` (local/bootstrap stubs)

Under a platform float `2026.1.*`, `2026.1.99` sorts **above** `2026.1.10.36` and silently wins restore.

## Cleanup procedure

1. Inventory:

   ```powershell
   pwsh -File novolis-governance/scripts/gpr-find-junk-versions.ps1
   ```

2. Dry-run delete:

   ```powershell
   pwsh -File novolis-governance/scripts/gpr-remove-junk-versions.ps1 -WhatIf
   ```

3. Delete:

   ```powershell
   pwsh -File novolis-governance/scripts/gpr-remove-junk-versions.ps1
   ```

4. If a package **only** had junk versions, the package disappears from the feed. Republish from the owning repo:

   ```powershell
   gh workflow run Merge --repo Novolis-Platform/<repo>
   ```

5. If consumers baked the junk version into a nuspec dependency (exact `version="2026.1.99"`), republish that consumer package too after the real dependency exists.

6. Re-check:

   ```powershell
   pwsh -File novolis-governance/scripts/gpr-health-check.ps1
   ```

## Floating versions

| Pattern | OK? | Notes |
|---------|-----|-------|
| `2026.1.*` | Yes | Platform line — **only** allowed float |
| `2026.1.10.*` / `2026.1.1.*` | No | Build-line float; fails when that build was never published |
| Exact `2026.1.10.32` | Avoid | Prefer `2026.1.*`; pins hide publish races and rot |

Normalize checkout floats:

```powershell
pwsh -File novolis-governance/scripts/fix-novolis-platform-floats.ps1
pwsh -File novolis-governance/scripts/fix-novolis-platform-floats.ps1 -Apply
```

## Broken dependency versions (float poison)

A published package whose nuspec requires a **missing** Novolis dependency version
(e.g. `Live.Protocol 2026.1.10.36` → `LocalIpc 2026.1.10.36` never published) wins
`2026.1.*` restores and fails consumers.

```powershell
# Targeted
pwsh -File novolis-governance/scripts/gpr-find-broken-deps.ps1 -Package Novolis.Audio.Live.Protocol

# Org-wide (slow)
pwsh -File novolis-governance/scripts/gpr-find-broken-deps.ps1

# Delete the poison version, then republish
pwsh -File novolis-governance/scripts/gpr-delete-package-version.ps1 `
  -Package Novolis.Audio.Live.Protocol -Version 2026.1.10.36 -WhatIf
pwsh -File novolis-governance/scripts/gpr-delete-package-version.ps1 `
  -Package Novolis.Audio.Live.Protocol -Version 2026.1.10.36
gh workflow run Merge --repo Novolis-Platform/novolis-audio
```

Policy: [nuget-only-policy.md](nuget-only-policy.md). Publishing: [nuget-setup.md](nuget-setup.md).

## Org workflow permissions

Merge publish needs org default workflow permissions **`write`** (or explicit `packages: write` on the job). Check:

```powershell
gh api orgs/Novolis-Platform/actions/permissions/workflow
```
