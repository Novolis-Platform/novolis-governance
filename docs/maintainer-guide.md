# Maintainer guide

- Review workflow, package, and registry changes carefully (2 approvals for sensitive paths).
- Use `novolis-workflows` reusable workflows; do not duplicate CI logic per repo.
- Validate `.novolis/packages.json` when adding packages.
- Smoke-test publishing with `novolis-smoketest` before migrating real libraries.
