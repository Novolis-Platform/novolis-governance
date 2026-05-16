# Roadmap

## Bootstrap (current)

- [x] Organization and governance
- [x] Template, workflows, registry, installer scaffolding
- [x] Reserved domain repositories
- [ ] NuGet trusted publishing validation (smoke test)
- [ ] Branch rulesets on all repos

## Frank.\* migration (evaluation complete 2026-05-17)

Planning docs: [frank-inventory.md](frank-inventory.md), [bootstrap-gate-assessment.md](bootstrap-gate-assessment.md).

**Blocked on:** NuGet trusted publishing validation (same as bootstrap gate).

| Wave | Repo | Status |
|------|------|--------|
| Pilot | `novolis-messaging` — `Novolis.Messaging.Channels` | Brief ready |
| 0 | `novolis-messaging` — PulseFlow | Brief ready |
| 1 | `novolis-testing` | Brief ready |
| 2 | `novolis-transports` — Bedrock + Http | Brief ready |
| 3 | `novolis-storage` — Json/Sqlite subset | Inventory only |
| 4 | `novolis-security` | Inventory only |
| 5 | `novolis-analyzers` / `novolis-codegen` | P1 partial |
| — | `novolis-raylib` | Active; GameEngine reference-only |

## Next

- Open extraction gate (trusted NuGet publish on smoketest)
- Execute pilot: Channels → `novolis-messaging`
- Migrate or build libraries into reserved repos per waves
- Expand registry and `novolis` CLI
- Signing, SBOM, and provenance (post-v0)
