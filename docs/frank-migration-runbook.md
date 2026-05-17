# Frank.* migration runbook

Extract/rebuild playbook for P0 libraries. Do not transfer git history.

## Prerequisites

1. [frank-naming-and-structure.md](frank-naming-and-structure.md) signed off for the wave.
2. Frank source available under `bootstrap/scratch/frank-eval/` (or fresh shallow clone).
3. Target `novolis-*` repo scaffolded with `Directory.Build.props`, `global.json`, CI, `release.yml`.

## Per-slice steps

1. Open tracking issue on target repo (see [frank-inventory.md](frank-inventory.md)).
2. Branch `migrate/<frank-repo-short-name>`.
3. Run [migrate-frank-slice.ps1](../scripts/migrate-frank-slice.ps1) or copy manually into `src/` / `tests/`.
4. Add/update `.csproj`: `PackageId`, `Version`, `ProjectReference` to Novolis deps (never `Frank.*`).
5. Update `Novolis.<Domain>.slnx` and [.novolis/packages.json](frank-naming-and-structure.md) on the repo.
6. `dotnet build` / `dotnet test` locally.
7. PR → CI green → preview release (trusted publishing on that repo).
8. Registry entry in `novolis-registry/packages/`.
9. Frank source README banner + archive when wave complete.

## Pilot order

1. `Novolis.Messaging.Channels` (migration publish gate)
2. `Novolis.Messaging` (PulseFlow)
3. `Novolis.Testing.*`
4. `Novolis.Transports.*`
5. `Novolis.Storage.*` subset
6. `Novolis.Security.*`

## Frank README banner (template)

```markdown
> **Moved to Novolis:** This library is superseded by [`Novolis.<Package>`](https://github.com/Novolis-Platform/novolis-<domain>) on NuGet. This repository is archived; do not add features here.
```

## Registry entry (template)

Create `novolis-registry/packages/<package-id-kebab>.json`:

```json
{
  "id": "novolis.messaging.channels",
  "name": "Novolis.Messaging.Channels",
  "type": "nuget",
  "version": "0.1.0-preview.1",
  "repository": "https://github.com/Novolis-Platform/novolis-messaging",
  "packageId": "Novolis.Messaging.Channels"
}
```

Adjust fields to match [package.schema.json](https://github.com/Novolis-Platform/novolis-registry/blob/main/schemas/package.schema.json).
