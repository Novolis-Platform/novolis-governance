using System.Diagnostics;
using System.Text.Json;

static class NovolisGpr
{
    public static void AssertGh()
    {
        if (RunGh("auth", "status") != 0)
            throw new InvalidOperationException("GitHub CLI (gh) is required. Install from https://cli.github.com/");
    }

    public static string AuthToken()
    {
        var (code, stdout, _) = CaptureGh("auth", "token");
        if (code != 0 || string.IsNullOrWhiteSpace(stdout))
            throw new InvalidOperationException("gh auth token failed. Run: gh auth login");
        return stdout.Trim();
    }

    public static List<JsonElement> ListPackages(string org)
    {
        var all = new List<JsonElement>();
        for (var page = 1; ; page++)
        {
            var (code, stdout, stderr) = CaptureGh("api", $"orgs/{org}/packages?package_type=nuget&per_page=100&page={page}");
            if (code != 0)
                throw new InvalidOperationException($"Failed to list packages for org {org} (page {page}): {stderr}");
            using var doc = JsonDocument.Parse(string.IsNullOrWhiteSpace(stdout) ? "[]" : stdout);
            var batch = doc.RootElement.EnumerateArray().Select(e => e.Clone()).ToList();
            if (batch.Count == 0)
                break;
            all.AddRange(batch);
            if (batch.Count < 100)
                break;
        }

        return all;
    }

    public static List<JsonElement> ListVersions(string org, string packageName)
    {
        var all = new List<JsonElement>();
        for (var page = 1; ; page++)
        {
            var (code, stdout, _) = CaptureGh("api", $"orgs/{org}/packages/nuget/{packageName}/versions?per_page=100&page={page}");
            if (code != 0)
                throw new InvalidOperationException($"Failed to list versions for {packageName} (page {page}).");
            using var doc = JsonDocument.Parse(string.IsNullOrWhiteSpace(stdout) ? "[]" : stdout);
            var batch = doc.RootElement.EnumerateArray().Select(e => e.Clone()).ToList();
            if (batch.Count == 0)
                break;
            all.AddRange(batch);
            if (batch.Count < 100)
                break;
        }

        return all;
    }

    public static bool IsJunkVersion(string version)
    {
        if (version == "1.0.0")
            return true;
        if (System.Text.RegularExpressions.Regex.IsMatch(version, @"^2026\.1\.(99|100)(\.|$)"))
            return true;
        var three = System.Text.RegularExpressions.Regex.Match(version, @"^2026\.1\.(\d+)$");
        return three.Success && int.Parse(three.Groups[1].Value) >= 90;
    }

    public static (int Exit, string Stdout, string Stderr) CaptureGh(params string[] arguments)
    {
        var psi = new ProcessStartInfo("gh")
        {
            RedirectStandardOutput = true,
            RedirectStandardError = true,
            UseShellExecute = false,
            CreateNoWindow = true,
        };
        foreach (var arg in arguments)
            psi.ArgumentList.Add(arg);
        using var p = Process.Start(psi) ?? throw new InvalidOperationException("Failed to start gh");
        var stdout = p.StandardOutput.ReadToEnd();
        var stderr = p.StandardError.ReadToEnd();
        p.WaitForExit();
        return (p.ExitCode, stdout, stderr);
    }

    public static int RunGh(params string[] arguments)
    {
        var psi = new ProcessStartInfo("gh")
        {
            RedirectStandardOutput = true,
            RedirectStandardError = true,
            UseShellExecute = false,
            CreateNoWindow = true,
        };
        foreach (var arg in arguments)
            psi.ArgumentList.Add(arg);
        using var p = Process.Start(psi) ?? throw new InvalidOperationException("Failed to start gh");
        p.StandardOutput.ReadToEnd();
        p.StandardError.ReadToEnd();
        p.WaitForExit();
        return p.ExitCode;
    }
}
