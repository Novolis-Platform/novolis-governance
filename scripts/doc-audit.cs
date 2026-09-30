// Audits packable library projects for package README and documentation MSBuild settings.
//
//   dotnet run --file d:\novolis\novolis-governance\scripts\doc-audit.cs -- --repo PATH

#:property TargetFramework=net10.0
#:property PublishAot=false
#:property PackAsTool=false
#:property ImplicitUsings=enable
#:property Nullable=enable
#:property ManagePackageVersionsCentrally=false
#:include lib/workspace.cs

using System.Text.RegularExpressions;
using System.Xml.Linq;

var repoRoot = NovolisWorkspace.Arg(args, "--repo", "-RepoRoot") ?? args.ElementAtOrDefault(0);
if (string.IsNullOrWhiteSpace(repoRoot))
{
    Console.Error.WriteLine("Usage: doc-audit --repo PATH [--require-docs]");
    return 2;
}

repoRoot = Path.GetFullPath(repoRoot);
var requireDocs = NovolisWorkspace.Flag(args, "--require-docs", "-RequireDocumentationProps");
var scanRoots = new List<string>();
foreach (var name in new[] { "src", "codegen" })
{
    var dir = Path.Combine(repoRoot, name);
    if (Directory.Exists(dir))
        scanRoots.Add(dir);
}

if (scanRoots.Count == 0)
{
    Console.Error.WriteLine($"No src/ or codegen/ under {repoRoot}");
    return 1;
}

var marker = Path.Combine(repoRoot, "build", ".novolis-documentation-complete");
var enforceDocs = requireDocs || File.Exists(marker);
var failures = new List<string>();
var projects = scanRoots.SelectMany(r => NovolisWorkspace.EnumerateFiles(r, "*.csproj")).ToList();

foreach (var proj in projects)
{
    if (!IsPackable(proj))
        continue;
    var readme = Path.Combine(Path.GetDirectoryName(proj)!, "README.md");
    if (!File.Exists(readme))
    {
        failures.Add($"Missing README.md: {proj}");
        continue;
    }

    var readmeText = File.ReadAllText(readme);
    if (readmeText.Contains("See docs/getting-started.md for integration", StringComparison.Ordinal))
        failures.Add($"Placeholder quick start in README.md: {proj}");
    var hasInstall = readmeText.Contains("## Install", StringComparison.Ordinal)
        || readmeText.Contains("dotnet add package", StringComparison.Ordinal)
        || readmeText.Contains("PackageReference Include=", StringComparison.Ordinal);
    var hasQuick = readmeText.Contains("## Quick start", StringComparison.Ordinal)
        || readmeText.Contains("## Example", StringComparison.Ordinal)
        || readmeText.Contains("## Getting started", StringComparison.Ordinal)
        || readmeText.Contains("## Usage", StringComparison.Ordinal);
    if (!hasInstall || !hasQuick)
        failures.Add($"README.md missing Install or Quick start section: {proj}");

    if (enforceDocs && !HasDocumentation(proj, repoRoot, scanRoots))
        failures.Add($"GenerateDocumentationFile not enabled: {proj}");
}

if (failures.Count > 0)
{
    Console.Error.WriteLine($"doc-audit FAILED ({failures.Count} issue(s)) in {repoRoot}");
    foreach (var f in failures)
        Console.Error.WriteLine($"  {f}");
    return 1;
}

Console.WriteLine($"doc-audit OK: {projects.Count} csproj under src/ and codegen/ in {repoRoot}");
return 0;

static bool IsPackable(string proj)
{
    var n = proj.Replace('/', '\\');
    if (n.Contains(@"\tests\", StringComparison.OrdinalIgnoreCase) || n.Contains(@"\content\", StringComparison.OrdinalIgnoreCase))
        return false;
    var packable = NovolisWorkspace.ProjectProperty(proj, "IsPackable");
    return !string.Equals(packable, "false", StringComparison.OrdinalIgnoreCase);
}

static bool HasDocumentation(string proj, string repoRoot, List<string> scanRoots)
{
    if (string.Equals(NovolisWorkspace.ProjectProperty(proj, "GenerateDocumentationFile"), "true", StringComparison.OrdinalIgnoreCase))
        return true;
    var text = "";
    foreach (var root in scanRoots)
    {
        var dbp = Path.Combine(root, "Directory.Build.props");
        if (File.Exists(dbp))
            text += File.ReadAllText(dbp);
    }

    var repoBuild = Path.Combine(repoRoot, "build");
    if (Directory.Exists(repoBuild))
    {
        foreach (var props in Directory.EnumerateFiles(repoBuild, "*.props"))
            text += File.ReadAllText(props);
    }

    return Regex.IsMatch(text, @"GenerateDocumentationFile\s*>\s*true")
        || text.Contains("Novolis.Documentation.props", StringComparison.Ordinal);
}
