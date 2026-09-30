// Overview of Novolis org NuGet packages on GitHub Packages.
//
//   dotnet run --file d:\novolis\novolis-governance\scripts\gpr-package-overview.cs

#:property TargetFramework=net10.0
#:property PublishAot=false
#:property PackAsTool=false
#:property ImplicitUsings=enable
#:property Nullable=enable
#:property ManagePackageVersionsCentrally=false
#:include lib/gpr.cs

using System.Text.Json;

var org = NovolisArg(args, "--org", "-Org") ?? "Novolis-Platform";
var unlinkedOnly = HasFlag(args, "--unlinked-only", "-UnlinkedOnly");
var junkLatestOnly = HasFlag(args, "--junk-latest-only", "-JunkLatestOnly");
var packages = NovolisGpr.ListPackages(org);
var rows = new List<Row>();

foreach (var pkg in packages)
{
    var name = pkg.GetProperty("name").GetString() ?? "";
    var versions = NovolisGpr.ListVersions(org, name);
    var latest = versions.Count > 0 ? versions[0].GetProperty("name").GetString() : null;
    var repo = pkg.TryGetProperty("repository", out var repository) && repository.TryGetProperty("full_name", out var full)
        ? full.GetString()
        : null;
    var junkLatest = latest is not null && NovolisGpr.IsJunkVersion(latest);
    var junkCount = versions.Count(v => NovolisGpr.IsJunkVersion(v.GetProperty("name").GetString() ?? ""));
    var linked = !string.IsNullOrWhiteSpace(repo);
    if (unlinkedOnly && linked)
        continue;
    if (junkLatestOnly && !junkLatest)
        continue;
    rows.Add(new Row(name, latest, versions.Count, junkCount, junkLatest, repo ?? "(none)", linked, pkg.TryGetProperty("visibility", out var vis) ? vis.GetString() : null));
}

var linkedCount = rows.Count(r => r.Linked);
var unlinked = rows.Count(r => !r.Linked);
var junkLatestCount = rows.Count(r => r.JunkLatest);
var withJunk = rows.Count(r => r.JunkVersions > 0);
Console.WriteLine($"Org: {org}  packages: {rows.Count}  linked: {linkedCount}  unlinked: {unlinked}  junk-latest: {junkLatestCount}  with-junk: {withJunk}");
Console.WriteLine();
Console.WriteLine($"{"Package",-48} {"Latest",-16} {"Ver",4} {"Junk",4} Repository");
foreach (var row in rows.OrderBy(r => r.Package, StringComparer.OrdinalIgnoreCase))
    Console.WriteLine($"{row.Package,-48} {row.Latest,-16} {row.Versions,4} {row.JunkVersions,4} {row.Repository}");

return unlinked > 0 || junkLatestCount > 0 || withJunk > 0 ? 1 : 0;

static string? NovolisArg(string[] args, params string[] names)
{
    for (var i = 0; i < args.Length; i++)
    {
        foreach (var name in names)
        {
            if (string.Equals(args[i], name, StringComparison.OrdinalIgnoreCase) && i + 1 < args.Length)
                return args[i + 1];
        }
    }

    return null;
}

static bool HasFlag(string[] args, params string[] names) =>
    args.Any(a => names.Any(n => string.Equals(a, n, StringComparison.OrdinalIgnoreCase)));

sealed record Row(string Package, string? Latest, int Versions, int JunkVersions, bool JunkLatest, string Repository, bool Linked, string? Visibility);
