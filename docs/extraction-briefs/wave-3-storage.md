# Wave 3 — Storage subset

**Target repo:** [novolis-storage](https://github.com/Novolis-Platform/novolis-storage)  
**Naming:** [frank-naming-and-structure.md](../frank-naming-and-structure.md)

## Scope (in)

| Frank | Novolis |
|-------|---------|
| `Frank.DataStorage.Abstractions` | `Novolis.Storage.Abstractions` |
| `Frank.DataStorage.Json` | `Novolis.Storage.Json` |
| `Frank.DataStorage.Sqlite` | `Novolis.Storage.Sqlite` |
| Tests for Json + Sqlite only | `tests/Novolis.Storage.*.Tests` |

## Out of scope (defer)

- Meta `Frank.DataStorage`, `Core`, Csv, Xml, LiteDb, MongoDb, Realm, Benchmarks
- `Frank.Reflection` — remove package reference from Abstractions (unused in source)

## Dependencies

- `Novolis.Testing.TestBases` for tests (after wave 1)
- No `Frank.*` package references

## Done when

- Three packages build on `net10.0`
- Tests pass for Json + Sqlite
- Registry entries added
- Frank.DataStorage README banner (full repo archive deferred until all backends decided)
