# Pilot extraction brief: Channels → novolis-messaging

**Status:** Ready for implementation after [bootstrap gate](../bootstrap-gate-assessment.md) opens.

## Source

- Repo: [frankhaugen/Frank.Channels.DependencyInjection](https://github.com/frankhaugen/Frank.Channels.DependencyInjection)
- Package: `Frank.Channels.DependencyInjection` (net10.0)

## Target

- Repo: [Novolis-Platform/novolis-messaging](https://github.com/Novolis-Platform/novolis-messaging)
- Package: `Novolis.Messaging.Channels`
- Namespace: `Novolis.Messaging.Channels`

## In scope

- `AddChannel<T>()` / `AddChannel<T>(Action<ChannelOptions>)` extensions
- DI registration for `Channel<T>`, `ChannelReader<T>`, `ChannelWriter<T>`
- Tests (rewrite from Frank tests; drop `Frank.Testing.TestBases` or use minimal local test helpers until Wave 1)

## Out of scope

- PulseFlow (wave 0b)
- Any transport or persistence

## Steps

1. Scaffold `novolis-messaging` from `novolis-template-dotnet` if not already done.
2. Copy implementation; rename namespaces and package ID.
3. Add `.novolis/packages.json` entry.
4. CI green; `0.1.0-preview.1` when gate open.
5. Update Frank repo README with migration pointer.

## API breaking changes

| Frank | Novolis |
|-------|---------|
| `Frank.Channels.DependencyInjection` | `Novolis.Messaging.Channels` |
| `using Frank.Channels.DependencyInjection` | `using Novolis.Messaging.Channels` |

## Success criteria

- `dotnet add package Novolis.Messaging.Channels` works from GitHub Packages / configured feed
- PulseFlow migration issue unblocked (depends on this package)

## Effort

**S** (1–2 days after gate open)
