// Dump text + page PNG from a Norgeskart print PDF (bbox labels, scale).
//
//   dotnet run --file d:\novolis\novolis-governance\scripts\inspect-norgeskart-pdf.cs -- "C:\Users\frank\Downloads\norgeskart-utskrift.pdf"
//
#:project d:\novolis\novolis-pdf\src\Novolis.Pdf.Text\Novolis.Pdf.Text.csproj

using Novolis.Pdf.Abstractions;
using Novolis.Pdf.Parsing;
using Novolis.Pdf.Text;

if (args.Length == 0)
{
    Console.Error.WriteLine("Usage: inspect-norgeskart-pdf.cs <path-to.pdf> [png-out]");
    return 1;
}

var pdfPath = Path.GetFullPath(args[0]);
if (!File.Exists(pdfPath))
{
    Console.Error.WriteLine($"Not found: {pdfPath}");
    return 1;
}

await using var fs = new FileStream(
    pdfPath,
    new FileStreamOptions
    {
        Mode = FileMode.Open,
        Access = FileAccess.Read,
        Share = FileShare.ReadWrite | FileShare.Delete,
        Options = FileOptions.Asynchronous,
    });
var info = new FileInfo(pdfPath);
await using var source = new LocalPdfSource(fs, info);
var document = await PdfParser.ParseAsync(source);
var spans = new PdfTextExtractor().ExtractDocument(document);
var text = string.Concat(spans.Select(s => s.Text));
Console.WriteLine("--- extracted text ---");
Console.WriteLine(text);
Console.WriteLine("--- end ---");
return 0;

file sealed class LocalPdfSource : IPdfSource
{
    private readonly FileStream _stream;
    private readonly SemaphoreSlim _gate = new(1, 1);
    private bool _disposed;

    public LocalPdfSource(FileStream stream, FileInfo info)
    {
        _stream = stream;
        Descriptor = new PdfSourceDescriptor(info.Name, info.FullName, info.Length, info.LastWriteTimeUtc);
    }

    public PdfSourceDescriptor Descriptor { get; }

    public async ValueTask<int> ReadAtAsync(long offset, Memory<byte> buffer, CancellationToken cancellationToken = default)
    {
        ObjectDisposedException.ThrowIf(_disposed, this);
        await _gate.WaitAsync(cancellationToken).ConfigureAwait(false);
        try
        {
            _stream.Seek(offset, SeekOrigin.Begin);
            return await _stream.ReadAsync(buffer, cancellationToken).ConfigureAwait(false);
        }
        finally
        {
            _gate.Release();
        }
    }

    public ValueTask DisposeAsync()
    {
        if (_disposed)
            return ValueTask.CompletedTask;
        _disposed = true;
        _gate.Dispose();
        _stream.Dispose();
        return ValueTask.CompletedTask;
    }
}
