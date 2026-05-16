# P0 deep-dive (Frank.\* → Novolis)

Validated against shallow clones at SDK **10.0.203**, branch `main` (Frank.Libraries uses `master` — not cloned).

## Frank.Channels.DependencyInjection

| Field | Value |
|-------|-------|
| Packable | `Frank.Channels.DependencyInjection` |
| Tests | 2 `[Fact]` |
| Latest release | 2.2 |
| External Frank deps | None in library (tests use `Frank.Testing.TestBases`) |
| API surface | `AddChannel<T>()`, resolves `Channel<T>`, `ChannelReader<T>`, `ChannelWriter<T>` |
| Blockers | None |
| Novolis slice | Full single package → `Novolis.Messaging.Channels` |
| Effort | **S** |

## Frank.PulseFlow

| Field | Value |
|-------|-------|
| Packable | `Frank.PulseFlow` |
| Tests | 8 `[Fact]` |
| Latest release | 3.0 |
| Frank deps | `Frank.Channels.DependencyInjection`, `Frank.Reflection`, `Frank.Testing.TestBases` |
| Docs | `docs/` tree, AGENTS.md, STYLE.md |
| Blockers | Remove/replace Reflection dependency during migration (inline or `Novolis.CodeGen` later) |
| Novolis slice | Core messaging + ported docs |
| Effort | **M** (after Channels + Testing) |

## Frank.BedrockSlim

| Field | Value |
|-------|-------|
| Packable | `Server`, `Client`, `Cryptography` |
| Tests | 1 `[Fact]` |
| Latest release | 1.1 |
| Samples | Client + Server sample projects |
| Blockers | Low test coverage — add TCP integration tests in Novolis |
| Novolis slice | Server + Client only → `Novolis.Transports.Tcp.*` |
| Effort | **M** |

## Frank.Testing

| Field | Value |
|-------|-------|
| Packable | `Logging`, `TestBases`, `Testcontainers`, `TestOutputExtensions` |
| Tests | Test project present; few Fact attributes in quick scan |
| Latest release | 2.0 |
| Frank deps | `Frank.Reflection`, `Frank.Reflection.Dump` |
| Blockers | Decouple Reflection for first Novolis cut (copy minimal helpers or delay Dump package) |
| Novolis slice | All four packages under `Novolis.Testing.*` |
| Effort | **M** — **Wave 1 priority** |

## Frank.DataStorage

| Field | Value |
|-------|-------|
| Packable | 10 backends + Abstractions + Core |
| Tests | 6 `[Fact]` |
| Latest release | 3.1 |
| Frank deps | `Frank.Reflection`, `Frank.Testing.TestBases` |
| Blockers | Large matrix — **first wave: Json + Sqlite + Abstractions only** |
| Novolis slice | See wave 3 issue |
| Effort | **L** (full), **M** (subset) |

## Frank.Http

| Field | Value |
|-------|-------|
| Packable | `Http`, `Abstractions`, `Authentication`, `Extensions` |
| Tests | 14 test files, 0 Fact in quick scan (investigate test framework) |
| Latest release | 1.1 |
| Frank deps | None |
| Blockers | Weak test signal — add xUnit tests on migration |
| Novolis slice | Full HTTP stack → `Novolis.Transports.Http.*` |
| Effort | **M** |

## Frank.Security

| Field | Value |
|-------|-------|
| Packable | `Cryptography`, `HaveIBeenPwned`, `Resources` |
| Tests | 8 `[Fact]` |
| Latest release | 0.2 |
| Frank deps | `Frank.Testing.*` (tests) |
| Blockers | Sparse README — document APIs during migration |
| Novolis slice | Cryptography + HIBP client (skip Resources unless required) |
| Effort | **S–M** |

## P0 re-scores (confirmed)

All seven remain **P0** (totals 11–15). No demotions.
