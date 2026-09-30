// Adapted from agent-contracts-standard (MIT) for novolis-governance.
//
//   dotnet run --file d:\novolis\novolis-governance\scripts\verify-acs-repo.cs

#:property TargetFramework=net10.0
#:property PublishAot=false
#:property PackAsTool=false
#:property ImplicitUsings=enable
#:property Nullable=enable
#:property ManagePackageVersionsCentrally=false

using System.Runtime.CompilerServices;

var scripts = Path.GetDirectoryName(ThisFile())!;
var root = Directory.GetParent(scripts)!.FullName;
var missing = new[]
{
    Path.Combine(root, "AGENTS.md"),
    Path.Combine(root, ".ai", "index.md"),
}.Where(p => !File.Exists(p)).ToArray();

if (missing.Length > 0)
{
    Console.Error.WriteLine("ACS layout missing: " + string.Join(", ", missing));
    return 1;
}

Console.WriteLine("ACS verification passed for novolis-governance.");
return 0;

static string ThisFile([CallerFilePath] string path = "") => path;
