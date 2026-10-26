// Regenerate CAL-DNV-REVIEW-001 (HTML + JSON manifest + optional headless annex PNGs).
if (args.Contains("--help") || args.Contains("-h"))
{
    Console.WriteLine("Usage: dotnet run --file Emit-CalypsoDnvReview.cs [--headless]");
    return;
}

var headless = args.Contains("--headless");
var project = @"d:\novolis\novolis-lab\labs\cad\CalypsoCad\CalypsoCad.csproj";
var psi = new System.Diagnostics.ProcessStartInfo("dotnet")
{
    WorkingDirectory = @"d:\novolis",
    RedirectStandardOutput = true,
    RedirectStandardError = true,
    UseShellExecute = false,
    CreateNoWindow = true,
};
psi.ArgumentList.Add("run");
psi.ArgumentList.Add("--project");
psi.ArgumentList.Add(project);
psi.ArgumentList.Add("-p:NovolisUseProjectReferences=true");
psi.ArgumentList.Add("--");
psi.ArgumentList.Add("--dnv-review");
if (headless)
    psi.ArgumentList.Add("--headless");

using var p = System.Diagnostics.Process.Start(psi)!;
var outText = await p.StandardOutput.ReadToEndAsync();
var errText = await p.StandardError.ReadToEndAsync();
await p.WaitForExitAsync();
Console.Write(outText);
if (!string.IsNullOrEmpty(errText))
    Console.Error.Write(errText);
Environment.ExitCode = p.ExitCode;
