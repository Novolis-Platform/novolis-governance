// Find references to renamed/retired Novolis package ids.
//
//   dotnet run --file d:\novolis\novolis-governance\scripts\find-stale-package-ids.cs

#:property TargetFramework=net10.0
#:property PublishAot=false
#:property PackAsTool=false
#:property ImplicitUsings=enable
#:property Nullable=enable
#:property ManagePackageVersionsCentrally=false
#:include lib/workspace.cs

using System.Text.RegularExpressions;

var root = NovolisWorkspace.Arg(args, "--root", "-Root") ?? NovolisWorkspace.Root();
var stale = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase)
{
    ["Novolis.Audio.Host.NAudio"] = "Novolis.Audio.Output.NAudio",
    ["Novolis.Audio.Host.Abstractions"] = "Novolis.Audio.Output.Abstractions",
    ["Novolis.Audio.Live.Repl"] = "Novolis.Audio.Live.Protocol (Repl types)",
    ["Novolis.Audio.Analysis"] = "Novolis.Audio.Live.Visuals",
    ["Novolis.Audio.Live.Host"] = "LiveStudio.Host in novolis-apps (not a package)",
};

for (var i = 0; i < args.Length; i++)
{
    if ((string.Equals(args[i], "--extra", StringComparison.OrdinalIgnoreCase)
         || string.Equals(args[i], "-ExtraIds", StringComparison.OrdinalIgnoreCase))
        && i + 1 < args.Length)
        stale[args[i + 1]] = "(custom)";
}

var includeRx = new Regex($@"(?i)Include=""(?<id>{string.Join("|", stale.Keys.Select(Regex.Escape))})""");
var hits = new List<(string File, int Line, string Package, string Replacement)>();

foreach (var repo in NovolisWorkspace.NovolisRepos(root))
{
    var props = Path.Combine(repo, "Directory.Packages.props");
    if (File.Exists(props))
        Scan(props);
    foreach (var csproj in NovolisWorkspace.EnumerateFiles(repo, "*.csproj"))
        Scan(csproj);
}

if (hits.Count == 0)
{
    Console.WriteLine($"find-stale-package-ids: OK (scanned {root})");
    return 0;
}

Console.Error.WriteLine($"Found {hits.Count} stale package id reference(s):");
foreach (var hit in hits)
    Console.Error.WriteLine($"  {hit.File}:{hit.Line} {hit.Package} → {hit.Replacement}");
Console.Error.WriteLine("See novolis-governance/docs/nuget-only-policy.md and gpr-maintenance.md");
return 1;

void Scan(string path)
{
    var rel = NovolisWorkspace.Rel(root, path);
    var lines = File.ReadAllLines(path);
    for (var i = 0; i < lines.Length; i++)
    {
        var m = includeRx.Match(lines[i]);
        if (!m.Success)
            continue;
        var id = m.Groups["id"].Value;
        hits.Add((rel, i + 1, id, stale[id]));
    }
}
