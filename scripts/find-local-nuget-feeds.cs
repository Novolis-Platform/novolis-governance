// Find forbidden local NuGet folder feeds in nuget.config files.
//
//   dotnet run --file d:\novolis\novolis-governance\scripts\find-local-nuget-feeds.cs

#:property TargetFramework=net10.0
#:property PublishAot=false
#:property PackAsTool=false
#:property ImplicitUsings=enable
#:property Nullable=enable
#:property ManagePackageVersionsCentrally=false
#:include lib/workspace.cs

using System.Text.RegularExpressions;

var root = NovolisWorkspace.Arg(args, "--root", "-Root") ?? NovolisWorkspace.Root();
if (!Directory.Exists(root))
{
    Console.Error.WriteLine($"Root not found: {root}");
    return 1;
}

var forbidden = new Regex(@"(?i)novolis-local|nuget-local|NOVOLIS_LOCAL_FEED|artifacts[/\\]+nuget");
var hits = new List<(string File, int Line, string Text)>();
var configs = new List<string>();
var rootConfig = Path.Combine(root, "nuget.config");
if (File.Exists(rootConfig))
    configs.Add(rootConfig);

foreach (var repo in NovolisWorkspace.NovolisRepos(root))
{
    foreach (var file in NovolisWorkspace.EnumerateFiles(repo, "nuget.config")
                 .Concat(NovolisWorkspace.EnumerateFiles(repo, "NuGet.config")))
        configs.Add(file);
}

foreach (var path in configs.Distinct(StringComparer.OrdinalIgnoreCase))
{
    var lines = File.ReadAllLines(path);
    for (var i = 0; i < lines.Length; i++)
    {
        if (!forbidden.IsMatch(lines[i]))
            continue;
        hits.Add((NovolisWorkspace.Rel(root, path), i + 1, lines[i].Trim()));
    }
}

if (hits.Count == 0)
{
    Console.WriteLine($"find-local-nuget-feeds: OK (scanned {root})");
    return 0;
}

Console.Error.WriteLine($"Found {hits.Count} local NuGet feed reference(s). Remove them (nuget.org + github only):");
foreach (var hit in hits)
    Console.Error.WriteLine($"  {hit.File}:{hit.Line} {hit.Text}");
Console.Error.WriteLine("See novolis-governance/docs/nuget-only-policy.md");
return 1;
