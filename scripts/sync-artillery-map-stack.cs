// Prefer the ArtillerySimulator workflow script:
//   dotnet run --file d:\novolis\novolis-lab\labs\simulation\ArtillerySimulator\scripts\build-kristiansand-map.cs -p:NovolisUseProjectReferences=true
#:property TargetFramework=net10.0
#:property PublishAot=false
#:property ImplicitUsings=enable

using System.Diagnostics;

return Forward(
    @"d:\novolis\novolis-lab\labs\simulation\ArtillerySimulator\scripts\build-kristiansand-map.cs",
    args);

static int Forward(string target, string[] args)
{
    Console.WriteLine($"Forwarding to {target}");
    var psi = new ProcessStartInfo("dotnet")
    {
        UseShellExecute = false,
        CreateNoWindow = true,
        RedirectStandardOutput = true,
        RedirectStandardError = true,
    };
    psi.ArgumentList.Add("run");
    psi.ArgumentList.Add("--file");
    psi.ArgumentList.Add(target);
    psi.ArgumentList.Add("-p:NovolisUseProjectReferences=true");
    psi.ArgumentList.Add("--");
    foreach (var a in args)
        psi.ArgumentList.Add(a);

    using var proc = Process.Start(psi) ?? throw new InvalidOperationException("Failed to start dotnet.");
    Console.Write(proc.StandardOutput.ReadToEnd());
    Console.Error.Write(proc.StandardError.ReadToEnd());
    proc.WaitForExit();
    return proc.ExitCode;
}
