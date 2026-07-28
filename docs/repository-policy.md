# Repository policy

- **NuGet-only cross-repo dependencies** — no sibling `ProjectReference`; see [nuget-only-policy.md](nuget-only-policy.md). Enforced by `scripts/verify-nuget-only.ps1`.
- All .NET library and tool repositories target **.NET 10** (`net10.0`) with SDK **10.0.100** minimum (`global.json` + `Directory.Build.props`).
- Public by default unless there is a clear reason otherwise.
- Use [novolis-template-dotnet](https://github.com/Novolis-Platform/novolis-template-dotnet) for package and tool repos.
- Game authoring libraries live in [novolis-gaming](https://github.com/Novolis-Platform/novolis-gaming); see [gaming-layer-policy.md](gaming-layer-policy.md).
- Production desktop apps live in [novolis-apps](https://github.com/Novolis-Platform/novolis-apps); integration smoke apps in [novolis-dogfooding](https://github.com/Novolis-Platform/novolis-dogfooding). See [apps-repos.md](apps-repos.md).
- Every repo must have README, docs/getting-started.md, docs/design.md, docs/release.md.
- Packable libraries must follow [documentation-policy.md](documentation-policy.md) (XML API docs + per-package README).
- Reserved repos state that implementation is not migrated yet.
- Branch protection on `main`: PR required, 1+ approval, status checks, linear history.
- Sensitive paths (`.github/workflows/**`, `Directory.Build.props`, `.novolis/**`) require 2 approvals.
