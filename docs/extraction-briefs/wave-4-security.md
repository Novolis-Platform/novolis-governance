# Wave 4 — Security

**Target repo:** [novolis-security](https://github.com/Novolis-Platform/novolis-security)  
**Naming:** [frank-naming-and-structure.md](../frank-naming-and-structure.md)

## Scope (in)

| Frank | Novolis |
|-------|---------|
| `Frank.Security.Cryptography` (generation) | `Novolis.Security.Secrets` |
| `Frank.Security.Cryptography` (hashing) | `Novolis.Security.PasswordHashing` |
| `Frank.Security.Cryptography` (string AES) | `Novolis.Security.Encryption` |
| `Frank.Security.HaveIBeenPwned` | `Novolis.Security.HaveIBeenPwned` |
| `Frank.Security.Resources` (word lists) | `Novolis.Security.WordLists` (internal, not packable) |
| Tests | `tests/Novolis.Security.Tests` |

## Out of scope

- Meta package `Novolis.Security` umbrella

## Dependencies

- `Novolis.Testing.*` for tests (wave 1)
- `Novolis.Security.Secrets` → `Novolis.Security.WordLists`
- No `Frank.*` in production code

## Done when

- All facets on `net10.0`, CI green
- Registry entries for packable facets
- Frank.Security README banner
