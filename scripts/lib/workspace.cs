using System.Runtime.CompilerServices;
using System.Xml.Linq;

static class NovolisWorkspace
{
    public static string Root([CallerFilePath] string thisFile = "")
    {
        var env = Environment.GetEnvironmentVariable("NOVOLIS_ROOT");
        if (!string.IsNullOrWhiteSpace(env))
            return Path.GetFullPath(env);

        var dir = Path.GetDirectoryName(thisFile)!;
        if (string.Equals(Path.GetFileName(dir), "lib", StringComparison.OrdinalIgnoreCase))
            dir = Directory.GetParent(dir)!.FullName;
        var governance = Directory.GetParent(dir)!.FullName;
        return Directory.GetParent(governance)!.FullName;
    }

    public static string? Arg(string[] args, params string[] names)
    {
        for (var i = 0; i < args.Length; i++)
        {
            foreach (var name in names)
            {
                if (string.Equals(args[i], name, StringComparison.OrdinalIgnoreCase)
                    && i + 1 < args.Length)
                    return args[i + 1];
                var prefix = name + "=";
                if (args[i].StartsWith(prefix, StringComparison.OrdinalIgnoreCase))
                    return args[i][prefix.Length..];
            }
        }

        return null;
    }

    public static bool Flag(string[] args, params string[] names) =>
        args.Any(a => names.Any(n => string.Equals(a, n, StringComparison.OrdinalIgnoreCase)));

    public static IEnumerable<string> NovolisRepos(string root) =>
        Directory.GetDirectories(root, "novolis-*").OrderBy(Path.GetFileName, StringComparer.OrdinalIgnoreCase);

    public static IEnumerable<string> EnumerateFiles(string root, string pattern, bool skipBuild = true)
    {
        foreach (var path in Directory.EnumerateFiles(root, pattern, SearchOption.AllDirectories))
        {
            if (skipBuild && IsBuildPath(path))
                continue;
            yield return path;
        }
    }

    public static bool IsBuildPath(string path)
    {
        var n = path.Replace('/', '\\');
        return n.Contains(@"\obj\", StringComparison.OrdinalIgnoreCase)
            || n.Contains(@"\bin\", StringComparison.OrdinalIgnoreCase)
            || n.Contains(@"\artifacts\", StringComparison.OrdinalIgnoreCase)
            || n.Contains(@"\TestResults\", StringComparison.OrdinalIgnoreCase)
            || n.Contains(@"\.git\", StringComparison.OrdinalIgnoreCase)
            || n.Contains(@"\submodules\", StringComparison.OrdinalIgnoreCase);
    }

    public static string Rel(string root, string path) =>
        Path.GetRelativePath(root, path).Replace('\\', '/');

    public static IEnumerable<string> PackageReferences(string csprojPath)
    {
        XDocument xml;
        try
        {
            xml = XDocument.Load(csprojPath);
        }
        catch
        {
            yield break;
        }

        foreach (var el in xml.Descendants().Where(e => e.Name.LocalName == "PackageReference"))
        {
            var id = (string?)el.Attribute("Include") ?? (string?)el.Attribute("Update");
            if (!string.IsNullOrWhiteSpace(id))
                yield return id;
        }
    }

    public static string? ProjectProperty(string csprojPath, string name)
    {
        try
        {
            var xml = XDocument.Load(csprojPath);
            foreach (var el in xml.Descendants().Where(e => e.Name.LocalName == name))
            {
                var value = el.Value?.Trim();
                if (!string.IsNullOrWhiteSpace(value))
                    return value;
            }
        }
        catch
        {
            return null;
        }

        return null;
    }
}
