# Import: `Frank.EntityFrameworkCore` → Novolis

**Source:** `D:\frankrepos\Frank.EntityFrameworkCore`

## What

| Package | Role |
|---------|------|
| `Frank.EntityFrameworkCore.Repositories` | Generic repository patterns over EF Core |
| `Frank.EntityFrameworkCore.Audit` | Audit trail / change tracking helpers |

Tests use `Frank.Testing.*` only.

## Why

- Data access patterns are **not** covered by `novolis-storage` (Json/Sqlite file/storage abstractions).
- Small, focused surface — good spike for a **`novolis-data`** or **`novolis-efcore`** lane.
- No dependency on game stack; safe orthogonal repo.

## How

### Target

**New repo (proposed):** `novolis-data` with facets:

- `Novolis.Data.EntityFrameworkCore`
- `Novolis.Data.EntityFrameworkCore.Audit`

### Port steps

1. Confirm EF Core version aligned with `net10.0` platform standard.
2. Bootstrap repo; port repositories; add TUnit + Testcontainers SQL if needed.
3. Strip `Frank.Testing` → `Novolis.Testing.*`.
4. Document when to use Storage vs EF packages.
5. Publish after testing wave stable on GPR.

### Priority

**P2** — no current dogfood blocker in `d:\novolis` stack.

## Acceptance

- Packages build with strict XML docs.
- frank-inventory gains data/EF row or defers with rationale.
