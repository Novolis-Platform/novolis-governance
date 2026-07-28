# GitHub Packages (GPR) maintenance

Operational runbook for keeping the Novolis org NuGet feed healthy. Floats (`2026.1.*`) only work when the feed has no throwaway versions and packages are linked to their publishing repos.

## Quick overview

```powershell
# Full health check (GPR + local checkout)
pwsh -File novolis-governance/scripts/gpr-health-check.ps1

# Inventory table (latest version, repo link, junk flags)
pwsh -File novolis-governance/scripts/gpr-package-overview.ps1
```

Requires `gh` authenticated with `read:packages` (delete needs `delete:packages` / org admin).

## Scripts

| Script | Purpose | Exit |
|--------|---------|------|
| [`gpr-health-check.ps1`](../scripts/gpr-health-check.ps1) | One-shot: overview + junk + build-line floats + nuget-only | 1 if any hard check fails |
| [`gpr-package-overview.ps1`](../scripts/gpr-package-overview.ps1) | Package inventory (latest, versions, linked repo, visibility) | 1 if unlinked or junk present |
| [`gpr-find-junk-versions.ps1`](../scripts/gpr-find-junk-versions.ps1) | List throwaway versions that poison `2026.1.*` | 1 if any found |
| [`gpr-remove-junk-versions.ps1`](../scripts/gpr-remove-junk-versions.ps1) | Delete junk versions (`-WhatIf` first) | 1 on API failure |
| [`find-build-line-floats.ps1`](../scripts/find-build-line-floats.ps1) | Scan `Directory.Packages.props` for `2026.1.N.*` floats | 1 if found |
| [`verify-nuget-only.ps1`](../scripts/verify-nuget-only.ps1) | Cross-repo `ProjectReference` / sibling-src hacks | 1 if found |
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
| `2026.1.*` | Yes | Platform line |
| `2026.1.10.*` / `2026.1.1.*` | No | Build-line float; fails when that build was never published |
| Exact `2026.1.10.32` | Yes | Use for cross-repo stacks that must match (e.g. Live + LocalIpc) |

Policy: [nuget-only-policy.md](nuget-only-policy.md). Publishing: [nuget-setup.md](nuget-setup.md).

## Org workflow permissions

Merge publish needs org default workflow permissions **`write`** (or explicit `packages: write` on the job). Check:

```powershell
gh api orgs/Novolis-Platform/actions/permissions/workflow
```
