# Security policy

- Report vulnerabilities via GitHub Private Vulnerability Reporting.
- External PRs run unprivileged CI only; no secrets on fork PRs.
- Registry: HTTPS only, SHA-256 for every artifact, updates via PR only.
- Dependabot PRs touching workflows or packages require maintainer review.
