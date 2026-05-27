# Novolis Architectural Ideals

Novolis architectural ideals are a set of principles that guide the design and architecture of Novolis projects.

1. Optimize for operational correctness, clarity, and maintainability over theoretical purity.
2. Patterns are tools, not requirements.
3. Every abstraction, layer, or component must justify itself through measurable value:
   security, policy enforcement, orchestration, reuse, operational safety, or clarity.
4. The database is the operational system of record and schema changes are intentionally high-friction.
5. Persistence entities express storage truth, not universal business meaning.
6. Business meaning is contextual and may be represented through internal projections, DTOs, or feature-local models.
7. Public transport contracts (.Models) are external service language only and must not leak into core logic.
8. DbContext is an acceptable dependency when it is the clearest and safest tool.
9. Thin wrappers over DbContext or DbSet<> that add no behavior or policy are architectural noise.
10. Repositories/services are justified only when they centralize meaningful behavior, policy, orchestration, or safety constraints.
11. Prefer explicit, atomic, idempotent database operations.
12. Preserve SaveChanges/interceptor behavior unless bypassing it is intentional and explicit.
13. Enforce critical invariants mechanically where possible:
    analyzers, query filters, interceptors, extension methods, integration tests.
14. Organize code primarily around features and use cases, not technical categories.
15. Vertical slices, services, repositories, direct EF usage, and mixed approaches may coexist when each serves a clear purpose.
16. Simple operations should remain simple. Complex workflows should have explicit behavioral boundaries.
17. The architecture is evaluated by operational outcomes and developer cognition, not by adherence to mandatory patterns.
