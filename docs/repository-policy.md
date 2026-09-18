# Repository policy

- **NuGet-only cross-repo dependencies** — no sibling `ProjectReference`; see [nuget-only-policy.md](nuget-only-policy.md). Enforced by `scripts/verify-nuget-only.ps1`.
- All .NET library and tool repositories target **.NET 10** (`net10.0`) with SDK **10.0.100** minimum (`global.json` + `Directory.Build.props`).
- Public by default unless there is a clear reason otherwise.
- Use [novolis-template-dotnet](https://github.com/Novolis-Platform/novolis-template-dotnet) for package, tool, utility, and lab repos.
- Game authoring libraries live in [novolis-gaming](https://github.com/Novolis-Platform/novolis-gaming); see [gaming-layer-policy.md](gaming-layer-policy.md).
- `PackAsTool` commands live in [novolis-tools](https://github.com/Novolis-Platform/novolis-tools); small technical executables live in [novolis-utilities](https://github.com/Novolis-Platform/novolis-utilities); production desktop apps and games live in [novolis-apps](https://github.com/Novolis-Platform/novolis-apps); integration labs live in [novolis-lab](https://github.com/Novolis-Platform/novolis-lab). Library repos must not host product `apps/`, shipped CLIs, or packable tool hosts — packable `src/`, tests, and private `tools/` only. See [apps-repos.md](apps-repos.md) and [executable-grains.md](executable-grains.md).
- Every repo must have README, docs/getting-started.md, docs/design.md, docs/release.md.
- Packable libraries must follow [documentation-policy.md](documentation-policy.md) (XML API docs + per-package README).
- Reserved repos state that implementation is not migrated yet.
- Branch protection on `main`: PR required, 1+ approval, status checks, linear history.
- Sensitive paths (`.github/workflows/**`, `Directory.Build.props`, `.novolis/**`) require 2 approvals.
