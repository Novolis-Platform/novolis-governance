// Reject ordinary Novolis PackageReferences in governed project files.
//
//   dotnet run --file d:\novolis\novolis-governance\scripts\verify-library-reference-usage.cs

#:property TargetFramework=net10.0
#:property PublishAot=false
#:property PackAsTool=false
#:property ImplicitUsings=enable
#:property Nullable=enable
#:property ManagePackageVersionsCentrally=false
#:include lib/workspace.cs

var root = NovolisWorkspace.Arg(args, "--root", "-Root") ?? NovolisWorkspace.Root();
var exceptions = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
{
    "Novolis.Raylib",
    "Novolis.Raylib.Native",
    "Novolis.Avalonia.Packaging.Inno",
};
var hostAllow = new Dictionary<string, HashSet<string>>(StringComparer.OrdinalIgnoreCase)
{
    ["merglyph"] = new(StringComparer.OrdinalIgnoreCase) { "Novolis.Maui.Markdown" },
    ["treffly-app"] = new(StringComparer.OrdinalIgnoreCase)
    {
        "Novolis.Avalonia.Mobile",
        "Novolis.Avalonia.Mobile.Android",
        "Novolis.Avalonia.Mobile.Desktop",
    },
};

var violations = new List<string>();
var repos = NovolisWorkspace.NovolisRepos(root)
    .Concat(Directory.GetDirectories(root).Where(d => hostAllow.ContainsKey(Path.GetFileName(d))))
    .Distinct(StringComparer.OrdinalIgnoreCase)
    .OrderBy(n => n, StringComparer.OrdinalIgnoreCase)
    .ToArray();

foreach (var repo in repos)
{
    var repoName = Path.GetFileName(repo);
    foreach (var csproj in NovolisWorkspace.EnumerateFiles(repo, "*.csproj"))
    {
        if (csproj.Contains("_scratch", StringComparison.OrdinalIgnoreCase)
            || csproj.Contains("_docprobe", StringComparison.OrdinalIgnoreCase))
            continue;

        var rel = NovolisWorkspace.Rel(root, csproj);
        foreach (var packageId in NovolisWorkspace.PackageReferences(csproj))
        {
            if (!packageId.StartsWith("Novolis.", StringComparison.Ordinal))
                continue;
            if (exceptions.Contains(packageId))
                continue;
            if (hostAllow.TryGetValue(repoName, out var allowed) && allowed.Contains(packageId))
                continue;
            violations.Add($"{rel} : {packageId} must use LibraryReference (or receive a reviewed exception in verify-library-reference-usage)");
        }
    }
}

if (violations.Count > 0)
{
    Console.Error.WriteLine("LibraryReference usage violations:");
    foreach (var v in violations)
        Console.Error.WriteLine($"  - {v}");
    Console.Error.WriteLine("See novolis-governance/docs/nuget-only-policy.md");
    return 1;
}

Console.WriteLine($"verify-library-reference-usage: OK ({repos.Length} repos scanned)");
return 0;
