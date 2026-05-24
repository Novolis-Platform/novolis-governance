# `D:\frankrepos` — explicit skip list

Repos present locally that should **not** be imported into Novolis platform libraries without a new product decision.

| Repo | Reason |
|------|--------|
| **Frank.Wpf** | WPF stack off-brand; ~20 packages |
| **Frank.CrossPlatformWindow** | SDL2 windowing outside Raylib lane |
| **Frank.HttpDude** | App (`IsPackable=false`); depends on Frank.Http, PulseFlow, Wpf — dogfood only |
| **Frank.Brewery** | Hobby app; netstandard2.1 / stale EF |
| **Frank.Logbook** | Web app host, not libraries |
| **Frank.IRC** | Educational; overlaps Networking.Irc |
| **Frank.Apps** | Application collection + Maui |
| **Frank.Finance.Documents.Ubl** | Vertical finance domain |
| **Frank.TorrentClient** | Niche BitTorrent |
| **Frank.ServiceBusExplorer** | EtherRipple experiment |
| **Frank.XsdCodeGeneration** | Author dead-end; spike only |
| **Frank.Libraries** | Monolith; author disclaims production — decompose **on demand** only |
| **Frank.GameEngine.Rendering.*** (bulk) | `novolis-raylib` + `novolis-rendering` replace Raylib/RT/MonoGame adapters |
| **Frank.GameEngine.Physics** | `novolis-physics` supersedes |
| **Frank.GameEngine.Primitives** (3D math) | `novolis-math` migrated |

## What to do instead

- **HttpDude / Apps:** keep in `D:\frankrepos` or `novolis-dogfooding` as private apps referencing **published** Novolis packages.
- **Wpf / CrossPlatformWindow:** archive reference unless Avalonia/desktop lane expands.
- **Libraries monolith:** import **single package** when a Novolis repo needs it (e.g. Csv for ML Legacy) — never bulk migrate.

## Revisit triggers

| Repo | Revisit when |
|------|----------------|
| Frank.Libraries | A dogfood app needs one specific package with Novolis naming |
| Frank.XsdCodeGeneration | Finance/codegen lane needs XSD |
| Frank.Networking.Irc | Chat product on platform |
| Frank.TorrentClient | Distribution tooling required |
