# Wave 4 — Security

**Target repo:** [novolis-security](https://github.com/Novolis-Platform/novolis-security)  
**Naming:** [frank-naming-and-structure.md](../frank-naming-and-structure.md)

## Scope (in)

| Frank | Novolis |
|-------|---------|
| `Frank.Security.Cryptography` | `Novolis.Security.Cryptography` |
| `Frank.Security.HaveIBeenPwned` | `Novolis.Security.HaveIBeenPwned` |
| Tests | Per-facet under `tests/` |

## Out of scope

- `Frank.Security.Resources` unless a product needs embedded assets

## Dependencies

- `Novolis.Testing.*` for tests (wave 1)
- No `Frank.*` in production code

## Done when

- Both packages on `net10.0`, CI green
- Registry entries
- Frank.Security README banner
