# Novolis Architectural Guidance

## Purpose

This architecture exists to optimize for:

```text
clarity
operational safety
developer throughput
maintainability
incremental modernization
stable operations
low-friction change
```

This architecture explicitly rejects:

```text
pattern cargo culting
mandatory layering
theoretical purity over operational reality
abstractions without purpose
```

Patterns are tools, not requirements.

A layer, abstraction, or component must justify its existence through measurable value.

---

# Core Philosophy

## 1. The Database Is an Operational System of Record

The relational database is treated as durable operational truth.

Schema changes are intentionally high-friction and operationally governed.

Migrations are approved explicitly by DBA/OPS processes.

The database is optimized for:

```text
stability
auditability
operational reliability
reporting
repair tooling
cross-system consistency
```

The database is not required to model every business context directly.

Do not force conceptual purity into schema design when it increases operational complexity.

---

## 2. Persistence Truth Is Not Business Meaning

Persistence entities express storage truth.

Business meaning is contextual.

Example:

```text
UserEntity
  persistence representation

ApprovalUser
  approval-context business projection

UserProfile
  profile-context business projection
```

A single persistence entity may project into many contextual business models.

This is encouraged.

---

## 3. Transport Models Are Not Internal Models

`.Models` packages define public transport contracts.

These contracts are:

```text
stable
serializable
cross-process
versionable
transport-oriented
```

They are not internal business language.

`.Models` must not leak into core business logic or persistence layers.

---

## 4. Constraints Matter More Than Ceremony

Architecture rules must protect real operational concerns.

Valid concerns include:

```text
tenant isolation
authorization
auditability
operational safety
idempotency
performance
deployment independence
schema governance
```

Invalid concerns include:

```text
mandatory repositories
mandatory services
mandatory mapping layers
mandatory indirection
```

Bad rule:

```text
Never inject DbContext into controllers.
```

Good rule:

```text
Tenant filtering must not be bypassed accidentally.
```

---

# Assembly Taxonomy

## Novolis.X

Contains:

```text
feature slices
workflows
use cases
components
business orchestration
contextual business models
mapping
domain logic
```

Core code should primarily organize around features and use cases, not technical folders.

Prefer:

```text
Features/Invoices/Approve/
Features/Users/Profile/
```

Over:

```text
Services/
Repositories/
Helpers/
Managers/
```

---

## Novolis.X.Api / Novolis.X.Worker

Composition roots and runtime hosts.

Responsible for:

```text
routing
dependency injection
configuration
runtime orchestration
background processing
```

---

## Novolis.X.Models

Public transport contracts only.

Must not reference other Novolis packages.

---

## Novolis.X.Client

Typed internal SDKs.

Responsible for:

```text
transport
auth
serialization
endpoint ownership
retry policies
consumer ergonomics
```

Consumers should know capabilities, not URLs.

---

## Novolis.X.Data

Contains:

```text
DbContext
EF Core configuration
persistence entities
query persistence logic
database-oriented models
```

Persistence entities are intentionally usable internally.

`.Data` is allowed to be operationally central.

---

## Novolis.X.Data.Migrations

Migration history and design-time migration concerns only.

Separated primarily for:

```text
build performance
incremental compilation
operational isolation
```

---

## Novolis.X.Tests

Testing.

---

## Novolis.X.Test.Benchmarks

Benchmarks and performance experimentation.

---

## Novolis.X.Compliance

Optional capability-specific package.

Used when independent:

```text
testing
compliance gating
release ownership
operational governance
```

is beneficial.

---

# Dependency Rules

## Allowed Dependencies

`.Api/.Worker` may reference:

```text
Core
.Data
.Models
```

`.Client` may reference:

```text
.Models only
```

`.Models`:

```text
Must not reference Novolis.* packages
```

`Core`:

```text
Must not reference .Models
May reference .Data
```

`.Data`:

```text
Must not reference .Models
```

---

# Data Access Philosophy

## DbContext Is Allowed

`DbContext` is an acceptable dependency in:

```text
endpoints
use cases
feature handlers
services
vertical slices
```

when it is the clearest and safest tool.

This is especially encouraged for simple atomic operations.

Example:

```csharp
await db.Users
    .Where(x => x.Id == currentUser.UserId)
    .ExecuteUpdateAsync(...);
```

---

## Thin Wrappers Are Forbidden

Wrappers over `DbContext` or `DbSet<>` that merely forward calls are considered architectural noise.

Forbidden:

```text
Controller -> Service -> Repository -> DbContext
```

when no layer adds:

```text
policy
behavior
reuse
orchestration
clarity
```

---

## Repositories Must Encode Policy

Repositories are justified only when they centralize meaningful rules such as:

```text
tenant isolation
authorization
audit rules
soft-delete handling
financial safety rules
cross-system consistency
```

---

# Mutation Rules

## Prefer Atomic Operations

Writes should favor:

```text
idempotency
atomicity
clarity
retry safety
minimal side effects
```

Simple operations should complete in one obvious database transaction boundary.

---

## SaveChanges Behavior Matters

`ExecuteUpdateAsync()` bypasses:

```text
change tracking
SaveChanges
SaveChanges interceptors
```

Therefore:

```text
Use ExecuteUpdateAsync only when bypass behavior is intentional.
```

If interceptors, outbox behavior, synchronization, or audit behavior matters:

```text
use tracked entity updates
or explicit wrappers
```

---

## SaveChanges Interceptors Are First-Class Architecture

SaveChanges interceptors are acceptable for operational synchronization concerns such as:

```text
lookup synchronization
audit emission
event outbox creation
cross-service cache propagation
```

These are considered legitimate operational architecture.

---

# Query Safety

## Policy Enforcement Should Be Mechanical

Prefer enforcing invariants through:

```text
extension methods
query filters
Roslyn analyzers
integration tests
explicit bypass attributes
```

Example:

```csharp
query.ForTenant(tenantId)
```

Architecture should prefer enforceable safety over ceremonial layering.

---

# Internal Models and DTOs

Contextual internal projections are encouraged.

Not every internal type should be a persistence entity.

Examples:

```text
ApprovalUser
InvoiceSummary
PaymentCandidate
UserProfile
```

Internal DTOs are acceptable when they improve:

```text
clarity
performance
behavioral isolation
cognitive understanding
```

---

# Use Cases and Services

## Named Behavioral Boundaries

Use explicit services/components/use cases when:

```text
multiple operations coordinate
business workflows exist
side effects span systems
behavior deserves ownership
complexity needs isolation
```

---

## Simple Operations Should Stay Simple

Do not introduce orchestration layers for trivial CRUD.

Example:

```text
change display name
mark notification as read
toggle flag
```

may directly use DbContext.

---

# Vertical Slice Philosophy

Vertical slices are encouraged.

Feature-local implementation is preferred over global technical categorization.

A feature may internally choose:

```text
direct DbContext
service
repository
handler
component
query object
```

as appropriate.

The architecture supports mixed approaches simultaneously.

---

# Incremental Modernization

This architecture intentionally supports coexistence between:

```text
traditional layered systems
vertical slices
direct EF usage
service-oriented logic
policy repositories
feature-local components
```

The goal is evolution without friction.

Teams should modernize incrementally rather than rewrite ideologically.

---

# Final Principle

The architecture judges code by:

```text
clarity of intent
operational correctness
maintainability
policy enforcement
change safety
```

—not by the number of layers or patterns involved.
