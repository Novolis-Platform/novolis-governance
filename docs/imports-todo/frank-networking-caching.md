# Import: `Frank.Networking` and `Frank.UmbrellaCache`

**Sources:** `D:\frankrepos\Frank.Networking`, `D:\frankrepos\Frank.UmbrellaCache`

## What

### Frank.Networking

- `Frank.Networking` — general networking utilities
- `Frank.Networking.Irc` — IRC client (separate solution)

Inventory: **P1 defer** — audit overlap with `Novolis.Transports.Tcp` / Http first.

### Frank.UmbrellaCache

- `Frank.UmbrellaCache.Abstractions`
- `Frank.UmbrellaCache` — distributed cache client
- Server uses `Frank.BedrockSlim.Server` → **`Novolis.Transports.Tcp.Server`** after wave 2

## Why

- Transports wave migrated Bedrock/Http but not umbrella cache or IRC.
- Cache layer is useful for multi-node dogfood **after** TCP transport packages publish to GPR.

## How

### Networking

1. Diff APIs vs `novolis-transports` — if duplicate, **skip** and document.
2. If unique (e.g. connection multiplexer), add facet `Novolis.Transports.Networking`.
3. **IRC:** skip unless product needs it ([frank-repos-explicit-skip.md](frank-repos-explicit-skip.md)).

### UmbrellaCache

1. Blocked on **Novolis.Transports.Tcp** GPR.
2. New repo `novolis-caching` or facet under transports.
3. Retarget Bedrock → Novolis TCP packages.

### Priority

**P3**

## Acceptance

- Written overlap report in transports repo `docs/` before port.
- No Frank.BedrockSlim package refs after migration.
