# Agent Contracts Standard (ACS) — governance alignment

**Source:** `D:\repos\agent-contracts-standard` (and clone under `D:\github\agent-contracts-standard`)  
**Mine:** Yes (Frank) — **not** a runtime library import.

## What

[ACS v0.1](https://github.com/frankhaugen/agent-contracts-standard): vendor-neutral layout for agent contracts:

- Root `AGENTS.md`
- `.ai/index.md` + taxonomy (instructions, policies, skills, commands, context)
- `scripts/Verify-AcsRepo.ps1` compliance check
- Templates under `templates/`, examples `minimal` / `full`

## Why

- Novolis has `.cursor/rules` and `novolis-governance/docs` but **no** ACS-shaped `.ai/` tree or verify script.
- FleetCommander already uses `AGENTS.md` + Copilot instructions — ACS unifies Cursor/Copilot/CLI agents without vendor lock-in.
- Complements documentation rollout; does **not** replace [library-boundaries.md](../library-boundaries.md).

## How

### Phase 1 — Governance repo (no new NuGet)

1. Add `novolis-governance/AGENTS.md` pointing to boundaries, nuget-only policy, imports-todo index.
2. Add `novolis-governance/.ai/index.md` with links to key policies (subset of ACS **full** example).
3. Vendor or submodule **only** `scripts/Verify-AcsRepo.ps1` (MIT) — adapt paths for monorepo (scan `novolis-*` roots).

### Phase 2 — Per-repo rollout

| Repo type | Minimum |
|-----------|---------|
| Platform libs | `AGENTS.md` stub + link to governance |
| `novolis-dogfooding` | Full `.ai/` if actively agent-driven |

### Do not

- Copy entire ACS repo into every `novolis-*` package.
- Add required `.cursor/` paths (forbidden by ACS neutrality — keep Cursor config optional).

### Relationship to Cursor

- `.cursor/rules/*.mdc` can **coexist** as editor-specific; ACS `.ai/` is the portable contract.

## Acceptance

- `pwsh novolis-governance/scripts/Verify-AcsRepo.ps1` (adapted) passes on governance repo.
- Document in [documentation-policy.md](../documentation-policy.md) optional ACS compliance for new repos.
