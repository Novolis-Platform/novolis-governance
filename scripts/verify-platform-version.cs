// Fails if build/version.json is not on the platform line YEAR.1.1 (default 2026.1.1).
//
//   dotnet run --file d:\novolis\novolis-governance\scripts\verify-platform-version.cs -- --repo PATH

#:property TargetFramework=net10.0
#:property PublishAot=false
#:property PackAsTool=false
#:property ImplicitUsings=enable
#:property Nullable=enable
#:property ManagePackageVersionsCentrally=false
#:include lib/workspace.cs

using System.Text.Json;

var repo = NovolisWorkspace.Arg(args, "--repo", "-RepoPath") ?? args.ElementAtOrDefault(0);
if (string.IsNullOrWhiteSpace(repo))
{
    Console.Error.WriteLine("Usage: verify-platform-version --repo PATH");
    return 2;
}

repo = Path.GetFullPath(repo);
var expectedYear = int.Parse(NovolisWorkspace.Arg(args, "--year", "-ExpectedYear") ?? "2026");
var expectedMajor = int.Parse(NovolisWorkspace.Arg(args, "--major", "-ExpectedMajor") ?? "1");
var expectedMinor = int.Parse(NovolisWorkspace.Arg(args, "--minor", "-ExpectedMinor") ?? "1");
var jsonPath = Path.Combine(repo, "build", "version.json");
if (!File.Exists(jsonPath))
{
    Console.Error.WriteLine($"Missing {jsonPath}");
    return 1;
}

using var doc = JsonDocument.Parse(File.ReadAllText(jsonPath));
var v = doc.RootElement;
int ReadInt(params string[] names)
{
    foreach (var name in names)
    {
        if (v.TryGetProperty(name, out var p) && p.TryGetInt32(out var n))
            return n;
    }

    return 0;
}

var year = ReadInt("year", "sdkYear");
var major = ReadInt("major", "apiBreak");
var minor = ReadInt("minor", "feature");
var failures = new List<string>();
if (year != expectedYear)
    failures.Add($"year={year} (expected {expectedYear})");
if (major != expectedMajor)
    failures.Add($"major={major} (expected {expectedMajor} — a value of 2 would publish 2026.2.* and is forbidden without approval)");
if (minor != expectedMinor)
    failures.Add($"minor={minor} (expected {expectedMinor})");

var propsPath = Path.Combine(repo, "build", "version.props");
if (File.Exists(propsPath))
{
    var propsText = File.ReadAllText(propsPath);
    var expectedPlatform = $"{expectedYear}.{expectedMajor}.{expectedMinor}";
    if (!propsText.Contains($"<NovolisPlatformVersion>{expectedPlatform}</NovolisPlatformVersion>", StringComparison.Ordinal))
        failures.Add($"build/version.props NovolisPlatformVersion does not match {expectedPlatform}");
    var expectedFloat = $"{expectedYear}.{expectedMajor}.*";
    if (!propsText.Contains($"<NovolisPackageFloatVersion>{expectedFloat}</NovolisPackageFloatVersion>", StringComparison.Ordinal))
        failures.Add($"build/version.props NovolisPackageFloatVersion does not match {expectedFloat}");
}

if (failures.Count > 0)
{
    Console.Error.WriteLine($"Platform version mismatch in {repo} : {string.Join("; ", failures)}");
    return 1;
}

Console.WriteLine($"OK {Path.GetFileName(repo)} platform line {year}.{major}.{minor} (GPR: {year}.{major}.{minor}.BUILD)");
return 0;
