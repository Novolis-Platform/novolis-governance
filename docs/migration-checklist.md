# Migration checklist

1. Identify old source repo.
2. Decide move vs extract vs rebuild.
3. Create issue in target repo.
4. Copy only useful source.
5. Normalize namespace and package ID.
6. Update README; add tests and package metadata.
7. Add `.novolis/packages.json`.
8. Run CI; create preview release; validate NuGet package.
9. Archive or redirect old repo; add migration note in old README.

**Rule:** Do not transfer old repository history by default. Prefer clean curated repos unless history is legally or technically important.
