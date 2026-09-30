// Fail if any .csproj uses cross-repo ProjectReference or sibling-src MSBuild hacks.
// Does NOT flag MSBuild ProjectReference mode (Novolis.ProjectReferenceMode.targets).
// LibraryReference is allowed in committed csproj.
//
//   dotnet run --file d:\novolis\novolis-governance\scripts\verify-nuget-only.cs

#:property TargetFramework=net10.0
#:property PublishAot=false
#:property PackAsTool=false
#:property ImplicitUsings=enable
#:property Nullable=enable
#:property ManagePackageVersionsCentrally=false

using System.Runtime.CompilerServices;
using System.Text.RegularExpressions;

var root = Environment.GetEnvironmentVariable("NOVOLIS_ROOT");
if (string.IsNullOrWhiteSpace(root))
{
    var scripts = Path.GetDirectoryName(GetScriptPath())!;
    var governance = Directory.GetParent(scripts)!.FullName;
    root = Directory.GetParent(governance)!.FullName;
}

var crossRepoRef = new Regex(@"<ProjectReference\s+Include=""[^""]*[/\\]novolis-[^""\\]+[/\\]", RegexOptions.CultureInvariant);
var srcHack = new Regex(@"<Novolis\w+Src\b", RegexOptions.CultureInvariant);
var dualRef = new Regex(@"ItemGroup\s+Condition=""[^""]*Novolis\w+Src", RegexOptions.CultureInvariant);
var packAsTool = new Regex(@"<PackAsTool>\s*true\s*</PackAsTool>", RegexOptions.CultureInvariant | RegexOptions.IgnoreCase);
var packable = new Regex(@"<IsPackable>\s*true\s*</IsPackable>", RegexOptions.CultureInvariant | RegexOptions.IgnoreCase);
var cliOrTool = new Regex(@"(\.Cli|\.Tool)$", RegexOptions.CultureInvariant | RegexOptions.IgnoreCase);

var nonLibraryRepos = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
{
    "novolis-tools",
    "novolis-utilities",
    "novolis-apps",
    "novolis-lab",
    "novolis-experimental",
    "novolis-smoketest",
    "novolis-template-dotnet",
    "novolis-templates",
    "novolis-governance",
    "novolis-workflows",
    "novolis-registry",
};

var violations = new List<string>();
var repos = Directory.GetDirectories(root, "novolis-*");
foreach (var repo in repos)
{
    var repoName = Path.GetFileName(repo);
    foreach (var csproj in Directory.EnumerateFiles(repo, "*.csproj", SearchOption.AllDirectories))
    {
        if (csproj.Contains($"{Path.DirectorySeparatorChar}obj{Path.DirectorySeparatorChar}", StringComparison.OrdinalIgnoreCase)
            || csproj.Contains($"{Path.DirectorySeparatorChar}bin{Path.DirectorySeparatorChar}", StringComparison.OrdinalIgnoreCase))
        {
            continue;
        }

        var rel = Path.GetRelativePath(root, csproj);
        var text = File.ReadAllText(csproj);
        if (crossRepoRef.IsMatch(text))
        {
            if (repoName.Equals("novolis-lab", StringComparison.OrdinalIgnoreCase)
                && Regex.IsMatch(text, @"(?i)<ProjectReference[^>]*submodules[/\\]novolis-"))
            {
                violations.Add($"{rel} : lab submodule ProjectReference is forbidden; use ProjectReference mode mapping");
            }
            else
            {
                violations.Add($"{rel} : cross-repo ProjectReference");
            }
        }

        if (srcHack.IsMatch(text))
            violations.Add($"{rel} : sibling-src MSBuild property (Novolis*Src)");
        if (dualRef.IsMatch(text))
            violations.Add($"{rel} : conditional ProjectReference/PackageReference by Novolis*Src");

        if (!nonLibraryRepos.Contains(repoName))
        {
            if (packAsTool.IsMatch(text))
                violations.Add($"{rel} : PackAsTool is only allowed in novolis-tools");

            var baseName = Path.GetFileNameWithoutExtension(csproj);
            if (packable.IsMatch(text) && cliOrTool.IsMatch(baseName))
                violations.Add($"{rel} : packable CLI/tool host is only allowed in novolis-tools");
        }
    }
}

if (violations.Count > 0)
{
    Console.Error.WriteLine("NuGet-only policy violations:");
    foreach (var v in violations)
        Console.Error.WriteLine($"  - {v}");
    Console.Error.WriteLine("See novolis-governance/docs/nuget-only-policy.md");
    return 1;
}

Console.WriteLine($"verify-nuget-only: OK ({repos.Length} repos scanned)");
return 0;

static string GetScriptPath([CallerFilePath] string path = "") => path;
