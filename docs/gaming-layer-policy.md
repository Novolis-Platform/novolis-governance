# Gaming layer policy

Operational summary for `novolis-gaming`. **Stack boundaries:** [library-boundaries.md](library-boundaries.md).

## Purpose

`novolis-gaming` ships **game authoring and shipping** libraries: pseudonymous identity, menu navigation, multiplayer lobby glue, player session protocol (`Novolis.Game.Session`), Inno Setup helpers. It is **not** the Math / Physics / Simulation / Rendering / Raylib stack.

## Repo map

| Repo | Role |
|------|------|
| **novolis-gaming** | `Novolis.Game.*` authoring packages |
| **novolis-install** | Platform `novolis` global tool (GPR package install) |
| **novolis-templates** | `dotnet new` scaffolds (general + MonoGame) |
| **novolis-workflows** | Backend workflow orchestration (Cron, Mapping, Messaging) |
| **novolis-dogfooding** | Integration samples (PackageReference only) |

## Allowed in `novolis-gaming`

- ASP.NET Core + SignalR in `Novolis.Game.Multiplayer.AspNetCore` only
- Player session protocol (`Novolis.Game.Session`) — session contracts, MessagePack wire, LocalIpc/stdio hosts; no game domain models
- Opaque refs (`PlayerRef`, `SessionRef`, `LobbyId`) — no email, legal name, or provider subject strings in public API
- Same-repo `ProjectReference` between `Novolis.Game.*` facets
- `PackageReference` to `Novolis.Transports.LocalIpc`, `Novolis.Testing.*`, and third-party NuGet

## Forbidden in `novolis-gaming`

- `Novolis.Simulation.*`, `Novolis.Raylib.*`, `Novolis.Rendering.*` package references
- Simulation ↔ Raylib wiring inside a single package
- Game domain models (factions, ships, SCR/GalacticSim rules)
- SignalR or game lobby code in `novolis-transports`
- PII persistence in platform packages

## PII split

| Concern | Owner |
|---------|--------|
| Opaque `PlayerRef`, in-memory display nicknames | `Novolis.Game.Identity.*` |
| Steam / email / GDPR / Identity Server | Product app |

Apps implement `IExternalIdentityLinker` and real auth; platform sees hashed external subjects only.

## Related

- [novolis-gaming design](https://github.com/Novolis-Platform/novolis-gaming/blob/main/docs/design.md)
- [nuget-only-policy.md](nuget-only-policy.md)
