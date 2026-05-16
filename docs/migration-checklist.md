# Migration checklist

Use when moving code from legacy **Frank.\*** repositories into **Novolis-Platform** `novolis-*` repos.

Related: [frank-inventory.md](frank-inventory.md), [migration evaluation rubric](#evaluation-rubric), [bootstrap-gate-assessment.md](bootstrap-gate-assessment.md).

## Gate

Do **not** copy source until [bootstrap-gate-assessment.md](bootstrap-gate-assessment.md) records that NuGet trusted publishing is validated.

## Evaluation rubric

Score each source repo **0–5** on:

| Dimension | Question |
|-----------|----------|
| Strategic fit | Advances Novolis (modular .NET infra, realtime, graphics adjacency)? |
| Differentiation | Better than BCL + mainstream packages alone? |
| Maturity | Tests, CI, releases, docs, clear API? |

**Bands** (sum of the three scores, max 15):

| Band | Score | Action |
|------|-------|--------|
| P0 Bring | 12–15 | Schedule extraction; define packages |
| P1 Evaluate | 8–11 | Spike; re-score |
| P2 Reference | 4–7 | Mine ideas only; README pointer |
| P3 Skip | 0–3 | Do not migrate |

**Extraction modes:** Extract | Merge | Rebuild | Archive

## Per-repo migration steps

1. Identify old source repo (link in target `novolis-*` issue).
2. Decide **extract** vs **rebuild** vs **archive** (see [frank-inventory.md](frank-inventory.md)).
3. Create tracking issue on target repo (`status:bootstrap` → `status:active`).
4. Copy only useful source (no wholesale dump).
5. Normalize namespace to `Novolis.*` and package ID per [naming.md](naming.md).
6. Update README; add tests and package metadata per [package-policy.md](package-policy.md).
7. Add `.novolis/packages.json` per repo template.
8. Run CI; create preview release; validate NuGet package.
9. Archive or redirect old repo; add migration banner in old README.

## History rule

**Do not transfer old repository history by default.** Prefer clean curated repos unless history is legally or technically important.

## Frank-specific

- Resolve **Frank→Frank** dependencies before wave order (see [frank-inventory.md](frank-inventory.md) dependency graph).
- Replace `Frank.Testing.*` package references with `Novolis.Testing.*` as `novolis-testing` lands (Wave 1).
- Do not migrate `Frank.GameEngine.Rendering.*` while `Novolis.Raylib` is the graphics path — see [gameengine-reference-policy.md](gameengine-reference-policy.md).
