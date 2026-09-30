// Find published NuGet versions whose Novolis dependencies are missing from GPR.
//
//   dotnet run --file d:\novolis\novolis-governance\scripts\gpr-find-broken-deps.cs

#:property TargetFramework=net10.0
#:property PublishAot=false
#:property PackAsTool=false
#:property ImplicitUsings=enable
#:property Nullable=enable
#:property ManagePackageVersionsCentrally=false
#:include lib/gpr.cs

using System.IO.Compression;
using System.Text.RegularExpressions;

var org = "Novolis-Platform";
string? filter = null;
var maxPackages = 0;
for (var i = 0; i < args.Length; i++)
{
    if (Match(args[i], "--org", "-Org") && i + 1 < args.Length) org = args[++i];
    else if (Match(args[i], "--package", "-Package") && i + 1 < args.Length) filter = args[++i];
    else if (Match(args[i], "--max", "-MaxPackages") && i + 1 < args.Length) maxPackages = int.Parse(args[++i]);
}

NovolisGpr.AssertGh();
var token = NovolisGpr.AuthToken();
Console.WriteLine($"Loading package inventory for {org}...");
var packages = NovolisGpr.ListPackages(org);
if (!string.IsNullOrWhiteSpace(filter))
    packages = packages.Where(p => string.Equals(p.GetProperty("name").GetString(), filter, StringComparison.OrdinalIgnoreCase)).ToList();
if (maxPackages > 0 && packages.Count > maxPackages)
    packages = packages.Take(maxPackages).ToList();

var versionIndex = new Dictionary<string, (HashSet<string> Versions, string? Latest)>(StringComparer.OrdinalIgnoreCase);
Console.WriteLine($"Indexing versions ({packages.Count} packages)...");
foreach (var pkg in packages)
{
    var name = pkg.GetProperty("name").GetString() ?? "";
    versionIndex[name] = IndexPackage(org, name);
}

void EnsureIndexed(string id)
{
    if (versionIndex.ContainsKey(id))
        return;
    try
    {
        versionIndex[id] = IndexPackage(org, id);
    }
    catch
    {
        versionIndex[id] = (new HashSet<string>(StringComparer.OrdinalIgnoreCase), null);
    }
}

var depRx = new Regex(@"<dependency\s+id=""(?<id>Novolis\.[^""]+)""\s+version=""(?<ver>[^""]+)""");
var hits = new List<(string Package, string PackageVersion, string Dependency, string Required, string? Available)>();
var inspected = 0;
using var http = new HttpClient();
http.DefaultRequestHeaders.Authorization = new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", token);
http.DefaultRequestHeaders.Accept.ParseAdd("application/octet-stream");

foreach (var pkg in packages)
{
    var name = pkg.GetProperty("name").GetString() ?? "";
    if (!versionIndex.TryGetValue(name, out var meta) || meta.Latest is null)
        continue;
    var nuspec = await DownloadNuspec(http, org, name, meta.Latest);
    inspected++;
    if (nuspec is null)
    {
        Console.WriteLine($"WARN: could not download {name} {meta.Latest}");
        continue;
    }

    foreach (Match m in depRx.Matches(nuspec))
    {
        var depId = m.Groups["id"].Value;
        var depVer = m.Groups["ver"].Value;
        if (depVer.Contains('*') || depVer.Contains('[') || depVer.Contains('('))
            continue;
        EnsureIndexed(depId);
        if (!versionIndex[depId].Versions.Contains(depVer))
            hits.Add((name, meta.Latest, depId, depVer, versionIndex[depId].Latest));
    }

    if (inspected % 25 == 0)
        Console.WriteLine($"  inspected {inspected} / {packages.Count}...");
}

if (hits.Count == 0)
{
    Console.WriteLine($"gpr-find-broken-deps: OK ({inspected} package latest version(s) inspected)");
    return 0;
}

Console.Error.WriteLine($"Found {hits.Count} broken Novolis dependency edge(s) on latest versions:");
foreach (var hit in hits.OrderBy(h => h.Package).ThenBy(h => h.Dependency))
    Console.Error.WriteLine($"  {hit.Package} {hit.PackageVersion} → {hit.Dependency} {hit.Required} (latest {hit.Available})");
return 1;

static bool Match(string value, params string[] names) =>
    names.Any(n => string.Equals(value, n, StringComparison.OrdinalIgnoreCase));

static (HashSet<string> Versions, string? Latest) IndexPackage(string org, string name)
{
    var versions = NovolisGpr.ListVersions(org, name);
    var set = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
    foreach (var v in versions)
        set.Add(v.GetProperty("name").GetString() ?? "");
    return (set, versions.Count > 0 ? versions[0].GetProperty("name").GetString() : null);
}

static async Task<string?> DownloadNuspec(HttpClient http, string org, string packageId, string version)
{
    var tmp = Path.Combine(Path.GetTempPath(), $"gpr-nuspec-{packageId}-{Guid.NewGuid():N}");
    Directory.CreateDirectory(tmp);
    try
    {
        var nupkg = Path.Combine(tmp, $"{packageId}.{version}.nupkg");
        var url = $"https://nuget.pkg.github.com/{org}/download/{packageId}/{version}/{packageId}.{version}.nupkg";
        using var response = await http.GetAsync(url);
        if (!response.IsSuccessStatusCode)
            return null;
        await using (var fs = File.Create(nupkg))
            await response.Content.CopyToAsync(fs);
        using var zip = ZipFile.OpenRead(nupkg);
        var entry = zip.Entries.FirstOrDefault(e => e.Name.EndsWith(".nuspec", StringComparison.OrdinalIgnoreCase));
        if (entry is null)
            return null;
        using var reader = new StreamReader(entry.Open());
        return await reader.ReadToEndAsync();
    }
    catch
    {
        return null;
    }
    finally
    {
        try { Directory.Delete(tmp, true); } catch { /* ignore */ }
    }
}
