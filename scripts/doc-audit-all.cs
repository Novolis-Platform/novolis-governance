// Runs doc-audit on every novolis-* repository under a workspace root.
//
//   dotnet run --file d:\novolis\novolis-governance\scripts\doc-audit-all.cs

#:property TargetFramework=net10.0
#:property PublishAot=false
#:property PackAsTool=false
#:property ImplicitUsings=enable
#:property Nullable=enable
#:property ManagePackageVersionsCentrally=false
#:include lib/workspace.cs

using System.Diagnostics;
using System.Runtime.CompilerServices;

var root = NovolisWorkspace.Arg(args, "--workspace-root", "-WorkspaceRoot") ?? NovolisWorkspace.Root();
var requireDocs = NovolisWorkspace.Flag(args, "--require-docs", "-RequireDocumentationProps");
var scripts = Path.GetDirectoryName(ThisFile())!;
var audit = Path.Combine(scripts, "doc-audit.cs");
var failed = new List<string>();
var repos = NovolisWorkspace.NovolisRepos(root)
    .Where(r => Directory.Exists(Path.Combine(r, "src")) || Directory.Exists(Path.Combine(r, "codegen")))
    .OrderBy(Path.GetFileName, StringComparer.OrdinalIgnoreCase)
    .ToArray();

foreach (var repo in repos)
{
    var name = Path.GetFileName(repo);
    Console.WriteLine($"doc-audit: {name}");
    var extra = new List<string> { "--repo", repo };
    if (requireDocs)
        extra.Add("--require-docs");
    if (RunFile(audit, extra.ToArray()) != 0)
        failed.Add(name);
}

if (failed.Count > 0)
{
    Console.Error.WriteLine($"doc-audit-all FAILED in: {string.Join(", ", failed)}");
    return 1;
}

Console.WriteLine($"doc-audit-all OK: {repos.Length} repos");
return 0;

static string ThisFile([CallerFilePath] string path = "") => path;

static int RunFile(string file, params string[] appArgs)
{
    var psi = new ProcessStartInfo("dotnet")
    {
        RedirectStandardOutput = false,
        RedirectStandardError = false,
        UseShellExecute = false,
        CreateNoWindow = true,
    };
    psi.ArgumentList.Add("run");
    psi.ArgumentList.Add("--file");
    psi.ArgumentList.Add(file);
    psi.ArgumentList.Add("--");
    foreach (var a in appArgs)
        psi.ArgumentList.Add(a);
    using var p = Process.Start(psi) ?? throw new InvalidOperationException("Failed to start dotnet");
    p.WaitForExit();
    return p.ExitCode;
}
