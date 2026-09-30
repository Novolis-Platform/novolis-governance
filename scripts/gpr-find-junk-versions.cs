// Find throwaway NuGet versions on GitHub Packages that poison 2026.1.* floats.
//
//   dotnet run --file d:\novolis\novolis-governance\scripts\gpr-find-junk-versions.cs

#:property TargetFramework=net10.0
#:property PublishAot=false
#:property PackAsTool=false
#:property ImplicitUsings=enable
#:property Nullable=enable
#:property ManagePackageVersionsCentrally=false
#:include lib/gpr.cs

var org = "Novolis-Platform";
for (var i = 0; i < args.Length; i++)
{
    if ((string.Equals(args[i], "--org", StringComparison.OrdinalIgnoreCase)
         || string.Equals(args[i], "-Org", StringComparison.OrdinalIgnoreCase))
        && i + 1 < args.Length)
        org = args[i + 1];
}

var hits = new List<(string Package, string Version, string Repository, string? Created)>();
foreach (var pkg in NovolisGpr.ListPackages(org))
{
    var name = pkg.GetProperty("name").GetString() ?? "";
    var repo = pkg.TryGetProperty("repository", out var repository) && repository.TryGetProperty("full_name", out var full)
        ? full.GetString() ?? "(none)"
        : "(none)";
    foreach (var v in NovolisGpr.ListVersions(org, name))
    {
        var version = v.GetProperty("name").GetString() ?? "";
        if (!NovolisGpr.IsJunkVersion(version))
            continue;
        hits.Add((name, version, repo, v.TryGetProperty("created_at", out var c) ? c.GetString() : null));
    }
}

if (hits.Count == 0)
{
    Console.WriteLine($"gpr-find-junk-versions: OK (no junk versions in {org})");
    return 0;
}

Console.Error.WriteLine($"Found {hits.Count} junk version(s) that can poison 2026.1.* floats:");
foreach (var hit in hits.OrderBy(h => h.Package).ThenBy(h => h.Version))
    Console.Error.WriteLine($"  {hit.Package} {hit.Version} {hit.Repository} {hit.Created}");
Console.Error.WriteLine("Remove with gpr-remove-junk-versions.ps1 (stays PowerShell).");
return 1;
