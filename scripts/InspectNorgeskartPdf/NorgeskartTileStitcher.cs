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
        using var croppedPdfSpace = new SKBitmap(pixelWidth, pixelHeight, SKColorType.Rgba8888, SKAlphaType.Premul);
        using (var canvas = new SKCanvas(croppedPdfSpace))
        {
            canvas.Clear(SKColors.White);
            // SKRect is (left, top, right, bottom) — not (left, top, width, height).
            var srcLeft = (float)cropLeft;
            var srcTop = (float)cropTop;
            var src = new SKRect(srcLeft, srcTop, srcLeft + (float)cropWidth, srcTop + (float)cropHeight);
            var dest = new SKRect(0, 0, pixelWidth, pixelHeight);
            canvas.DrawBitmap(full, src, dest, new SKSamplingOptions(SKFilterMode.Linear));
        }

        // PDF → bitmap uses a y-down image space for the crop; flip so row 0 = north (matches stack pixelOrigin topLeftNorthWest).
        using var cropped = FlipVertical(croppedPdfSpace);

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
            // Draw every image draw call. Norgeskart repeats identical raster payloads at different
            // CTMs; deduplicating by size + matrix (especially with rounded components) drops tiles and
            // produces holes or a wrong content bbox.
            foreach (var command in plan.Commands)
            {
                if (command is not PdfImageCommand image)
                    continue;

                var m = image.Matrix;
                var destLeft = m.E * scale;
                var destWidth = m.A * scale;
                var destHeight = m.D * scale;
                var destTop = (page.DisplayHeight - m.F - m.D) * scale;

                using var tile = PdfSkiaImageDecoder.Decode(image);
                var dl = (float)destLeft;
                var dt = (float)destTop;
                var dest = new SKRect(dl, dt, dl + (float)destWidth, dt + (float)destHeight);
                canvas.DrawBitmap(tile, dest, new SKSamplingOptions(SKFilterMode.Linear));
            }
        }

        return bitmap;
    }

    private static SKBitmap FlipVertical(SKBitmap src)
    {
        var w = src.Width;
        var h = src.Height;
        var dest = new SKBitmap(w, h, SKColorType.Rgba8888, SKAlphaType.Premul);
        using var canvas = new SKCanvas(dest);
        canvas.Clear(SKColors.White);
        canvas.Scale(1f, -1f);
        canvas.Translate(0, -h);
        canvas.DrawBitmap(src, 0, 0, new SKSamplingOptions(SKFilterMode.Linear));
        return dest;
    }
}
