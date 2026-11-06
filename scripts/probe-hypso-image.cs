#:package SkiaSharp@3.116.1
#:property TargetFramework=net10.0

using SkiaSharp;

var path = args.Length > 0 ? args[0] : @"d:\novolis\novolis-lab\artifacts\hypso-extract\img-0.jpg";
using var bitmap = SKBitmap.Decode(path);
Console.WriteLine($"{path}: {bitmap.Width}x{bitmap.Height}");
var samples = new (int x, int y)[]
{
    (bitmap.Width / 2, bitmap.Height / 2),
    (bitmap.Width / 4, bitmap.Height / 4),
    (bitmap.Width * 3 / 4, bitmap.Height / 4),
    (100, 100),
    (bitmap.Width - 100, bitmap.Height - 100),
};
foreach (var (x, y) in samples)
{
    var c = bitmap.GetPixel(x, y);
    Console.WriteLine($"  ({x},{y}) R={c.Red} G={c.Green} B={c.Blue} A={c.Alpha}");
}
