# Contribution policy

- **Maintainers and agents:** commit on `main` and push directly. Do not open pull requests for ordinary Novolis-Platform work; merge CI (`merge.yml`) publishes packages.
- **External contributors:** fork PRs welcome; fork PRs are unprivileged (build/test only via `pull-request.yml`).
- Maintainers trigger publish and release flows (merge/release workflows).
- Large changes should start as a Discussion or issue.
- Generated files must be clearly marked.
- **Libraries vs tools:** domain algorithms live in packages; CLIs and file tools are shallow wrappers — see [library-vs-cli.md](library-vs-cli.md).
- **Avalonia composition:** Layout shell → Controls atoms → domain panels → apps — see [avalonia-composition-grain.md](avalonia-composition-grain.md).
