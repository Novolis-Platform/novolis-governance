// Fail if Novolis libraries violate Avalonia/MAUI isolation or upward spine PackageReferences.
//
//   dotnet run --file d:\novolis\novolis-governance\scripts\verify-layer-boundaries.cs

#:property TargetFramework=net10.0
#:property PublishAot=false
#:property PackAsTool=false
#:property ImplicitUsings=enable
#:property Nullable=enable
#:property ManagePackageVersionsCentrally=false
#:include lib/workspace.cs

var root = NovolisWorkspace.Arg(args, "--workspace-root", "-WorkspaceRoot") ?? NovolisWorkspace.Root();
var violations = new List<string>();
var scanned = 0;

foreach (var repo in NovolisWorkspace.NovolisRepos(root))
{
    foreach (var csproj in NovolisWorkspace.EnumerateFiles(repo, "*.csproj"))
    {
        var name = Path.GetFileNameWithoutExtension(csproj);
        if (!name.StartsWith("Novolis.", StringComparison.Ordinal))
            continue;
        if (name.Contains(".Unit", StringComparison.Ordinal) || name.Contains(".Tests", StringComparison.Ordinal))
            continue;
        if (IsAppHostPath(csproj))
            continue;

        scanned++;
        var refs = NovolisWorkspace.PackageReferences(csproj).ToArray();
        var selfRank = SpineRank(name);
        var isAvaloniaLayer = name.StartsWith("Novolis.Avalonia", StringComparison.Ordinal);
        var isMauiLayer = name.StartsWith("Novolis.Maui", StringComparison.Ordinal);
        var isBlazorLayer = name.StartsWith("Novolis.Blazor", StringComparison.Ordinal);
        var isAvaloniaRepoSource = csproj.Replace('/', '\\').Contains(@"\novolis-avalonia\src\", StringComparison.OrdinalIgnoreCase);

        if (isAvaloniaRepoSource && !name.StartsWith("Novolis.Avalonia.", StringComparison.Ordinal))
            violations.Add($"NOV2014 {csproj}: '{name}' is under novolis-avalonia/src; only Novolis.Avalonia.* projects may live there");

        foreach (var reference in refs)
        {
            if (IsAvaloniaPackage(reference) && !isAvaloniaLayer)
                violations.Add($"NOV2006 {csproj}: library '{name}' PackageReference '{reference}' (Avalonia reserved for Novolis.Avalonia.*)");
            if (IsMauiPackage(reference) && !isMauiLayer && name != "Novolis.Audio.Voice.Platform.Maui")
                violations.Add($"NOV2010 {csproj}: library '{name}' PackageReference '{reference}' (MAUI reserved for Novolis.Maui.*)");
            if (isMauiLayer && IsAvaloniaPackage(reference))
                violations.Add($"NOV2011 {csproj}: '{name}' PackageReference '{reference}' (MAUI must not take Avalonia)");
            if (isAvaloniaLayer && IsMauiPackage(reference))
                violations.Add($"NOV2011 {csproj}: '{name}' PackageReference '{reference}' (Avalonia must not take MAUI)");
            if (IsBlazorPackage(reference) && !isBlazorLayer)
                violations.Add($"NOV2012 {csproj}: library '{name}' PackageReference '{reference}' (Blazor reserved for Novolis.Blazor.*)");
            if (isBlazorLayer && (IsAvaloniaPackage(reference) || IsMauiPackage(reference)))
                violations.Add($"NOV2013 {csproj}: '{name}' PackageReference '{reference}' (Blazor must not take Avalonia or MAUI)");
            if ((isAvaloniaLayer || isMauiLayer) && IsBlazorPackage(reference))
                violations.Add($"NOV2013 {csproj}: '{name}' PackageReference '{reference}' (Avalonia and MAUI must not take Blazor)");

            var refRank = SpineRank(reference);
            if (selfRank is int sr && refRank is int rr && sr < rr)
                violations.Add($"NOV2007 {csproj}: '{name}' (rank {sr}) → '{reference}' (rank {rr}) upward spine reference");
        }
    }
}

if (violations.Count > 0)
{
    Console.Error.WriteLine($"Layer boundary violations ({violations.Count}):");
    foreach (var v in violations)
        Console.Error.WriteLine($"  {v}");
    return 1;
}

Console.WriteLine($"verify-layer-boundaries: OK ({scanned} Novolis library projects scanned under {root})");
return 0;

static bool IsAvaloniaPackage(string id) => id == "Avalonia" || id.StartsWith("Avalonia.", StringComparison.Ordinal);
static bool IsMauiPackage(string id) => id == "Microsoft.Maui" || id.StartsWith("Microsoft.Maui.", StringComparison.Ordinal);
static bool IsBlazorPackage(string id) => id == "Microsoft.AspNetCore.Components" || id.StartsWith("Microsoft.AspNetCore.Components.", StringComparison.Ordinal);

static int? SpineRank(string name)
{
    if (name.StartsWith("Novolis.Math.", StringComparison.Ordinal) || name == "Novolis.Math") return 0;
    if (name.StartsWith("Novolis.Physics.", StringComparison.Ordinal) || name == "Novolis.Physics") return 1;
    if (name.StartsWith("Novolis.Simulation.", StringComparison.Ordinal) || name == "Novolis.Simulation") return 2;
    if (name.StartsWith("Novolis.Game.", StringComparison.Ordinal) || name == "Novolis.Game") return 3;
    if (name.StartsWith("Novolis.Avalonia.", StringComparison.Ordinal) || name == "Novolis.Avalonia") return 4;
    return null;
}

static bool IsAppHostPath(string path)
{
    var p = path.Replace('/', '\\');
    return p.Contains(@"\novolis-apps\", StringComparison.OrdinalIgnoreCase)
        || p.Contains(@"\novolis-utilities\", StringComparison.OrdinalIgnoreCase)
        || p.Contains(@"\novolis-lab\", StringComparison.OrdinalIgnoreCase)
        || p.Contains(@"\novolis-templates\", StringComparison.OrdinalIgnoreCase)
        || p.Contains(@"\treffly-app\", StringComparison.OrdinalIgnoreCase)
        || p.Contains(@"\novolis-experimental\", StringComparison.OrdinalIgnoreCase)
        || p.Contains(@"\artifacts\", StringComparison.OrdinalIgnoreCase)
        || p.Contains(@"\merglyph\", StringComparison.OrdinalIgnoreCase);
}
