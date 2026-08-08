# Maintainer guide

- **Ship on `main`:** maintainers and agents push commits to `main` (no feature-branch PRs for ordinary work). Package publish runs from `merge.yml` on push to `main`.
- External/fork PRs still use `pull-request.yml`; do not treat those as the maintainer workflow.
- Review workflow, package, and registry changes carefully (2 approvals for sensitive paths).
- Use `novolis-workflows` reusable workflows; do not duplicate CI logic per repo.
- Validate `.novolis/packages.json` when adding packages.
- Smoke-test publishing with `novolis-smoketest` before migrating real libraries.
