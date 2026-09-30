// Find Novolis PackageVersion floats that are not on the platform line.
//
//   dotnet run --file d:\novolis\novolis-governance\scripts\find-build-line-floats.cs

#:property TargetFramework=net10.0
#:property PublishAot=false
#:property PackAsTool=false
#:property ImplicitUsings=enable
#:property Nullable=enable
#:property ManagePackageVersionsCentrally=false
#:include lib/workspace.cs

using System.Text.RegularExpressions;

var root = NovolisWorkspace.Arg(args, "--root", "-Root") ?? NovolisWorkspace.Root();
var buildLineFloat = new Regex(@"Version\s*=\s*""(?<ver>2026\.1\.\d+\.\*)""");
var hits = new List<(string File, int Line, string Package, string Version)>();

foreach (var repo in NovolisWorkspace.NovolisRepos(root))
{
    var props = Path.Combine(repo, "Directory.Packages.props");
    if (!File.Exists(props))
        continue;
    var rel = NovolisWorkspace.Rel(root, props);
    var lines = File.ReadAllLines(props);
    for (var i = 0; i < lines.Length; i++)
    {
        var line = lines[i];
        if (!line.Contains("PackageVersion", StringComparison.Ordinal) || !line.Contains("Novolis.", StringComparison.Ordinal))
            continue;
        var pkg = Regex.Match(line, @"Include=""(?<id>[^""]+)""");
        var id = pkg.Success ? pkg.Groups["id"].Value : "(unknown)";
        var m = buildLineFloat.Match(line);
        if (m.Success)
            hits.Add((rel, i + 1, id, m.Groups["ver"].Value));
    }
}

if (hits.Count == 0)
{
    Console.WriteLine($"find-build-line-floats: OK (scanned {root})");
    return 0;
}

Console.Error.WriteLine($"Found {hits.Count} build-line float(s). Prefer 2026.1.* or an exact published pin:");
foreach (var hit in hits)
    Console.Error.WriteLine($"  {hit.File}:{hit.Line} {hit.Package} {hit.Version}");
Console.Error.WriteLine("See novolis-governance/docs/nuget-only-policy.md");
return 1;
