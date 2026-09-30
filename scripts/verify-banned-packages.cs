// Fail if any novolis-* repo references banned NuGet packages (Markdig, QuestPDF).
//
//   dotnet run --file d:\novolis\novolis-governance\scripts\verify-banned-packages.cs

#:property TargetFramework=net10.0
#:property PublishAot=false
#:property PackAsTool=false
#:property ImplicitUsings=enable
#:property Nullable=enable
#:property ManagePackageVersionsCentrally=false
#:include lib/workspace.cs

using System.Text.RegularExpressions;

var root = NovolisWorkspace.Root();
var banned = new HashSet<string>(StringComparer.OrdinalIgnoreCase) { "Markdig", "QuestPDF" };
var packageRef = new Regex(@"<PackageReference\s+Include=""(?<id>[^""]+)""", RegexOptions.CultureInvariant);
var packageVersion = new Regex(@"<PackageVersion\s+Include=""(?<id>[^""]+)""", RegexOptions.CultureInvariant);
var usingBanned = new Regex(@"(?m)^\s*using\s+(Markdig|QuestPDF)(\.|;)", RegexOptions.CultureInvariant);
var violations = new List<string>();
var repos = NovolisWorkspace.NovolisRepos(root).ToArray();

foreach (var repo in repos)
{
    foreach (var file in NovolisWorkspace.EnumerateFiles(repo, "*.*")
                 .Where(f => f.EndsWith(".csproj", StringComparison.OrdinalIgnoreCase)
                     || f.EndsWith("Directory.Packages.props", StringComparison.OrdinalIgnoreCase)
                     || f.EndsWith("Packages.props", StringComparison.OrdinalIgnoreCase)))
    {
        var rel = NovolisWorkspace.Rel(root, file);
        var text = File.ReadAllText(file);
        foreach (Match m in packageRef.Matches(text))
        {
            if (banned.Contains(m.Groups["id"].Value))
                violations.Add($"{rel} : PackageReference {m.Groups["id"].Value}");
        }

        foreach (Match m in packageVersion.Matches(text))
        {
            if (banned.Contains(m.Groups["id"].Value))
                violations.Add($"{rel} : PackageVersion {m.Groups["id"].Value}");
        }
    }

    foreach (var file in NovolisWorkspace.EnumerateFiles(repo, "*.cs"))
    {
        if (usingBanned.IsMatch(File.ReadAllText(file)))
            violations.Add($"{NovolisWorkspace.Rel(root, file)} : using Markdig/QuestPDF");
    }
}

if (violations.Count > 0)
{
    Console.Error.WriteLine("Banned package policy violations (Markdig / QuestPDF):");
    foreach (var v in violations)
        Console.Error.WriteLine($"  - {v}");
    Console.Error.WriteLine("See novolis-governance/docs/markdown-and-pdf-policy.md");
    return 1;
}

Console.WriteLine($"verify-banned-packages: OK ({repos.Length} repos scanned)");
return 0;
