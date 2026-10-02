// Contract checks for the direct-release updater across manifest, workflow,
// composite action, and gated product smoke coverage.
using System.Text.Json.Nodes;

var workspace = FindWorkspace(Directory.GetCurrentDirectory());

var appsManifestPath = Path.Combine(workspace, "novolis-apps", "build", "apps.json");
var releaseWorkflowPath = Path.Combine(
    workspace,
    "novolis-workflows",
    ".github",
    "workflows",
    "apps-release.yml");
var publishActionPath = Path.Combine(
    workspace,
    "novolis-workflows",
    "actions",
    "publish-built-release",
    "action.yml");
var smokeProjectPath = Path.Combine(
    workspace,
    "novolis-apps",
    "tests",
    "Update.Smoke",
    "Update.Smoke.csproj");
var smokeTestsPath = Path.Combine(
    workspace,
    "novolis-apps",
    "tests",
    "Update.Smoke",
    "UpdateDeviceSmokeTests.cs");

var failures = new List<string>();

RequireFile(appsManifestPath);
RequireFile(releaseWorkflowPath);
RequireFile(publishActionPath);
RequireFile(smokeProjectPath);
RequireFile(smokeTestsPath);

if (failures.Count == 0)
{
    var apps = JsonNode.Parse(File.ReadAllText(appsManifestPath))?["apps"]?.AsArray()
        ?? throw new InvalidOperationException("apps.json does not contain apps.");
    var updateCount = 0;
    foreach (var app in apps)
    {
        var update = app?["update"];
        if (update?["enabled"]?.GetValue<bool>() != true)
            continue;

        updateCount++;
        RequireValue(update, "appId", "update.appId");
        RequireValue(update, "repository", "update.repository");
        RequireValue(update, "channel", "update.channel");
        var distribution = update?["distribution"]?.GetValue<string>();
        if (!string.Equals(distribution, "direct-github", StringComparison.Ordinal))
            failures.Add($"enabled update must be direct-github, found '{distribution}'.");
    }

    if (updateCount == 0)
        failures.Add("apps.json declares no enabled update identities.");
    else
        Console.WriteLine($"Checked {updateCount} enabled direct-release app identities.");
}

if (File.Exists(releaseWorkflowPath))
{
    var workflow = File.ReadAllText(releaseWorkflowPath);
    RequireText(workflow, "release_matrix", "release workflow must produce release metadata.");
    RequireText(workflow, "metadata-json:", "release workflow must pass update metadata.");
    RequireText(workflow, "publish-built-release@main", "release workflow must use publish action.");
}

if (File.Exists(publishActionPath))
{
    var action = File.ReadAllText(publishActionPath);
    RequireText(action, "metadata-json:", "publish action must require metadata-json.");
    RequireText(action, "Novolis.Update.json", "publish action must publish update metadata.");
    RequireText(action, "SHA256SUMS.txt", "publish action must publish checksums.");
    RequireText(action, "Get-FileHash", "publish action must hash release assets.");
    RequireText(action, "direct-github", "publish action must reject store-managed rows.");
    RequireText(action, "downloadUri", "publish action must emit verified download URLs.");
    RequireText(action, "catalog contract", "publish action must validate generated update metadata.");
    RequireText(action, "gh release create", "publish action must publish one release.");
}

if (File.Exists(smokeProjectPath))
{
    var project = File.ReadAllText(smokeProjectPath);
    RequireText(project, "IsTestingPlatformApplication>true", "smoke project must use MTP.");
    RequireText(project, "Appium.WebDriver", "smoke project must include Appium.");
}

if (File.Exists(smokeTestsPath))
{
    var smoke = File.ReadAllText(smokeTestsPath);
    RequireText(smoke, "NOVOLIS_UPDATE_WINDOWS_SMOKE", "Windows smoke gate is missing.");
    RequireText(smoke, "NOVOLIS_UPDATE_MAUI_WINDOWS_SMOKE", "MAUI Windows smoke gate is missing.");
    RequireText(smoke, "NOVOLIS_UPDATE_ANDROID_SMOKE", "Android smoke gate is missing.");
    RequireText(smoke, "StoreManaged", "store-managed smoke guard is missing.");
    RequireText(smoke, "UpdateStatusView", "update accessibility contract is missing.");
}

if (failures.Count != 0)
{
    Console.Error.WriteLine("Update pipeline contract failed:");
    foreach (var failure in failures)
        Console.Error.WriteLine($"- {failure}");
    return 1;
}

Console.WriteLine("Update pipeline contract passed.");
return 0;

void RequireFile(string path)
{
    if (!File.Exists(path))
        failures.Add($"required file is missing: {path}");
}

void RequireText(string text, string expected, string message)
{
    if (!text.Contains(expected, StringComparison.Ordinal))
        failures.Add(message);
}

void RequireValue(JsonNode? parent, string property, string name)
{
    var value = parent?[property]?.GetValue<string>();
    if (string.IsNullOrWhiteSpace(value))
        failures.Add($"{name} is required.");
}

static string FindWorkspace(string start)
{
    var directory = new DirectoryInfo(start);
    while (directory is not null)
    {
        if (Directory.Exists(Path.Combine(directory.FullName, "novolis-apps"))
            && Directory.Exists(Path.Combine(directory.FullName, "novolis-workflows"))
            && Directory.Exists(Path.Combine(directory.FullName, "novolis-governance")))
        {
            return directory.FullName;
        }

        directory = directory.Parent;
    }

    throw new DirectoryNotFoundException(
        "Run this verifier from inside the d:\\novolis workspace.");
}
