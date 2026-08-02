# Architectural ideals

| Ideal | Topic |
| --- | --- |
| [hexgame-authoritative-core.md](hexgame-authoritative-core.md) | HexGame-shaped game loops on Novolis (Tick in Simulation/apps; Physics as callee) |
| [workspace-snapshot-timeline.md](workspace-snapshot-timeline.md) | Editor workspaces, snapshots, and branchable timelines |
| [distributed-services-architectural-guideline.md](distributed-services-architectural-guideline.md) | Distributed services structure and conformance |

---

# Distributed Services Architectural Guideline

This guideline defines how Novolis **distributed services** are structured, bounded, and evolved. It applies to multi-project service repositories that expose APIs or workers, persist operational state, and communicate through typed clients and transport contracts.

**Assumptions:** Services run behind platform routing (proxy, ingress, or container host). Each service owns isolated data stores (which may be tables in a shared database); no service mutates another service’s persistence directly.

## Document map

| Section | Topic |
| --- | --- |
| [1. Introduction](distributed-services-architectural-guideline.md#1-introduction) | Purpose, scope, assumptions, non-goals |
| [2. Foundational principles](distributed-services-architectural-guideline.md#2-foundational-principles) | System of record, data ownership, semantics, contracts |
| [3. Service package structure](distributed-services-architectural-guideline.md#3-service-package-structure) | Assembly roles and responsibilities |
| [4. Dependency and boundary rules](distributed-services-architectural-guideline.md#4-dependency-and-boundary-rules) | In-repo and cross-repo references |
| [5. Data access and persistence](distributed-services-architectural-guideline.md#5-data-access-and-persistence) | EF Core usage, repositories, wrappers |
| [6. Mutation, consistency, and side effects](distributed-services-architectural-guideline.md#6-mutation-consistency-and-side-effects) | Writes, transactions, interceptors |
| [7. Query safety and policy enforcement](distributed-services-architectural-guideline.md#7-query-safety-and-policy-enforcement) | Mechanical enforcement, multi-tenancy |
| [8. Application structure](distributed-services-architectural-guideline.md#8-application-structure) | Models, use cases, vertical slices |
| [9. Evolution and modernization](distributed-services-architectural-guideline.md#9-evolution-and-modernization) | Incremental change without wholesale rewrites |
| [10. Conformance criteria](distributed-services-architectural-guideline.md#10-conformance-criteria) | How implementations are evaluated |
| [11. Inter-service integration](distributed-services-architectural-guideline.md#11-inter-service-integration) | Contracts, no shared persistence, async |
| [Appendix A](distributed-services-architectural-guideline.md#appendix-a-reference-implementations) | Template alignment status |

The normative specification is **[distributed-services-architectural-guideline.md](distributed-services-architectural-guideline.md)**.

## Summary principles

1. Optimize for operational correctness, clarity, and maintainability over theoretical purity.
2. Patterns are optional tools; every abstraction must deliver measurable value.
3. Each service owns isolated data stores; shared databases are allowed if write boundaries are clear.
4. Never mutate another service’s persistence—integrate via public contracts (`.Client` / API / agreed messaging).
5. Services assume platform routing; callers use capabilities, not hard-coded public URLs.
6. Persistence entities represent storage truth; business meaning is contextual and may be projected.
7. `.Models` packages are public transport contracts only and must not leak inward.
8. `DbContext` is permitted when it is the clearest, safest choice; see bulk-update rules in §6.2.
9. Thin wrappers over `DbContext` or `DbSet<>` that add no policy or behavior are prohibited.
10. Repositories and application services are justified when they centralize policy, orchestration, or safety.
11. Prefer explicit, atomic, idempotent database operations with intentional interceptor behavior.
12. Enforce critical invariants mechanically (analyzers, filters, interceptors, tests); apply tenant filters by default.
13. Organize code by feature and use case, not by technical category alone.
14. Mixed styles may coexist when each is purposeful; simple operations stay simple.
15. Cross-repo dependencies use published NuGet packages per nuget-only policy—not sibling `ProjectReference`.
16. Resilience playbooks (chaos, circuit breakers) are out of scope; client retry and idempotent writes are in scope.
17. Conformance is judged by operational outcomes and comprehension, not layer count.
