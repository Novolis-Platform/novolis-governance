// Prepends a GitHub Packages notice and package index table to a multi-package repo README.
//
//   dotnet run --file d:\novolis\novolis-governance\scripts\sync-repo-package-index-readme.cs -- --repo PATH [--replace]

#:property TargetFramework=net10.0
#:property PublishAot=false
#:property PackAsTool=false
#:property ImplicitUsings=enable
#:property Nullable=enable
#:property ManagePackageVersionsCentrally=false
#:include lib/workspace.cs

using System.Text;
using System.Text.RegularExpressions;

var repoRoot = NovolisWorkspace.Arg(args, "--repo", "-RepoRoot") ?? args.ElementAtOrDefault(0);
var replace = NovolisWorkspace.Flag(args, "--replace", "-Replace");
if (string.IsNullOrWhiteSpace(repoRoot))
{
    Console.Error.WriteLine("Usage: sync-repo-package-index-readme --repo PATH [--replace]");
    return 2;
}

repoRoot = Path.GetFullPath(repoRoot);
var readmePath = Path.Combine(repoRoot, "README.md");
if (!File.Exists(readmePath))
{
    Console.Error.WriteLine($"Missing README.md at repo root: {repoRoot}");
    return 1;
}

var repoName = Path.GetFileName(repoRoot);
const string org = "Novolis-Platform";
var packages = new List<(string Id, string Readme)>();
foreach (var folder in new[] { "src", "codegen" })
{
    var baseDir = Path.Combine(repoRoot, folder);
    if (!Directory.Exists(baseDir))
        continue;
    foreach (var csproj in NovolisWorkspace.EnumerateFiles(baseDir, "*.csproj"))
    {
        if (string.Equals(NovolisWorkspace.ProjectProperty(csproj, "IsPackable"), "false", StringComparison.OrdinalIgnoreCase))
            continue;
        var id = NovolisWorkspace.ProjectProperty(csproj, "PackageId") ?? Path.GetFileName(Path.GetDirectoryName(csproj)!);
        var pkgReadme = Path.Combine(Path.GetDirectoryName(csproj)!, "README.md");
        if (!File.Exists(pkgReadme))
            continue;
        packages.Add((id, Path.GetRelativePath(repoRoot, pkgReadme).Replace('\\', '/')));
    }
}

if (packages.Count == 0)
{
    Console.Error.WriteLine($"No packable projects under {repoRoot}");
    return 1;
}

var sb = new StringBuilder();
sb.AppendLine("<!-- novolis-package-index:start -->");
sb.AppendLine("> **GitHub Packages shows this repository README on every package page** (upstream limitation).");
sb.AppendLine("> Open the **package README** for install and quick start — embedded in each `.nupkg` and linked below.");
sb.AppendLine();
sb.AppendLine("## Published packages");
sb.AppendLine();
sb.AppendLine("| Package | Install | Package README |");
sb.AppendLine("|---------|---------|----------------|");
foreach (var p in packages.OrderBy(p => p.Id, StringComparer.OrdinalIgnoreCase))
{
    var url = $"https://github.com/{org}/{repoName}/blob/main/{p.Readme}";
    sb.AppendLine($"| `{p.Id}` | `dotnet add package {p.Id}` | [README]({url}) |");
}

sb.AppendLine();
sb.AppendLine("For NuGet.org and Visual Studio, the **embedded** `README.md` inside each package is authoritative.");
sb.AppendLine();
sb.AppendLine("<!-- novolis-package-index:end -->");
sb.AppendLine();
var index = sb.ToString();

var body = File.ReadAllText(readmePath);
if (Regex.IsMatch(body, @"(?s)<!-- novolis-package-index:start -->.*?<!-- novolis-package-index:end -->"))
{
    if (replace)
        body = Regex.Replace(body, @"(?s)<!-- novolis-package-index:start -->.*?<!-- novolis-package-index:end -->\s*", index);
}
else
{
    body = index + body.TrimStart();
}

File.WriteAllText(readmePath, body.TrimEnd() + Environment.NewLine, new UTF8Encoding(false));
Console.WriteLine($"Updated {readmePath} ({packages.Count} packages indexed)");
return 0;
