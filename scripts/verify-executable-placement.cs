// Verify shipped executable hosts stay in the executable repositories.
//
//   dotnet run --file d:\novolis\novolis-governance\scripts\verify-executable-placement.cs

#:property TargetFramework=net10.0
#:property PublishAot=false
#:property PackAsTool=false
#:property ImplicitUsings=enable
#:property Nullable=enable
#:property ManagePackageVersionsCentrally=false
#:include lib/workspace.cs

using System.Text.RegularExpressions;

var root = NovolisWorkspace.Arg(args, "--workspace-root", "-WorkspaceRoot") ?? NovolisWorkspace.Root();
var nonLibrary = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
{
    "novolis-tools", "novolis-utilities", "novolis-apps", "novolis-lab",
    "novolis-experimental", "novolis-smoketest", "novolis-template-dotnet",
    "novolis-templates", "novolis-governance", "novolis-workflows",
};
var violations = new List<string>();
var cliOrTool = new Regex(@"(\.Cli|\.Tool)$", RegexOptions.IgnoreCase);

foreach (var repo in NovolisWorkspace.NovolisRepos(root))
{
    var repoName = Path.GetFileName(repo);
    if (nonLibrary.Contains(repoName))
        continue;

    foreach (var csproj in NovolisWorkspace.EnumerateFiles(repo, "*.csproj"))
    {
        if (string.Equals(NovolisWorkspace.ProjectProperty(csproj, "PackAsTool"), "true", StringComparison.OrdinalIgnoreCase))
            violations.Add($"{csproj}: PackAsTool is only allowed in novolis-tools");

        var packable = NovolisWorkspace.ProjectProperty(csproj, "IsPackable");
        var output = NovolisWorkspace.ProjectProperty(csproj, "OutputType");
        var baseName = Path.GetFileNameWithoutExtension(csproj);
        if (string.Equals(packable, "true", StringComparison.OrdinalIgnoreCase)
            && string.Equals(output, "Exe", StringComparison.OrdinalIgnoreCase)
            && cliOrTool.IsMatch(baseName))
            violations.Add($"{csproj}: packable CLI/Tool host belongs in novolis-tools");
    }
}

if (violations.Count > 0)
{
    Console.Error.WriteLine($"Executable placement violations ({violations.Count}):");
    foreach (var v in violations)
        Console.Error.WriteLine($"  {v}");
    return 1;
}

Console.WriteLine("verify-executable-placement: OK");
return 0;
