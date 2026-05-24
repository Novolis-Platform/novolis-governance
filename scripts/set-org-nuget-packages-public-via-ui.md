# Set org NuGet packages to public (UI — only method that works)

GitHub’s REST API has **no** `PATCH .../visibility` for NuGet (returns 404). Use the package settings UI.

## Per package

1. Open: `https://github.com/orgs/Novolis-Platform/packages/nuget/{PackageId}/settings`
2. **Danger Zone** → **Change visibility**
3. Select **Public**
4. Type the package name to confirm
5. **I understand the consequences, change package visibility**

## Org setting (new publishes)

[Org → Settings → Packages](https://github.com/organizations/Novolis-Platform/settings/packages): enable **Public** only under **Package creation** so future CI publishes default to public.

## Verify

```powershell
gh api "orgs/Novolis-Platform/packages?package_type=nuget&per_page=100" --jq 'group_by(.visibility) | map({visibility: .[0].visibility, count: length})'
```

All entries should show `"visibility": "public"`.
