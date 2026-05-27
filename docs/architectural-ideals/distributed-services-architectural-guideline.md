# Distributed Services Architectural Guideline

**Status:** Normative  
**Applies to:** Novolis distributed services (API hosts, workers, and their supporting packages)  
**Placeholder:** `<Service>` denotes a domain or capability name (for example, `Invoicing`, `Identity`), consistent with [naming.md](../naming.md).

**Related policy:** [nuget-only-policy.md](../nuget-only-policy.md), [repository-policy.md](../repository-policy.md)

---

## 1. Introduction

### 1.1 Purpose

This guideline establishes a consistent architecture for Novolis distributed services: independently deployable components that own operational data, expose stable contracts to other services, and integrate through typed clients.

The architecture prioritizes:

- Clarity of intent and change safety
- Operational safety and auditability
- Maintainability and incremental modernization
- Developer throughput and low-friction evolution
- Stable production behavior

### 1.2 Scope

In scope:

- Package layout and dependency boundaries for a service (`Novolis.<Service>.*`)
- Persistence, transport contracts, and internal application structure
- Data access, mutation, and query-safety practices for EF Core–based services
- Cross-service boundaries (owned data stores, public contracts, typed clients)

**Assumptions:**

- Each service is deployed behind **platform routing** (reverse proxy, ingress, API gateway, or an equivalent container/platform host). Public URL topology and edge routing are platform concerns; services expose capabilities through hosts and `.Client` packages, not hard-coded caller URLs.
- A service owns one or more **isolated data stores** (a dedicated database, schema, or table set). Physical isolation is optional; **write authority** is not. Other services must not mutate persistence they do not own.

Out of scope:

- Client-only libraries, batch tools, and non-service packages (see [naming.md](../naming.md))
- Infrastructure provisioning, CI/CD, and detailed runtime platform configuration
- Edge patterns such as BFF composition, service mesh policy, and chaos or resilience drill playbooks (platform or operational docs)

### 1.3 Non-goals

This guideline does **not** mandate:

- Fixed layering or a single persistence access style
- Pattern adoption without demonstrated value
- Theoretical purity at the expense of operational reality
- Abstractions that exist only to satisfy structural conventions
- A dedicated physical database per service (shared servers and databases are allowed when ownership boundaries are clear)
- Specific resilience frameworks (circuit breakers, bulkheads, chaos testing). Client retry and idempotent writes are in scope; broader failure-mode engineering is intentionally left to platform and operations documentation.

Every layer, abstraction, or package must justify its cost through measurable benefit: security, policy enforcement, orchestration, reuse, operational safety, or clarity.

---

## 2. Foundational principles

### 2.1 The database is the operational system of record

The relational database holds durable operational truth **for that service’s owned stores**.

- Schema changes are intentionally high-friction and subject to operational governance (DBA/operations approval).
- The database is optimized for stability, auditability, operational reliability, reporting, repair tooling, and cross-system consistency.
- The schema is not required to model every business context directly; avoid forcing conceptual purity when it increases operational cost.

### 2.2 Owned data stores (logical isolation)

Each service owns the data stores for its operational state. Ownership may be expressed as:

- A dedicated database, or
- A dedicated schema or table set within a shared database

**Requirements:**

- Only the owning service’s `.Data` (and its hosts) may issue writes to that store.
- No service may read or write another service’s persistence directly (shared `DbContext`, cross-schema `UPDATE`, ad hoc SQL against foreign tables, or ORM navigation into another bounded context’s tables).
- Cross-service access uses the owning service’s **public contract** (`.Client` / API / agreed async integration), not shared-database coupling.

### 2.3 Persistence truth is not business meaning

Persistence entities express **storage truth**. Business meaning is **contextual**.

| Artifact | Role |
| --- | --- |
| `UserEntity` | Persistence representation |
| `ApprovalUser` | Approval-context projection |
| `UserProfile` | Profile-context projection |

A single persistence entity may project into multiple contextual models. This is expected and encouraged.

### 2.4 Transport models are not internal models

`Novolis.<Service>.Models` defines **public transport contracts** for cross-process communication. These contracts are stable, serializable, versionable, and transport-oriented.

They are not the internal vocabulary of business logic.

**Requirement:** `.Models` must not be referenced from core business logic or persistence layers.

Mapping between persistence, internal projections, and transport contracts belongs in the **host or core** at the boundary (for example, in feature handlers or API composition). Prefer explicit mapping over leaking `.Models` types inward.

### 2.5 Constraints over ceremony

Architecture rules must protect operational concerns, including:

- Tenant isolation and authorization
- Auditability and operational safety
- Idempotency and performance
- Deployment independence and schema governance

Rules that exist only to enforce structural patterns (for example, “never inject `DbContext` into controllers”) are insufficient unless they address a concrete risk.

**Preferred formulation:** “Tenant filtering must not be bypassed accidentally,” not blanket bans on legitimate tools.

---

## 3. Service package structure

A distributed service is expressed as a family of packages. The application core is the unsuffixed package `Novolis.<Service>`. Replace `<Service>` with the domain name.

### 3.1 `Novolis.<Service>` (core)

**Role:** Application core—feature slices, workflows, use cases, orchestration, contextual business models, mapping, and domain logic.

**Organization:** Prefer feature- and use-case–oriented folders:

```text
Features/Invoices/Approve/
Features/Users/Profile/
```

Avoid defaulting to technical buckets (`Services/`, `Repositories/`, `Helpers/`, `Managers/`) as the primary structure.

### 3.2 `Novolis.<Service>.Api` / `Novolis.<Service>.Worker`

**Role:** Composition roots and runtime hosts.

**Responsibilities:** HTTP or messaging endpoints, dependency injection, configuration, runtime orchestration, and background processing. Map between transport contracts and internal models at this boundary when not already done in core feature code.

### 3.3 `Novolis.<Service>.Models`

**Role:** Public transport contracts only.

**Requirement:** Must not reference other `Novolis.*` packages.

### 3.4 `Novolis.<Service>.Client`

**Role:** Typed internal SDK for consuming the service.

**Responsibilities:** Transport, authentication, serialization, endpoint ownership, retry policies, and consumer ergonomics. Callers depend on **capabilities**, not raw URLs.

### 3.5 `Novolis.<Service>.Data`

**Role:** Persistence infrastructure for **this service’s owned stores only**.

**Contains:** `DbContext`, EF Core configuration, persistence entities, query-oriented persistence logic, and database-facing models.

Persistence entities may be used within the service boundary. The `.Data` package may be operationally central.

### 3.6 `Novolis.<Service>.Data.Migrations`

**Role:** Migration history and design-time migration tooling only.

**Rationale:** Separated for build performance, incremental compilation, and operational isolation.

### 3.7 `Novolis.<Service>.Tests`

**Role:** Automated tests for the service.

### 3.8 `Novolis.<Service>.Tests.Benchmarks`

**Role:** Performance benchmarks and experimentation.

### 3.9 `Novolis.<Service>.Compliance` (optional)

**Role:** Capability-specific compliance, gating, or governance when independent testing, release ownership, or operational separation is beneficial.

---

## 4. Dependency and boundary rules

### 4.1 Within a service repository

| Package | May reference |
| --- | --- |
| `.Api` / `.Worker` | Core, `.Data`, `.Models` |
| `.Client` | `.Models` only |
| `.Models` | *(none — must not reference `Novolis.*`)* |
| Core | `.Data` *(must not reference `.Models`)* |
| `.Data` | *(must not reference `.Models`)* |
| `.Tests` | Core, `.Api`, `.Worker`, `.Client`, `.Data`, `.Models` as needed for testing |
| `.Tests.Benchmarks` | Same as `.Tests`, scoped to performance scenarios |
| `.Compliance` | Core, `.Models`, and other service packages required for compliance checks *(must not reference another service’s `.Data`)* |

### 4.2 Across service repositories

Per [nuget-only-policy.md](../nuget-only-policy.md):

- Cross-repo dependencies use **`PackageReference`** to published `Novolis.*` packages (typically another service’s `.Client` and indirectly `.Models`).
- **Prohibited:** `ProjectReference` into another service repository; referencing another service’s `.Data`; sharing a `DbContext` across services.

These boundaries preserve deployment independence, contract stability, and clear separation between transport, application, and persistence concerns.

---

## 5. Data access and persistence

### 5.1 Direct `DbContext` usage

`DbContext` is a permitted dependency in endpoints, use cases, feature handlers, services, and vertical slices when it is the clearest and safest approach—especially for simple, atomic operations.

```csharp
await db.Users
    .Where(x => x.Id == currentUser.UserId)
    .ExecuteUpdateAsync(...);
```

> **See also:** [§6.2](#62-savechanges-and-bulk-update-semantics) — `ExecuteUpdateAsync` bypasses interceptors; use only when that is intentional.

### 5.2 Prohibited thin wrappers

Wrappers over `DbContext` or `DbSet<>` that only forward calls add noise without policy, behavior, reuse, orchestration, or clarity.

**Prohibited pattern** (when intermediate layers add no value):

```text
Controller → Service → Repository → DbContext
```

| Acceptable | Not acceptable |
| --- | --- |
| `InvoiceRepository.GetForTenant(tenantId)` applies tenant filter, soft-delete, and authorization before returning `IQueryable` | `InvoiceRepository.GetAll()` returns `_db.Invoices` with no added policy |
| Feature handler injects `AppDbContext` for a single `ExecuteUpdateAsync` on one row | `GenericRepository<T>` with `GetById` / `Update` that only delegates to `_db.Set<T>()` |
| Application service coordinates invoice approval, payment client, and outbox in one workflow | `CompanyService` that only forwards `Create` / `Get` to `DbContext` with no rules |

### 5.3 Repository justification

Introduce a repository when it **centralizes policy**, such as:

- Tenant isolation and authorization
- Audit and soft-delete rules
- Financial or safety-critical invariants
- Cross-system consistency rules

A repository that merely wraps `DbSet<>` without encoding policy should not exist.

---

## 6. Mutation, consistency, and side effects

### 6.1 Atomic, intentional writes

Mutations should favor idempotency, atomicity, clarity, retry safety, and minimal side effects. Simple operations should complete within a single, obvious transaction boundary.

### 6.2 `SaveChanges` and bulk update semantics

`ExecuteUpdateAsync()` bypasses change tracking, `SaveChanges`, and `SaveChanges` interceptors.

**Requirement:** Use `ExecuteUpdateAsync` only when that bypass is intentional.

When interceptors, outbox emission, synchronization, or audit behavior must run, use tracked entity updates or an explicit, documented alternative.

### 6.3 Interceptors as operational infrastructure

`SaveChanges` interceptors are first-class mechanisms for operational concerns, including:

- Lookup synchronization
- Audit emission
- Transactional outbox creation
- Cross-service cache propagation

---

## 7. Query safety and policy enforcement

Critical invariants should be **mechanically enforceable** where practical:

- Extension methods and query filters
- Roslyn analyzers
- Integration tests
- Explicit bypass attributes (with review)

Example:

```csharp
query.ForTenant(tenantId);
```

Prefer enforceable safety over ceremonial layering.

### 7.1 Multi-tenancy baseline

When a service is multi-tenant:

- Tenant identity is established at the host boundary (claims, headers, or platform context) and passed explicitly into queries and commands.
- Reads and writes that touch tenant-scoped data apply a **tenant filter by default** (global query filter, `ForTenant` extension, or repository policy).
- Bypassing tenant filters requires an explicit, reviewed mechanism (for example, an attribute and analyzer) and must not be the default path.

---

## 8. Application structure

### 8.1 Internal projections and DTOs

Context-specific internal projections are encouraged. Not every type need be a persistence entity.

Examples: `ApprovalUser`, `InvoiceSummary`, `PaymentCandidate`, `UserProfile`.

Use internal DTOs when they improve clarity, performance, behavioral isolation, or comprehension.

### 8.2 Use cases and application services

Introduce named use cases, components, or application services when:

- Multiple operations must coordinate
- Business workflows span steps or systems
- Behavior warrants explicit ownership
- Complexity benefits from isolation

| Acceptable | Not acceptable |
| --- | --- |
| `ApproveInvoiceHandler` loads invoice, validates policy, calls payment `.Client`, writes outbox | `CompanyService` with `Get` / `Create` / `Update` that only mirrors `DbContext` calls |
| `SyncDirectoryUseCase` orchestrates paging, retries, and idempotent upserts across many rows | Service class added “for consistency” with one method used once |
| Feature-local handler uses `DbContext` directly for `MarkNotificationRead` | Handler that only calls `NotificationRepository.MarkRead` where the repository is a one-line forwarder |

### 8.3 Simplicity for trivial operations

Do not add orchestration layers for straightforward CRUD (for example, updating a display name, marking a notification read, toggling a flag). Direct `DbContext` usage is acceptable.

### 8.4 Vertical slices

Organize by **feature** rather than global technical category. Within a feature, choose the appropriate mechanism:

- Direct `DbContext`
- Application service or handler
- Policy repository
- Query object or component

Mixed approaches within one service are acceptable when each choice is deliberate.

---

## 9. Evolution and modernization

This architecture supports coexistence during migration:

- Traditional layered modules
- Vertical slices
- Direct EF Core usage
- Service-oriented workflows
- Policy-centric repositories
- Feature-local components

Teams should evolve services incrementally. Wholesale rewrites for ideological alignment are discouraged.

---

## 10. Conformance criteria

An implementation conforms when it demonstrates:

| Criterion | Description |
| --- | --- |
| Clarity of intent | Behavior is understandable without tracing unnecessary indirection |
| Operational correctness | Invariants, auditing, and side effects behave as required in production |
| Maintainability | Changes are localized and predictable |
| Policy enforcement | Security and tenant rules are enforced reliably |
| Change safety | Schema and contract evolution remain controlled |
| Data ownership | No cross-service direct persistence access; integration uses public contracts |

Conformance is **not** measured by the number of layers or the use of specific patterns.

---

## 11. Inter-service integration

### 11.1 Public contracts only

Consumers depend on `Novolis.<OtherService>.Client` (and its `.Models` types). Version and evolve `.Models` deliberately; breaking changes require coordinated releases per [release-policy.md](../release-policy.md).

### 11.2 No shared persistence

Integration patterns:

| Allowed | Prohibited |
| --- | --- |
| HTTP or messaging via `.Client` | Cross-service `JOIN` / `UPDATE` on foreign-owned tables |
| Read models or caches owned by the consumer | Consumer `DbContext` mapping another service’s entities |
| Transactional outbox owned by the publishing service | Dual-write to two services’ stores in one transaction without a defined pattern |

### 11.3 Async and consistency

When synchronous calls are insufficient, use the owning service’s outbox or messaging integration (see [§6.3](#63-interceptors-as-operational-infrastructure)). Eventual consistency and compensation logic belong in the owning or consuming service’s core, not in shared database triggers across ownership boundaries.

---

## Appendix A. Reference implementations

| Artifact | Status |
| --- | --- |
| `novolismicroservice` ([novolis-templates](../../../novolis-templates/)) | Reference scaffold: `Api`, core, `.Models`, `.Client`, `.Data`, `.Data.Migrations`, `.Tests` (TUnit). |
| CI enforcement | Package boundaries are not yet verified automatically; review PRs against [§4](#4-dependency-and-boundary-rules). |
