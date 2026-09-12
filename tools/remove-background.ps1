param(
    [Parameter(Mandatory = $true)]
    [string]$InputPath,

    [Parameter(Mandatory = $true)]
    [string]$OutputPath,

    [int]$Padding = 16
)

$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Drawing

if (-not ([System.Management.Automation.PSTypeName]'WhiteBackgroundRemover').Type) {
    Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.IO;
using System.Runtime.InteropServices;

public static class WhiteBackgroundRemover
{
    public static void Process(string inputPath, string outputPath, int padding)
    {
        using (var sourceImage = Image.FromFile(inputPath))
        using (var source = new Bitmap(sourceImage.Width, sourceImage.Height, PixelFormat.Format32bppArgb))
        {
            using (var graphics = Graphics.FromImage(source))
            {
                graphics.DrawImageUnscaled(sourceImage, 0, 0);
            }

            var rectangle = new Rectangle(0, 0, source.Width, source.Height);
            var data = source.LockBits(rectangle, ImageLockMode.ReadWrite, PixelFormat.Format32bppArgb);
            var bytes = Math.Abs(data.Stride) * data.Height;
            var pixels = new byte[bytes];
            Marshal.Copy(data.Scan0, pixels, 0, bytes);

            int left = source.Width;
            int top = source.Height;
            int right = -1;
            int bottom = -1;

            for (int y = 0; y < source.Height; y++)
            {
                for (int x = 0; x < source.Width; x++)
                {
                    int index = y * data.Stride + x * 4;
                    double blue = pixels[index];
                    double green = pixels[index + 1];
                    double red = pixels[index + 2];

                    double max = Math.Max(red, Math.Max(green, blue));
                    double min = Math.Min(red, Math.Min(green, blue));
                    double saturation = max - min;
                    double greenExcess = green - Math.Max(red, blue);

                    // Folhas e nervuras têm cromaticidade verde; o fundo e suas
                    // sombras são quase neutros. Combinar saturação e excesso de
                    // verde evita manter o halo cinza comum em fotos de catálogo.
                    double saturationAlpha = Clamp((saturation - 7.0) / 34.0);
                    double greenAlpha = Clamp((greenExcess - 1.0) / 24.0);
                    double alpha = Math.Max(saturationAlpha, greenAlpha);
                    alpha = alpha * alpha * (3.0 - 2.0 * alpha);

                    if (alpha < 0.07) alpha = 0.0;
                    if (alpha > 0.93) alpha = 1.0;

                    pixels[index] = (byte)Math.Round(blue);
                    pixels[index + 1] = (byte)Math.Round(green);
                    pixels[index + 2] = (byte)Math.Round(red);
                    pixels[index + 3] = (byte)Math.Round(alpha * 255.0);

                    if (pixels[index + 3] > 8)
                    {
                        if (x < left) left = x;
                        if (x > right) right = x;
                        if (y < top) top = y;
                        if (y > bottom) bottom = y;
                    }
                }
            }

            Marshal.Copy(pixels, 0, data.Scan0, bytes);
            source.UnlockBits(data);

            if (right < left || bottom < top)
                throw new InvalidOperationException("Nenhum objeto foi detectado na imagem.");

            left = Math.Max(0, left - padding);
            top = Math.Max(0, top - padding);
            right = Math.Min(source.Width - 1, right + padding);
            bottom = Math.Min(source.Height - 1, bottom + padding);

            var crop = new Rectangle(left, top, right - left + 1, bottom - top + 1);
            using (var result = source.Clone(crop, PixelFormat.Format32bppArgb))
            {
                string directory = Path.GetDirectoryName(outputPath);
                if (!String.IsNullOrEmpty(directory)) Directory.CreateDirectory(directory);
                result.Save(outputPath, ImageFormat.Png);
            }
        }
    }

    private static double Clamp(double value)
    {
        return Math.Max(0.0, Math.Min(1.0, value));
    }

}
'@
}

$resolvedInput = (Resolve-Path -LiteralPath $InputPath).Path
$outputFullPath = [System.IO.Path]::GetFullPath($OutputPath)
[WhiteBackgroundRemover]::Process($resolvedInput, $outputFullPath, $Padding)

Write-Output "Recorte salvo em: $outputFullPath"
