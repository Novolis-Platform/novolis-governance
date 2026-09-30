// Enforces Math → Physics → Simulation boundary rules.
//
//   dotnet run --file d:\novolis\novolis-governance\scripts\verify-stack-boundaries.cs

#:property TargetFramework=net10.0
#:property PublishAot=false
#:property PackAsTool=false
#:property ImplicitUsings=enable
#:property Nullable=enable
#:property ManagePackageVersionsCentrally=false
#:include lib/workspace.cs

using System.Text.RegularExpressions;

var root = NovolisWorkspace.Root();
var hits = new List<string>();
var raylibRoot = Path.Combine(root, "novolis-raylib");
if (Directory.Exists(raylibRoot))
{
    foreach (var csproj in NovolisWorkspace.EnumerateFiles(raylibRoot, "*.csproj"))
    {
        if (File.ReadAllText(csproj).Contains("Novolis.Simulation", StringComparison.Ordinal))
            hits.Add($"{csproj}: Raylib project must not reference Novolis.Simulation.*");
    }
}

foreach (var repoName in new[] { "novolis-math", "novolis-physics", "novolis-simulation" })
{
    var repoRoot = Path.Combine(root, repoName);
    if (!Directory.Exists(repoRoot))
        continue;

    foreach (var csproj in NovolisWorkspace.EnumerateFiles(repoRoot, "*.csproj"))
    {
        if (File.ReadAllText(csproj).Contains("Novolis.Raylib", StringComparison.Ordinal))
            hits.Add($"{csproj}: Stack project must not reference Novolis.Raylib.*");
    }

    var srcRoot = Path.Combine(repoRoot, "src");
    if (!Directory.Exists(srcRoot))
        continue;

    var vector2 = new Regex(@"\bVector2\b");
    var v3d = new Regex(@"\b(struct|readonly struct|record struct)\s+Vector3d\b");
    var qd = new Regex(@"\b(struct|readonly struct|record struct)\s+Quaterniond\b");
    var v3D = new Regex(@"\b(struct|readonly struct|record struct)\s+Vector3D\b");

    foreach (var file in NovolisWorkspace.EnumerateFiles(srcRoot, "*.cs"))
    {
        var rel = Path.GetRelativePath(repoRoot, file);
        var content = File.ReadAllText(file);
        if (vector2.IsMatch(content))
            hits.Add($"{rel}: Vector2 is forbidden in stack src (use Vector3 with Y=0 for planar XZ)");
        if (v3d.IsMatch(content))
            hits.Add($"{rel}: Custom Vector3d duplicates BCL Vector3");
        if (qd.IsMatch(content))
            hits.Add($"{rel}: Custom Quaterniond duplicates BCL Quaternion");
        if (v3D.IsMatch(content))
            hits.Add($"{rel}: Custom Vector3D duplicates BCL Vector3");
    }

    if (repoName == "novolis-math")
    {
        var cameraPath = Path.Combine(srcRoot, "Novolis.Math.Geometry", "Camera.cs");
        if (File.Exists(cameraPath) && !File.ReadAllText(cameraPath).Contains("[Obsolete", StringComparison.Ordinal))
            hits.Add("novolis-math/src/Novolis.Math.Geometry/Camera.cs: Camera must live in Novolis.Simulation.View (obsolete shim allowed)");
    }
}

if (hits.Count > 0)
{
    Console.Error.WriteLine("Stack boundary verification failed:");
    foreach (var hit in hits)
        Console.Error.WriteLine(hit);
    return 1;
}

Console.WriteLine("Stack boundary verification passed for novolis-math, novolis-physics, novolis-simulation.");
return 0;
