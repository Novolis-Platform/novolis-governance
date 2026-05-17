# Roadmap

## Bootstrap (done)

- [x] Organization and governance
- [x] Template, workflows, registry, installer scaffolding
- [x] Reserved domain repositories
- [x] .NET 10 standard (2026-05-17)
- [ ] NuGet trusted publishing on smoketest (org bootstrap / template only)
- [ ] Branch rulesets on all repos

## Frank.* migration (execution started 2026-05-17)

Docs: [frank-inventory.md](frank-inventory.md), [frank-naming-and-structure.md](frank-naming-and-structure.md), [frank-migration-runbook.md](frank-migration-runbook.md), [bootstrap-gate-assessment.md](bootstrap-gate-assessment.md).

**Migration publish gate:** first package `Novolis.Messaging.Channels` `0.1.0-preview.1` from `novolis-messaging` (not smoketest). See [nuget-setup.md](nuget-setup.md#migration-gate-novolis-messaging).

| Wave | Repo | Status |
|------|------|--------|
| Pilot | `novolis-messaging` — `Novolis.Messaging.Channels` | **Code migrated** — pending NuGet publish |
| 0b | `novolis-messaging` — `Novolis.Messaging` (PulseFlow) | **Code migrated** |
| 1 | `novolis-testing` — `Novolis.Testing.*` | **Code migrated** |
| 2 | `novolis-transports` — Tcp + Http | **Code migrated** (Http TUnit tests excluded from slnx until CI adapter) |
| 3 | `novolis-storage` — Abstractions/Json/Sqlite | **Code migrated** |
| 4 | `novolis-security` — Cryptography/HIBP | **Code migrated** |
| 5 | `novolis-analyzers` / `novolis-codegen` | P1 partial |
| — | `novolis-raylib` | Active; GameEngine reference-only |

## Next

- Configure NuGet trusted publishing for `novolis-messaging`; ship `0.1.0-preview.1`
- Frank README banners per [frank-sunset-banners.md](frank-sunset-banners.md); archive Frank P0 repos
- Expand registry entries as packages publish
- Signing, SBOM, and provenance (post-v0)
