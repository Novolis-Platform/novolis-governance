# Bootstrap gate assessment

Assessment date: 2026-05-17. Used to gate **Frank.\* code extraction** per [bootstrapping-organization.md](https://github.com/Novolis-Platform/.github/blob/main/plans/bootstrapping-organization.md) §20.

## Verdict

| Activity | Allowed now? |
|----------|----------------|
| Frank inventory, scoring, extraction **planning** docs | Yes |
| Copying Frank source into `novolis-*` repos | **No** — blocked on NuGet trusted publishing validation |
| Preview releases on Novolis packages | **No** |

**Evaluation phase may proceed.** **Implementation extraction** starts only after the blocking items below are checked off.

## Completion criteria (from bootstrap plan §20)

| Criterion | Status | Evidence |
|-----------|--------|----------|
| Organization exists | Done | [Novolis-Platform](https://github.com/Novolis-Platform) |
| Governance repo exists | Done | `novolis-governance` |
| Template repo exists | Done | `novolis-template-dotnet` (CI + Release workflows active) |
| Workflow repo exists | Done | `novolis-workflows` |
| Installer repos exist | Done | `novolis-install`, `novolis-installer-inno` |
| Registry repo exists | Done | `novolis-registry` |
| Initial reserved repos exist | Done | `novolis-messaging`, `novolis-transports`, `novolis-storage`, `novolis-testing`, `novolis-security`, `novolis-raylib`, etc. |
| Branch rules configured | Partial | Not verified on all repos — track in roadmap |
| CI works on template repos | Done | `novolis-template-dotnet` workflows active |
| Smoke-test package builds | Done | `novolis-smoketest` CI success (2026-05-16) |
| NuGet trusted publishing validated | **Not done** | [roadmap.md](roadmap.md) open item |
| Registry PR flow validated | Unknown | Confirm manually before first package publish |
| No real library migration started | Done | Reserved repos remain scaffold-only |

## Blocking item for extraction

1. **NuGet trusted publishing validation** — complete smoketest publish path per [nuget-setup.md](nuget-setup.md), then mark roadmap item done.

## Non-blocking follow-ups

- Branch rulesets on all org repos
- Registry PR flow sign-off
- Document trusted publishing runbook in maintainer guide

## Sign-off

When NuGet trusted publishing is validated, update [roadmap.md](roadmap.md) and add a line here:

```text
Extraction gate opened: YYYY-MM-DD — trusted publishing validated on novolis-smoketest.
```
