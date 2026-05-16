# Wave 2 extraction brief: novolis-transports

## Sources

| Frank repo | Novolis packages | Priority |
|------------|------------------|----------|
| [Frank.BedrockSlim](https://github.com/frankhaugen/Frank.BedrockSlim) | `Novolis.Transports.Tcp.Server`, `Novolis.Transports.Tcp.Client` | P0 |
| [Frank.Http](https://github.com/frankhaugen/Frank.Http) | `Novolis.Transports.Http`, `.Abstractions`, `.Authentication`, `.Extensions` | P0 |

## Depends on

- Bootstrap gate open
- **Wave 1** recommended (tests for Bedrock/Http migrations)

## BedrockSlim — in scope

- TCP server/client Bedrock processors
- `IConnectionProcessor` pattern
- Samples rewritten as `novolis-transports` samples

## BedrockSlim — out of scope

- `Frank.BedrockSlim.Cryptography` unless TLS story is defined

## Http — in scope

- `RestClient` / factory patterns from Frank.Http
- Authentication + extensions packages

## Http — gaps to fix on migration

- Add xUnit tests (Frank repo had weak Fact signal)
- Document vs `HttpClient` when to use Novolis wrapper

## Networking (deferred)

[Frank.Networking](https://github.com/frankhaugen/Frank.Networking) — **not in wave 2**; re-evaluate after TCP+HTTP ship (see [frank-p1-spikes.md](../frank-p1-spikes.md))

## Namespace map

| Frank | Novolis |
|-------|---------|
| `Frank.BedrockSlim.Server` | `Novolis.Transports.Tcp.Server` |
| `Frank.BedrockSlim.Client` | `Novolis.Transports.Tcp.Client` |
| `Frank.Http` | `Novolis.Transports.Http` |

## Release

`0.1.0-preview.*` per package

## Effort

**M–L** (Bedrock M + Http M)
