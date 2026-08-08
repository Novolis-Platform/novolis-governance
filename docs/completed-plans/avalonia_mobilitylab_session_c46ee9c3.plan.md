---
name: Avalonia MobilityLab session
overview: Add an Avalonia dogfood app MobilityLab that runs a controlled tax–mobility experiment on the Civics/Economy/Geopolitics kernels, with a readable scientific session (hypothesis, parameters, series, map, PASS/FAIL scorecard)—not a Spectre console clone.
todos:
  - id: scaffold
    content: Scaffold MobilityLab Avalonia app (csproj, Program/App/MainWindow, CPM pins, slnx + READMEs)
    status: completed
  - id: experiment-core
    content: Implement TaxMobilityWorld/Month/ExperimentResult with PASS/FAIL coupling checks
    status: completed
  - id: session-ui
    content: "Build scientific session UI: hypothesis, params, series canvas, map, Briefing scorecard"
    status: completed
  - id: headless-docs
    content: Add --headless evidence output + README abstract/identification; verify build/run
    status: completed
isProject: false
---

# Avalonia MobilityLab (tax–mobility session)

## Academic framing (locked)

**Research question:** Holding geography and initial stocks fixed, does raising polity Alpha’s household tax above the Economy tax-push / Civics emigration thresholds cause (1) net population outflow, (2) higher emigration pressure, and (3) weaker legitimacy vs a low-tax twin Beta, with Gamma as a low-tax destination?

**Design:** twin / treatment–control month loop (not free-play theatre). One optional “war shock” toggle exists as a confounder switch, off by default so the primary claim stays identifiable.

## Placement and stack

New app: [`d:\novolis\novolis-dogfooding\apps\avalonia\MobilityLab\`](d:\novolis\novolis-dogfooding\apps\avalonia\MobilityLab\)

- Template: MovieMakerLab-style `Program` / `App` / `MainWindow` (Fluent, **no** `Avalonia.Fonts.Inter`).
- Visual language: navy/teal + copper amber (scientific session, not purple SaaS / cream terracotta). Brand hero: **MobilityLab** as first-viewport title.
- Packages: Avalonia 12 + Desktop + Fluent + DataGrid; `Novolis.Avalonia.Briefing` (scorecard / metric table / feed); triad kernels matching PolityTriad (`Civics.*`, `Economy.Core`, `Geopolitics.Core|Diplomacy|Trade|Conflict`, `Civics.EconomyBridge`, `Civics.Agents`).
- Add missing CPM pins in [`Directory.Packages.props`](d:\novolis\novolis-dogfooding\Directory.Packages.props): `Novolis.Avalonia.Briefing` `2026.1.*` (and Agents/Conflict if not already present from PolityTriad).

Register in [`Novolis.Dogfooding.slnx`](d:\novolis\novolis-dogfooding\Novolis.Dogfooding.slnx) under `/avalonia/`, plus root README row and app README with absolute `dotnet run` + ProjectRef flag.

## Simulation core (app-local, rigorous)

Do **not** drag Spectre `PolityTriad` into the Avalonia project. Implement a focused experiment host:

| Type | Role |
|------|------|
| `TaxMobilityWorld` | Seed 3 polities / 6 provinces (α treatment, β control, γ haven); dual Economy ledgers; sync demography from owned pop |
| `TaxMobilityMonth` | Month order: agents → trade → Economy periods → Civics delivery → Gamma geo civic → `PopulationMigration` → optional conflict → sample |
| `MonthSample` / `ExperimentHistory` | Series: pop, net migration, emigration pressure, legitimacy, tax, prodVal, control |
| `ExperimentSpec` | Parameters: α tax, β tax, months, seed, warShockOn |
| `ExperimentResult` | End stocks + `CouplingCheck[]` with PASS/FAIL and human-readable claims |

Reuse kernel APIs already proven in PolityTriad / Wave 1 (`CivicEconomyBridge`, `PopulationMigration`, pop-weighted control, tax-push migrate). Formulas stay in kernels; the app only configures treatments and reports.

Default treatment: α tax `0.38`, β tax `0.14`, γ tax `0.12`, 36 months, seed 42.

## UI composition (understandable first viewport)

One composition, one job:

```mermaid
flowchart TB
  header [MobilityLab title plus hypothesis]
  params [Tax knobs Run Reset]
  body [Series plus province map]
  evidence [Briefing Scorecard and Feed]
  header --> params --> body --> evidence
```

1. **Hypothesis strip** — one sentence RQ + expected signs (α pop net &lt; 0, α pressure &gt; β, α L &lt; β L at horizon).
2. **Controls** — α/β tax sliders or numeric boxes, Months, Run / Step / Reset; war shock checkbox (off by default).
3. **Series panel** — lightweight Avalonia `Canvas` polylines for α/β population and emigration pressure (no new chart package); legend in mono only for Raw values if needed.
4. **Map strip** — province ownership + population labels (text/grid, readable).
5. **Evidence** — `ScorecardView` / `MetricTableView` / `FeedPanel` from Briefing for coupling checks and month log (escape any markup).

HardPause while editing params; Run advances on UI timer or blocking `Run(N)` then refresh.

## Docs / rigor

App README sections: Abstract, Identification strategy, Month loop, How to reproduce, Interpretation of PASS/FAIL. Link [`demography-coupling.md`](d:\novolis\novolis-civics\docs\demography-coupling.md).

## Verification

```powershell
dotnet build d:\novolis\novolis-dogfooding\apps\avalonia\MobilityLab\MobilityLab.csproj -p:NovolisUseProjectReferences=true
dotnet run --project d:\novolis\novolis-dogfooding\apps\avalonia\MobilityLab\MobilityLab.csproj -p:NovolisUseProjectReferences=true
```

Headless smoke path: `--headless 36` writes the same scorecard text to stdout (for CI/agents without a display).

