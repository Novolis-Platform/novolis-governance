# Frank P0 sunset banners

Apply to Frank source README files when each wave ships on NuGet.

## Template

```markdown
> **Moved to Novolis:** This library is superseded by [`{PackageId}`](https://www.nuget.org/packages/{PackageId}) from [novolis-{domain}](https://github.com/Novolis-Platform/novolis-{domain}). This repository is archived; do not add features here.
```

## Wave mapping

| Frank repo | Novolis package |
|------------|-----------------|
| Frank.Channels.DependencyInjection | `Novolis.Messaging.Channels` |
| Frank.PulseFlow | `Novolis.Messaging` |
| Frank.Testing.* | `Novolis.Testing.*` |
| Frank.BedrockSlim | `Novolis.Transports.Tcp.*` |
| Frank.Http | `Novolis.Transports.Http.*` |
| Frank.DataStorage (subset) | `Novolis.Storage.*` |
| Frank.Security | `Novolis.Security.*` |
| Frank.Reflection (subset) | `Novolis.CodeGen.Reflection*` |
| Frank.Analyzers (subset) | `Novolis.Analyzers.AutoMapper`, `Novolis.Analyzers.CodeLength` |
