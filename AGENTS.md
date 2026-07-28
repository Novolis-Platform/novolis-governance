# Novolis governance — agent contract

Portable agent instructions (ACS-aligned). Editor-specific rules may also exist under `.cursor/rules/`.

## Required reading

- [library-boundaries.md](docs/library-boundaries.md) — Math → Physics → Simulation; no `Vector3d`
- [nuget-only-policy.md](docs/nuget-only-policy.md) — cross-repo `PackageReference` only
- [platform-import-plan.md](docs/platform-import-plan.md) — canonical import execution order
- [imports-todo/README.md](docs/imports-todo/README.md) — detail appendices (not priority tables)

## Verification

```powershell
pwsh -File scripts/gpr-health-check.ps1
pwsh -File scripts/get-test-gap-report.ps1 -FailOnGaps:`$false
pwsh -File scripts/get-coverage-report.ps1 -ListRepos
pwsh -File scripts/verify-nuget-only.ps1
pwsh -File scripts/Verify-AcsRepo.ps1
```

GPR feed inventory and junk-version cleanup: [docs/gpr-maintenance.md](docs/gpr-maintenance.md).  
Coverage: [docs/coverage-report.md](docs/coverage-report.md).
