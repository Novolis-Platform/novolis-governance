// Fails if novolis-* repos reference forbidden test packages or patterns.
//
//   dotnet run --file d:\novolis\novolis-governance\scripts\verify-tunit-only.cs

#:property TargetFramework=net10.0
#:property PublishAot=false
#:property PackAsTool=false
#:property ImplicitUsings=enable
#:property Nullable=enable
#:property ManagePackageVersionsCentrally=false
#:include lib/workspace.cs

var root = NovolisWorkspace.Root();
var patterns = new[]
{
    "FluentAssertions",
    "PackageReference Include=\"xunit\"",
    "PackageVersion Include=\"xunit\"",
    "using Xunit",
    "[Fact]",
};
var hits = new List<string>();

foreach (var repo in NovolisWorkspace.NovolisRepos(root))
{
    foreach (var file in NovolisWorkspace.EnumerateFiles(repo, "*.*")
                 .Where(f => f.EndsWith(".cs", StringComparison.OrdinalIgnoreCase)
                     || f.EndsWith(".csproj", StringComparison.OrdinalIgnoreCase)
                     || f.EndsWith("Directory.Packages.props", StringComparison.OrdinalIgnoreCase)))
    {
        var content = File.ReadAllText(file);
        foreach (var pattern in patterns)
        {
            if (content.Contains(pattern, StringComparison.Ordinal))
                hits.Add($"{file}: {pattern}");
        }
    }
}

if (hits.Count > 0)
{
    Console.Error.WriteLine("TUnit-only verification failed:");
    foreach (var hit in hits)
        Console.Error.WriteLine(hit);
    return 1;
}

Console.WriteLine("TUnit-only verification passed for novolis-* repos.");
return 0;
