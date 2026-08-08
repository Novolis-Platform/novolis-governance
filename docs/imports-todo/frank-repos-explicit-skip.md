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
| **Frank.TorrentClient** | Niche BitTorrent |
| **Frank.ServiceBusExplorer** | EtherRipple experiment |
| **Frank.Libraries** | Monolith; author disclaims production — decompose **on demand** only |

## Moved to `novolis-xsd` (no longer skip)

| Repo | Destination |
|------|-------------|
| **Frank.Finance.Documents.Ubl** | Ideas + tests / XSD tree → `Novolis.Xsd.*` (regenerate; do not vendor generated tree) |
| **Frank.XsdCodeGeneration** | Reference-only spike; generation spine is Frank.UblSharp → `Novolis.Xsd.Generator` |
| **Frank.UblSharp** | Primary absorb → `Novolis.Xsd.Generator`, `Novolis.Xsd.Ubl`, `Novolis.Xsd.Ubl.Validation` |
| **Frank.Libraries.Ubl** / **SBDH** | Cherry-pick / Peppol envelope → `Novolis.Xsd.Ubl`, `Novolis.Xsd.Peppol` |
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
| Frank.Libraries | A dogfood app needs one specific package with Novolis naming (UBL/SBDH already → `novolis-xsd`) |
| Frank.Networking.Irc | Chat product on platform |
| Frank.TorrentClient | Distribution tooling required |
