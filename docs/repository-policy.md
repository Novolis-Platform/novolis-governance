# Repository policy

- All .NET library and tool repositories target **.NET 10** (`net10.0`) with SDK **10.0.100** minimum (`global.json` + `Directory.Build.props`).
- Public by default unless there is a clear reason otherwise.
- Use [novolis-template-dotnet](https://github.com/Novolis-Platform/novolis-template-dotnet) for package and tool repos.
- Every repo must have README, docs/getting-started.md, docs/design.md, docs/release.md.
- Reserved repos state that implementation is not migrated yet.
- Branch protection on `main`: PR required, 1+ approval, status checks, linear history.
- Sensitive paths (`.github/workflows/**`, `Directory.Build.props`, `.novolis/**`) require 2 approvals.
