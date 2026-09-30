// Check generated graphical profile tokens, banners, and UI project references.
//
//   dotnet run --file d:\novolis\novolis-governance\scripts\verify-graphical-profile.cs

#:property TargetFramework=net10.0
#:property PublishAot=false
#:property PackAsTool=false
#:property ImplicitUsings=enable
#:property Nullable=enable
#:property ManagePackageVersionsCentrally=false
#:include lib/workspace.cs
#:include lib/gpr.cs

using System.Diagnostics;
using System.Text.Json;
using System.Text.RegularExpressions;

var root = NovolisWorkspace.Arg(args, "--workspace-root", "-WorkspaceRoot") ?? NovolisWorkspace.Root();
var failures = new List<string>();
var exporter = Path.Combine(root, "novolis-governance", "scripts", "Export-GraphicalProfile.cs");
if (RunFile(exporter, "--check") != 0)
    failures.Add("Generated graphical profile token sources are stale.");

var bannerDir = Path.Combine(root, ".github", "brand", "banners");
var catalogPath = Path.Combine(root, ".github", "site", "repo-catalog.json");
var required = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
if (!File.Exists(catalogPath))
{
    failures.Add($"Missing generated catalog: {catalogPath}");
}
else
{
    using var catalog = JsonDocument.Parse(File.ReadAllText(catalogPath));
    foreach (var property in catalog.RootElement.EnumerateObject())
        required.Add(property.Name == ".github" ? "github-org" : property.Name);
}

try
{
    var (code, stdout, _) = NovolisGpr.CaptureGh("repo", "list", "Novolis-Platform", "--limit", "200", "--json", "name,isArchived,visibility");
    if (code == 0 && !string.IsNullOrWhiteSpace(stdout))
    {
        using var repos = JsonDocument.Parse(stdout);
        foreach (var repo in repos.RootElement.EnumerateArray())
        {
            if (repo.TryGetProperty("isArchived", out var archived) && archived.GetBoolean())
                continue;
            if (repo.TryGetProperty("visibility", out var vis)
                && !string.Equals(vis.GetString(), "PUBLIC", StringComparison.OrdinalIgnoreCase))
                continue;
            var name = repo.GetProperty("name").GetString() ?? "";
            required.Add(name == ".github" ? "github-org" : name);
        }
    }
    else
    {
        Console.WriteLine("verify-graphical-profile: skipped live org repo list (gh unavailable).");
    }
}
catch
{
    Console.WriteLine("verify-graphical-profile: skipped live org repo list (gh unavailable).");
}

foreach (var stem in required.OrderBy(s => s, StringComparer.OrdinalIgnoreCase))
{
    var bannerPath = Path.Combine(bannerDir, $"{stem}.svg");
    if (!File.Exists(bannerPath))
        failures.Add($"Missing banner: {bannerPath}");
}

var appsRoot = Path.Combine(root, "novolis-apps", "src");
if (Directory.Exists(appsRoot))
{
    foreach (var project in NovolisWorkspace.EnumerateFiles(appsRoot, "*.csproj"))
    {
        var text = File.ReadAllText(project);
        if (Regex.IsMatch(text, @"<IsTestProject>\s*true\s*</IsTestProject>"))
            continue;
        var isMaui = Regex.IsMatch(text, @"<UseMaui>\s*true\s*</UseMaui>");
        var isAvalonia = Regex.IsMatch(text, @"<PackageReference\s+Include=""Avalonia");
        if (!isMaui && !isAvalonia)
            continue;
        var expected = isMaui ? "Novolis.Maui.GraphicalProfile" : "Novolis.Avalonia.GraphicalProfile";
        if (!text.Contains(expected, StringComparison.Ordinal))
            failures.Add($"{project} is missing {expected}.");
    }
}

if (failures.Count > 0)
{
    Console.Error.WriteLine("verify-graphical-profile: FAILED");
    foreach (var f in failures)
        Console.Error.WriteLine($"  - {f}");
    return 1;
}

Console.WriteLine("verify-graphical-profile: OK");
return 0;

static int RunFile(string file, params string[] appArgs)
{
    var psi = new ProcessStartInfo("dotnet")
    {
        RedirectStandardOutput = true,
        RedirectStandardError = true,
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
    p.StandardOutput.ReadToEnd();
    p.StandardError.ReadToEnd();
    p.WaitForExit();
    return p.ExitCode;
}
