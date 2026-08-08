---
name: MobilityLab science battery
overview: "Extend MobilityLab from a single treated/CF contrast into a reproducible science battery: tax shock with baseline window, dose–response grid, high-tax placebo twin, multi-seed ensemble, and economy/fiscal estimands—still app-local on Wave 1 kernels."
todos:
  - id: study-spec
    content: Add StudySpec, ArmKind, tax schedule/shock fields; BatteryRunner executing primary/CF/placebo/dose/seeds
    status: completed
  - id: estimands
    content: "Extend ScientificEvaluator: event-study, fiscal/prod ATT, placebo + dose + ensemble aggregates and study-level checks"
    status: completed
  - id: report-ui
    content: BatteryMarkdownReport + MainWindow Battery mode (dose chart, shock marker, study scorecard); headless --headless / --single
    status: completed
  - id: docs-verify
    content: README study design; build + headless 48 smoke for dose/placebo/ensemble signs
    status: completed
isProject: false
---

# MobilityLab science battery

## Problem

Today’s session answers one binary question well (ATT of α tax 0.38 vs CF). That confirms a kernel coupling; it does not explore a **policy surface**, test **symmetry**, separate **levels vs shocks**, or report **economy/fiscal** consequences. PASS/FAIL stays easy because the model is built to pass.

## Design goal (locked)

Keep formulas in Civics/Economy/Geopolitics. MobilityLab becomes a **design + estimation harness**: multiple worlds per study, shared evaluators, comparative markdown. No kernel Wave 2 (unrest/HD/productivity) in this tranche—document those as later.

```mermaid
flowchart TB
  study [StudySpec]
  battery [BatteryRunner]
  worlds [World runs: baseline shock dose placebo seeds]
  eval [ScientificEvaluator per world]
  aggregate [BatteryReport ATT curves placebo ensemble]
  study --> battery --> worlds --> eval --> aggregate
```

## Core abstractions (new)

Under [`d:\novolis\novolis-dogfooding\apps\avalonia\MobilityLab\Experiment\`](d:\novolis\novolis-dogfooding\apps\avalonia\MobilityLab\Experiment\):

| Type | Role |
|------|------|
| `StudySpec` | Horizon, seeds `[42,43,44]`, β/γ tax, burn-in, baseline months, shock month, dose grid, flags |
| `ArmKind` | `Primary`, `Counterfactual`, `PlaceboHigh`, `Dose(tau)`, `Shock` |
| `ArmResult` | Spec + `ExperimentResult` + arm tag |
| `BatteryResult` | All arms + aggregate tables (dose curve, ensemble means/ranges, placebo Δ) |
| `BatteryRunner` | Executes arms; reuses `TaxMobilityWorld` / `TaxMobilityMonth` |

Extend [`ExperimentSpec`](d:\novolis\novolis-dogfooding\apps\avalonia\MobilityLab\Experiment\ExperimentSpec.cs):

- `BaselineMonths`, `ShockMonth` (0 = static treatment from t0; default shock at month 12 after baseline at β tax)
- `AlphaTaxSchedule` resolved by host each month (baseline → treatment), still **locked** after optional agents
- Keep existing static mode as `ShockMonth = 0` with constant α tax for back-compat

## Arm battery (always run on Study Run)

1. **Primary** — α = treatment tax (static or post-shock); β/γ low; war/agents off  
2. **Counterfactual** — α = β tax (existing ATT baseline)  
3. **Placebo high twin** — α = β = treatment tax; γ unchanged. Tests whether “twin” is real or only Gamma gravity: expect **both** α and β to lose; DID ≈ 0; Gamma absorb still high  
4. **Dose grid** — α ∈ `{0.22, 0.28, 0.32, 0.38, 0.45}` (straddle Economy tax-push ~0.28); each with CF at β tax; plot ATT pop % and ATT mean push vs tax  
5. **Seed ensemble** — primary+CF for seeds `{42,43,44}`; report mean/min/max ATT pop % (robustness, not inference)

Default study: 48 months, baseline 12, shock at 12, primary α 0.38, grid as above, 3 seeds. Fast enough for session + headless.

## Estimands (extend `EffectSizes` / evaluator)

Reuse [`ScientificEvaluator`](d:\novolis\novolis-dogfooding\apps\avalonia\MobilityLab\Experiment\ScientificEvaluator.cs); add:

- **Shock event-study (primary arm):** mean α net mig / push / approval in `[1, baseline]` vs `[shock, shock+12]`; pre-trend check (α−β pop growth near 0 pre-shock)  
- **Economy/fiscal ATT** (fields already on `PolityFacts`): ATT on cumulative `TaxCollected`, mean `ProductionValue`, end `StateCash` — so the report is not migration-only  
- **Placebo diagnostics:** `|DID| < ε` under placebo high; fail identification-style check if placebo DID mimics primary  
- **Dose summary:** tax at which ATT pop % first crosses −5% and −20%; monotonicity flag (Spearman ATT vs tax)

Coupling checks become **study-level** (not only single-arm 6/6):

| Check | Pass when |
|-------|-----------|
| identification | war/agents off; tax lock; twin balance |
| ATT primary | ATT pop % &lt; −2% |
| pre-trend | pre-shock \|DID growth\| small |
| dose responds | higher tax → more negative ATT (monotonic or weakly) |
| placebo symmetry | placebo \|DID\| ≪ primary \|DID\| |
| fiscal tradeoff | ATT tax revenue vs ATT pop (report; soft PASS if revenue↑ while pop↓) |
| ensemble sign | all seeds same ATT sign |

## UI / report

[`MainWindow.cs`](d:\novolis\novolis-dogfooding\apps\avalonia\MobilityLab\MainWindow.cs):

- Mode toggle: **Single** (current) vs **Battery** (default for Run)  
- Battery controls: months, baseline/shock, dose grid on/off, seeds, placebo on/off  
- Charts: (1) primary pop series with shock marker; (2) dose curve ATT pop % vs α tax; (3) ensemble ATT range  
- Scorecard = study-level checks; metrics panel = primary ATT + placebo DID + dose threshold  

[`MarkdownReport.cs`](d:\novolis\novolis-dogfooding\apps\avalonia\MobilityLab\Experiment\MarkdownReport.cs) → `BatteryMarkdownReport`:

- Spec + identification  
- Primary ATT/DID + event-study table  
- Dose–response table  
- Placebo table  
- Ensemble table  
- Economy/fiscal ATT  
- Series snapshot (primary only)  

Headless: `--headless 48` runs battery; `--single` keeps old one-arm path.

## Docs

Update [`README.md`](d:\novolis\novolis-dogfooding\apps\avalonia\MobilityLab\README.md): study design, arm definitions, how to read dose/placebo/ensemble, link demography-coupling. Explicitly: kernel Wave 2 (unrest/HD) remains out of scope.

## Verification

```powershell
dotnet build d:\novolis\novolis-dogfooding\apps\avalonia\MobilityLab\MobilityLab.csproj -p:NovolisUseProjectReferences=true
dotnet run --project d:\novolis\novolis-dogfooding\apps\avalonia\MobilityLab\MobilityLab.csproj -p:NovolisUseProjectReferences=true -- --headless 48
```

Expect: primary ATT negative; dose curve more negative at higher tax; placebo DID near zero relative to primary; ensemble same sign; pre-trend check PASS with shock design.

