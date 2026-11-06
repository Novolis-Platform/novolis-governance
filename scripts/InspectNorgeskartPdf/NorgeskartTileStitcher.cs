using Novolis.Pdf.Abstractions;
using Novolis.Pdf.Rendering;
using Novolis.Pdf.Rendering.Skia;
using SkiaSharp;

namespace Novolis.Governance.InspectNorgeskartPdf;

/// <summary>Stitches Norgeskart LZW tiles; optional crop to map content (north-up raster).</summary>
public static class NorgeskartTileStitcher
{
    public static (byte[] Png, NorgeskartMapContentFrame FramePdf, int PixelWidth, int PixelHeight) StitchCropped(
        PdfPageRenderPlan plan,
        PdfPageInfo page,
        double dpi)
    {
        var frame = NorgeskartMapContentFrame.FromPlan(plan);
        var scale = dpi / 72d;
        var cropLeft = frame.Left * scale;
        var cropTop = (page.DisplayHeight - frame.Top) * scale;
        var cropWidth = frame.Width * scale;
        var cropHeight = frame.Height * scale;
        var pixelWidth = System.Math.Clamp((int)System.Math.Round(cropWidth), 1, 16_384);
        var pixelHeight = System.Math.Clamp((int)System.Math.Round(cropHeight), 1, 16_384);

        using var full = StitchFullPage(plan, page, dpi);
        using var cropped = new SKBitmap(pixelWidth, pixelHeight, SKColorType.Rgba8888, SKAlphaType.Premul);
        using (var canvas = new SKCanvas(cropped))
        {
            canvas.Clear(SKColors.White);
            var src = SKRect.Create((float)cropLeft, (float)cropTop, (float)cropWidth, (float)cropHeight);
            var dest = SKRect.Create(0, 0, pixelWidth, pixelHeight);
            canvas.DrawBitmap(full, src, dest, new SKSamplingOptions(SKFilterMode.Linear));
        }

        using var encoded = SKImage.FromBitmap(cropped).Encode(SKEncodedImageFormat.Png, 92);
        return (encoded.ToArray(), frame, pixelWidth, pixelHeight);
    }

    internal static byte[] Stitch(PdfPageRenderPlan plan, PdfPageInfo page, double dpi)
    {
        using var full = StitchFullPage(plan, page, dpi);
        using var encoded = SKImage.FromBitmap(full).Encode(SKEncodedImageFormat.Png, 92);
        return encoded.ToArray();
    }

    private static SKBitmap StitchFullPage(PdfPageRenderPlan plan, PdfPageInfo page, double dpi)
    {
        var scale = dpi / 72d;
        var width = System.Math.Clamp((int)System.Math.Ceiling(page.DisplayWidth * scale), 1, 16_384);
        var height = System.Math.Clamp((int)System.Math.Ceiling(page.DisplayHeight * scale), 1, 16_384);
        var bitmap = new SKBitmap(width, height, SKColorType.Rgba8888, SKAlphaType.Premul);
        using (var canvas = new SKCanvas(bitmap))
        {
            canvas.Clear(SKColors.White);
            var seen = new HashSet<string>();
            foreach (var command in plan.Commands)
            {
                if (command is not PdfImageCommand image)
                    continue;

                var m = image.Matrix;
                var key = $"{image.Width}x{image.Height}:{m.E:F2}:{m.F:F2}:{m.A:F2}:{m.D:F2}";
                if (!seen.Add(key))
                    continue;

                var destLeft = m.E * scale;
                var destWidth = m.A * scale;
                var destHeight = m.D * scale;
                var destTop = (page.DisplayHeight - m.F - m.D) * scale;

                using var tile = PdfSkiaImageDecoder.Decode(image);
                var dest = SKRect.Create((float)destLeft, (float)destTop, (float)destWidth, (float)destHeight);
                canvas.DrawBitmap(tile, dest, new SKSamplingOptions(SKFilterMode.Linear));
            }
        }

        return bitmap;
    }
}
