# Gaming layer policy

Operational summary for `novolis-gaming`. **Stack boundaries:** [library-boundaries.md](library-boundaries.md).

## Purpose

`novolis-gaming` ships **game authoring and shipping** libraries: pseudonymous identity, menu navigation, multiplayer lobby glue, procedural content tools, Inno Setup helpers. It is **not** the Math / Physics / Simulation / Rendering / Raylib stack.

Live **agent surfaces** (HTTP/SSE/WebSocket/LocalIpc control) live in **`novolis-agent`** (`Novolis.Agent.Core` / `Novolis.Agent.Surface`) — not here.

## Repo map

| Repo | Role |
|------|------|
| **novolis-gaming** | `Novolis.Game.*` authoring packages |
| **novolis-commands** | Intent/command tooling (parse → envelope → queue) |
| **novolis-agent** | Agent Surface (Novolis.Agent.Core / .Surface / .Testing) |
| **novolis-install** | Platform `novolis` global tool (GPR package install) |
| **novolis-templates** | `dotnet new` scaffolds (general + MonoGame) |
| **novolis-workflows** | Shared GitHub Actions workflows for org CI/CD (not product libraries) |
| **novolis-dogfooding** | Integration samples (PackageReference only) |

## Allowed in `novolis-gaming`

- ASP.NET Core + SignalR in `Novolis.Game.Multiplayer.AspNetCore` only
- Procedural authoring (`Novolis.Game.Procedural`) — noise, infinite chunks/tracks, spawn tables; BCL only (feeds Simulation.Voxels height samplers at the **app** layer)
- Opaque refs (`PlayerRef`, `SessionRef`, `LobbyId`) — no email, legal name, or provider subject strings in public API
- Same-repo `ProjectReference` between `Novolis.Game.*` facets
- `PackageReference` to `Novolis.Testing.*`, and third-party NuGet (Identity/Multiplayer as needed)

## Forbidden in `novolis-gaming`

- Live agent surface hosts / `agent.*` wire (`novolis-agent`)
- `Novolis.Simulation.*`, `Novolis.Raylib.*`, `Novolis.Rendering.*` package references
- Character cameras, PA-style tile grids, voxel worlds/meshing — use `Novolis.Simulation.View` / `.Tiles` / `.Voxels` (+ `.Meshing`) instead
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

## Application core and player intent

`IGameApplication`-shaped Start/Tick/Save/Load and game domain rules stay in **apps**, not in `Novolis.Game.*`. A future BCL-only `Novolis.Game.Intent` (player command envelopes) is deferred until multiple apps share a shape — see [hexgame-authoritative-core.md](architectural-ideals/hexgame-authoritative-core.md).

## Related

- [novolis-gaming design](https://github.com/Novolis-Platform/novolis-gaming/blob/main/docs/design.md)
- [hexgame-authoritative-core.md](architectural-ideals/hexgame-authoritative-core.md) — HexGame-aligned composition; no GameKit / no HexGame NuGet
- [nuget-only-policy.md](nuget-only-policy.md)

`novolis-workflows` is the org's **reusable GitHub Actions** repo. Backend WorkflowEngine (Cron / Mapping / Messaging) imports target a future **`novolis-workflow-engine`** package repo — do not conflate the two.

