// Regenerate build/version.props from build/version.json.
//
//   dotnet run --file d:\novolis\novolis-governance\scripts\sync-version-props.cs -- --repo PATH

#:property TargetFramework=net10.0
#:property PublishAot=false
#:property PackAsTool=false
#:property ImplicitUsings=enable
#:property Nullable=enable
#:property ManagePackageVersionsCentrally=false
#:include lib/workspace.cs

using System.Text;
using System.Text.Json;

var repo = NovolisWorkspace.Arg(args, "--repo", "-RepoPath") ?? args.ElementAtOrDefault(0) ?? ".";
repo = Path.GetFullPath(repo);
var jsonPath = Path.Combine(repo, "build", "version.json");
var propsPath = Path.Combine(repo, "build", "version.props");
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
var platform = $"{year}.{major}.{minor}";
var floatVersion = $"{year}.{major}.*";
var props = $"""
    <?xml version="1.0" encoding="utf-8"?>
    <Project>
      <!-- Generated from build/version.json via scripts/sync-version-props.cs -->
      <PropertyGroup Label="Novolis platform version (YEAR.MAJOR.MINOR; BUILD from CI)">
        <NovolisYear>{year}</NovolisYear>
        <NovolisMajor>{major}</NovolisMajor>
        <NovolisMinor>{minor}</NovolisMinor>
        <NovolisPlatformVersion>{platform}</NovolisPlatformVersion>
        <NovolisPackageFloatVersion>{floatVersion}</NovolisPackageFloatVersion>
        <NovolisLocalBuild Condition="'$(NovolisLocalBuild)' == ''">1</NovolisLocalBuild>
      </PropertyGroup>
    </Project>
    """;

Directory.CreateDirectory(Path.GetDirectoryName(propsPath)!);
File.WriteAllText(propsPath, props.TrimEnd() + Environment.NewLine, new UTF8Encoding(false));
Console.WriteLine($"Wrote {propsPath} ({platform}, float {floatVersion})");
return 0;
