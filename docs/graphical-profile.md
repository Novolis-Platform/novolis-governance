# Novolis Graphical Profile

The Novolis Graphical Profile is the required chrome contract for product UI.
It is authored once in
[`build/graphical-profile/profile.json`](../build/graphical-profile/profile.json)
and projected into the Avalonia and MAUI UI libraries.

## Source of truth

Merglyph is the visual source. The profile keeps its dark and light palette:

- navy canvas: `#080D1C` / `#F5F7FC`
- cyan identity and focus: `#2FDFFF`
- blue navigation and open: `#258BFF`
- purple commit action: `#914BFF`
- teal informational status: `#167C88`

Warning and danger roles are the only additions required for general product
surfaces. Product content may retain its own colors for maps, drawings,
documents, video, data visualization, and game-world entities.

The profile is a visual grammar, not a theme dump:

- one violet commit action per view; blue is for opening and navigation
- one compact trailing status or control in a header
- one vertical scroll owner
- eyebrow, title, one muted sentence, then the content
- monospace only for evidence, raw values, and diagnostics

The shared chrome uses Segoe UI, a 28px page title, 18px cards, 42px touch
targets, 44px icon controls, 8px control radius, 14px badge radius, 16px mark
radius, 18px card radius, 22px primary-action radius, and one-pixel
structural strokes. There are no shadows, blur, or gradients in the chrome.

## Consumer packages

Avalonia applications consume `Novolis.Avalonia.GraphicalProfile`.
MAUI applications consume `Novolis.Maui.GraphicalProfile`. The packages use
the same role names and values; they remain separate because MAUI and Avalonia
are isolated UI layers.

Avalonia applications call `GraphicalProfile.Install(this)` from their
`Application` initialization. The package supplies `Ngp.*` resources for
`ThemeVariant.Light` and `ThemeVariant.Dark`, plus class-based styles.

MAUI applications call `GraphicalProfile.Install(this)` from their
`Application` constructor. The package installs dynamic resources and updates
them when the requested application theme changes.

The package owns the shared shell only: brand lockup, page hierarchy, fields,
cards, navigation, status chips, and action buttons. Maps, drawings, documents,
video, game-world entities, and other domain surfaces remain product-owned.

## Binding rules

Use the profile for application backgrounds, surfaces, borders, text,
navigation, buttons, cards, fields, status chips, and validation copy.
Use the profile typography and geometry values for chrome.

Keep these values local to the product:

- drawing and sketch ink
- map tiles and map overlays
- game-world, firm, road, and faction colors
- remote video pixels
- document syntax highlighting

The governance verifier checks that UI projects reference the correct package.
It does not reject domain content colors.

## Platform and delivery map

The graphical profile enters at the UI edge of the closed platform spine:

`Math → Physics → Simulation → Gaming → Avalonia / MAUI → products`

Math, physics, simulation, and gaming remain headless and do not reference
Avalonia or MAUI. Avalonia and MAUI are separate UI islands; an executable
host chooses one. Product hosts, tools, utilities, and labs compose the
libraries at the edge.

The delivery surfaces follow the same separation:

- GitHub Packages carries continuous `2026.1.*` package builds.
- GitHub Releases carries installable products, Android bundles, and other
  deliberate artifacts.
- A GitHub Release promotes eligible packages to nuget.org.

## Updating the profile

Edit `profile.json`, run:

```powershell
pwsh -File d:\novolis\novolis-governance\scripts\Export-GraphicalProfile.ps1
pwsh -File d:\novolis\novolis-governance\scripts\verify-graphical-profile.ps1
```

The exporter updates the generated token source in both library repositories.
The verifier compares generated tokens with the JSON and checks the app
consumer package map.
