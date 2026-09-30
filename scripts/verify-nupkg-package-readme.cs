// Verifies a packed .nupkg README H1 matches the package id.
//
//   dotnet run --file d:\novolis\novolis-governance\scripts\verify-nupkg-package-readme.cs -- --nupkg PATH --id PACKAGE

#:property TargetFramework=net10.0
#:property PublishAot=false
#:property PackAsTool=false
#:property ImplicitUsings=enable
#:property Nullable=enable
#:property ManagePackageVersionsCentrally=false
#:include lib/workspace.cs

using System.IO.Compression;
using System.Text.RegularExpressions;

var nupkg = NovolisWorkspace.Arg(args, "--nupkg", "-NupkgPath") ?? args.ElementAtOrDefault(0);
var expected = NovolisWorkspace.Arg(args, "--id", "-ExpectedPackageId") ?? args.ElementAtOrDefault(1);
if (string.IsNullOrWhiteSpace(nupkg) || string.IsNullOrWhiteSpace(expected))
{
    Console.Error.WriteLine("Usage: verify-nupkg-package-readme --nupkg PATH --id PACKAGE");
    return 2;
}

if (!File.Exists(nupkg))
{
    Console.Error.WriteLine($"Not found: {nupkg}");
    return 1;
}

using var zip = ZipFile.OpenRead(Path.GetFullPath(nupkg));
var entry = zip.GetEntry("README.md");
if (entry is null)
{
    Console.Error.WriteLine($"README.md missing from package {nupkg}");
    return 1;
}

using var reader = new StreamReader(entry.Open());
var text = reader.ReadToEnd();
if (Regex.IsMatch(text, @"(?m)^#\s+Novolis\.Raylib\s*$") && expected != "Novolis.Raylib")
{
    Console.Error.WriteLine($"Package {expected} contains repo/meta README (# Novolis.Raylib), not package-specific docs.");
    return 1;
}

if (!Regex.IsMatch(text, $@"(?m)^#\s+{Regex.Escape(expected)}\s*(\r?\n|$)"))
{
    var first = text.Split('\n')[0];
    Console.Error.WriteLine($"Package {expected} README H1 does not match. First line: {first}");
    return 1;
}

Console.WriteLine($"OK: {expected} readme in {nupkg}");
return 0;
