# Wave 0 extraction brief: novolis-messaging

## Sources

| Order | Frank repo | Novolis packages |
|-------|------------|------------------|
| 0a | [Frank.Channels.DependencyInjection](https://github.com/frankhaugen/Frank.Channels.DependencyInjection) | `Novolis.Messaging.Channels` |
| 0b | [Frank.PulseFlow](https://github.com/frankhaugen/Frank.PulseFlow) | `Novolis.Messaging` |

## Depends on

- Bootstrap gate open
- Pilot complete ([pilot-channels.md](pilot-channels.md))
- Wave 1 optional for PulseFlow test helpers (`Frank.Testing`) — can use temporary test utilities

## In scope (0b)

- Core PulseFlow: Nexus, Conduit, Pulse, Flow abstractions
- DI extensions for in-process messaging
- Port `docs/` from PulseFlow (rebrand Novolis)

## Out of scope

- Distributed messaging / brokers
- Replacing `Frank.Reflection` — inline minimal helpers or stub until Wave 5

## Namespace map

| Frank | Novolis |
|-------|---------|
| `Frank.Channels.DependencyInjection` | `Novolis.Messaging.Channels` |
| `Frank.PulseFlow` | `Novolis.Messaging` |

## Test strategy

- Port PulseFlow tests (8 facts baseline)
- Add channel registration tests if not already in pilot

## Release

- `Novolis.Messaging.Channels` `0.1.0-preview.*`
- `Novolis.Messaging` `0.1.0-preview.*` after 0a stable

## Frank sunset

Archive banners on both Frank repos pointing to `novolis-messaging`.

## Effort

**M** (pilot S + PulseFlow M)
