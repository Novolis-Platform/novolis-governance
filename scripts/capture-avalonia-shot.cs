// Opens an Avalonia host with the UI agent and writes one window PNG.
//
//   dotnet run --file d:\novolis\novolis-governance\scripts\capture-avalonia-shot.cs -- --endpoint novolis-avalonia-agent-sketch --output d:\novolis\frankhaugen-com\wwwroot\media\sketch-studio.png -- d:\path\SketchStudio.exe

#:property TargetFramework=net10.0
#:property PublishAot=false
#:property PackAsTool=false
#:property ImplicitUsings=enable
#:property Nullable=enable
#:property ManagePackageVersionsCentrally=false

#:package Novolis.Avalonia.Agent.Protocol@2026.1.*
#:package Novolis.Transports.LocalIpc@2026.1.*

using System.Diagnostics;
using System.Text;
using Novolis.Avalonia.Agent.Protocol;
using Novolis.Transports.LocalIpc;

var endpoint = Arg(args, "--endpoint");
var output = Arg(args, "--output");
var settle = int.TryParse(Arg(args, "--settle-ms"), out var settleMs) ? settleMs : 2500;
var waitSec = int.TryParse(Arg(args, "--wait-sec"), out var waitParsed) ? waitParsed : 90;
var split = Array.IndexOf(args, "--");
if (string.IsNullOrWhiteSpace(endpoint) || string.IsNullOrWhiteSpace(output) || split < 0 || split >= args.Length - 1)
{
    Console.Error.WriteLine("usage: capture-avalonia-shot --endpoint PIPE --output FILE.png [--settle-ms N] [--wait-sec N] -- EXE [ARGS...]");
    return 2;
}

var exe = args[split + 1];
var exeArgs = args[(split + 2)..];
Directory.CreateDirectory(Path.GetDirectoryName(Path.GetFullPath(output))!);

var psi = new ProcessStartInfo(exe)
{
    WorkingDirectory = Path.GetDirectoryName(Path.GetFullPath(exe))!,
    UseShellExecute = false,
    CreateNoWindow = true,
    RedirectStandardOutput = true,
    RedirectStandardError = true,
};
foreach (var arg in exeArgs)
    psi.ArgumentList.Add(arg);
psi.Environment["NOVOLIS_AVALONIA_AGENT"] = "1";
psi.Environment["NOVOLIS_AVALONIA_AGENT_ENDPOINT"] = endpoint;

using var process = Process.Start(psi) ?? throw new InvalidOperationException($"Failed to start {exe}");
var log = new StringBuilder();
process.OutputDataReceived += (_, e) => { if (e.Data is not null) log.AppendLine(e.Data); };
process.ErrorDataReceived += (_, e) => { if (e.Data is not null) log.AppendLine(e.Data); };
process.BeginOutputReadLine();
process.BeginErrorReadLine();

try
{
    await using var client = new UiAgentClient();
    var pipe = new LocalIpcEndpoint(endpoint, LocalIpcTransportKind.NamedPipe);
    Exception? last = null;
    var deadline = DateTime.UtcNow.AddSeconds(waitSec);
    while (DateTime.UtcNow < deadline)
    {
        if (process.HasExited)
        {
            Console.Error.WriteLine($"Host exited {process.ExitCode} before the agent pipe opened.");
            Console.Error.WriteLine(Tail(log));
            return 3;
        }

        try
        {
            using var connect = new CancellationTokenSource(TimeSpan.FromSeconds(2));
            await client.ConnectAsync(pipe, connect.Token).ConfigureAwait(false);
            last = null;
            break;
        }
        catch (Exception ex)
        {
            last = ex;
            await Task.Delay(300).ConfigureAwait(false);
        }
    }

    if (!client.IsConnected)
    {
        Console.Error.WriteLine($"No agent on {endpoint}: {last?.Message}");
        Console.Error.WriteLine(Tail(log));
        return 4;
    }

    var hello = await client.HelloAsync().ConfigureAwait(false);
    Console.WriteLine($"hello ok={hello.Success} title={hello.AppTitle} pid={hello.ProcessId}");
    if (!hello.Success)
    {
        Console.Error.WriteLine(hello.Error);
        return 5;
    }

    if (settle > 0)
        await Task.Delay(settle).ConfigureAwait(false);

    var shot = await client.ScreenshotAsync(maxWidth: 1600).ConfigureAwait(false);
    if (!shot.Success || shot.Png is not { Length: > 32 })
    {
        Console.Error.WriteLine(shot.Error ?? "screenshot failed");
        return 6;
    }

    await File.WriteAllBytesAsync(output, shot.Png).ConfigureAwait(false);
    Console.WriteLine($"SHOT {shot.Width}x{shot.Height} {output} ({shot.Png.Length} bytes)");
    return 0;
}
finally
{
    if (!process.HasExited)
    {
        process.Kill(entireProcessTree: true);
        process.WaitForExit(5000);
    }
}

static string? Arg(string[] args, string name)
{
    var index = Array.IndexOf(args, name);
    return index >= 0 && index + 1 < args.Length ? args[index + 1] : null;
}

static string Tail(StringBuilder log)
{
    var text = log.ToString();
    return text.Length <= 4000 ? text : text[^4000..];
}
