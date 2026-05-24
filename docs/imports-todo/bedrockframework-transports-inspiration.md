# Bedrock Framework — transports inspiration (third-party)

> **Status (2026-05-25):** Tcp middleware slice **shipped** in `Novolis.Transports.Tcp.Abstractions` (`MemoryTcpTransport`, connection pipeline). Bedrock fork still **out of scope**; optional logging middleware only. Master plan: [platform-import-plan.md](../platform-import-plan.md).

**Source:** `D:\dotnetrepos\BedrockFramework` (David Fowler / [BedrockFramework](https://github.com/davidfowl/BedrockFramework))  
**Related mine:** `D:\frankrepos\Frank.BedrockSlim` → already **`novolis-transports`** (`Novolis.Transports.Tcp.*`)

## What

Upstream **Bedrock.Framework** provides transport-agnostic networking:

| Area | Examples in tree |
|------|------------------|
| Core | `ServerBuilder`, `ConnectionContext`, middleware pipeline |
| Transports | Sockets, in-memory |
| Protocols | `ProtocolReader`/`Writer`, WebSocket framing |
| Experimental | HTTP/1–2, named pipes, connection pooling, Hub-style messages |

**Frank.BedrockSlim** is a **thin ASP.NET Core host** over custom TCP + optional AES (`IConnectionHandler`), **not** a fork of Bedrock.Framework. Novolis already migrated BedrockSlim to `Novolis.Transports.Tcp.Server/Client/Cryptography`.

## Why (borrow ideas, not repo)

| Gap in Novolis Tcp today | Bedrock idea |
|--------------------------|--------------|
| Single handler per connection | Middleware chain (`LoggingConnectionMiddleware`, `ConnectionLimitMiddleware`) |
| Custom framing only | `Protocol` abstraction for length-prefixed / WebSocket frames |
| No in-memory test transport | `MemoryTransport` for deterministic integration tests |
| WireFish / HTTP experiments | Experimental HTTP/2 client patterns (compare with `novolis-transports` Http) |

**Duplicate verdict:** Do **not** add `Bedrock.Framework` as a platform dependency without ADR — overlaps ASP.NET Core Connections and increases coupling to net8-era Bedrock packages.

## How

### Phase 1 — Shipped (2026-05)

- **`Novolis.Transports.Tcp.Abstractions`:** `ITcpConnectionMiddleware`, `TcpConnectionPipeline`, `MemoryTcpTransport`
- **`TcpConnectionHandler`** composes middleware before `IConnectionHandler`
- Unit test: `TcpConnectionPipelineTests` (no sockets)

### Phase 1b — Optional next

1. Read `Bedrock.Framework/Protocols` for framing patterns if custom protocols are added.
2. Register logging/rate-limit middleware via `services.AddSingleton<ITcpConnectionMiddleware, …>()`.
3. In-memory **duplex** client/server pair (if tests need two-way sessions).

### Phase 2 — Optional NuGet spike

- Evaluate **`Bedrock.Framework`** NuGet for a **dogfooding spike only** (not platform package).
- If used: isolate in `novolis-dogfooding`, not in `Novolis.Transports.Tcp` production path.

### Skip

- Vendoring `D:\dotnetrepos\BedrockFramework` into Novolis.
- Replacing Frank.BedrockSlim/Novolis Tcp with Bedrock server builder wholesale.

## Acceptance

- Tcp transport tests can run without real sockets (memory channel).
- Any middleware API is Novolis-owned and documented in `novolis-transports/docs`.
