# Wave 1 extraction brief: novolis-testing

## Source

[frankhaugen/Frank.Testing](https://github.com/frankhaugen/Frank.Testing)

## Target packages

| Frank | Novolis |
|-------|---------|
| `Frank.Testing.TestOutputExtensions` | `Novolis.Testing.TUnit` |
| `Frank.Testing.Logging` | `Novolis.Testing.Logging` |
| `Frank.Testing.TestBases` | `Novolis.Testing.TestBases` |
| `Frank.Testing.Testcontainers` | `Novolis.Testing.Testcontainers` |
| `Frank.Testing.TestServer` | Evaluate — not always packable; include if published |

## Why wave 1

Many Frank repos reference `Frank.Testing.*` in tests. Unblocks cleaner migrations in waves 0b–4.

## Blockers

- `Frank.Reflection` / `Frank.Reflection.Dump` referenced by Testing — **decouple first migration**:
  - Option A: Ship TestOutput + Logging without Dump
  - Option B: Minimal copy of dump helpers into testing package (temporary)

## In scope

- TUnit `TestContext` JSON/C#/XML/table writers
- Test logging adapters
- Testcontainers helpers (if still current on net10)

## Out of scope

- TUnit rewrite remnants unless already on main
- Frank.Reflection.Dump as permanent dependency

## Test strategy

- Port existing tests; target ≥ Frank baseline
- Smoketest consumer in `novolis-smoketest` optional

## Release

`0.1.0-preview.*` per package or single meta-package decision per [package-policy.md](../package-policy.md)

## Effort

**M**
