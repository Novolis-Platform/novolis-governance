#:property TargetFramework=net10.0
#:property PublishAot=false
#:property PackAsTool=false
#:property ImplicitUsings=enable
#:property Nullable=enable

using System.Diagnostics;

var canvas = args.Length > 0
    ? args[0]
    : Path.Combine(
        Environment.GetFolderPath(Environment.SpecialFolder.UserProfile),
        ".cursor", "projects", "d-novolis", "canvases", "calypso-functional-vessel.canvas.tsx");

var project = @"d:\novolis\novolis-lab\labs\cad\CalypsoCad\CalypsoCad.csproj";
var psi = new ProcessStartInfo("dotnet")
{
    Arguments = $"run --project \"{project}\" -p:NovolisUseProjectReferences=true -- --emit-functional-canvas \"{canvas}\"",
    RedirectStandardOutput = true,
    RedirectStandardError = true,
    UseShellExecute = false,
    CreateNoWindow = true,
};
using var proc = Process.Start(psi) ?? throw new InvalidOperationException("Failed to start dotnet.");
var stdout = proc.StandardOutput.ReadToEnd();
var stderr = proc.StandardError.ReadToEnd();
proc.WaitForExit();
if (!string.IsNullOrWhiteSpace(stdout))
    Console.Write(stdout);
if (!string.IsNullOrWhiteSpace(stderr))
    Console.Error.Write(stderr);
Environment.Exit(proc.ExitCode);
