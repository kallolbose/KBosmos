# Turns the downloaded moon maps (Wikimedia Commons; see the credits in kbosmos.html) into clean
# equirectangular textures in textures/<moon>.jpg: crops poster margins, reprojects Mercator,
# fills unmapped areas, resizes. Then run build-maps.ps1 to wrap them for the page.
#   powershell -File .claude/prep-moon-maps.ps1 <folder with the downloaded originals>
param([Parameter(Mandatory)] [string]$src)
$root = Split-Path -Parent $PSScriptRoot
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System; using System.Drawing; using System.Drawing.Imaging; using System.Drawing.Drawing2D;
using System.Runtime.InteropServices;
public static class MapPrep {
  public static int[] Px(Bitmap b) {
    var d = b.LockBits(new Rectangle(0, 0, b.Width, b.Height), ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb);
    var a = new int[b.Width * b.Height]; Marshal.Copy(d.Scan0, a, 0, a.Length); b.UnlockBits(d); return a;
  }
  public static Bitmap FromPx(int[] a, int w, int h) {
    var b = new Bitmap(w, h, PixelFormat.Format32bppArgb);
    var d = b.LockBits(new Rectangle(0, 0, w, h), ImageLockMode.WriteOnly, PixelFormat.Format32bppArgb);
    Marshal.Copy(a, 0, d.Scan0, a.Length); b.UnlockBits(d); return b;
  }
  static bool IsBg(int c, bool white, int t) {
    int r = (c >> 16) & 255, g = (c >> 8) & 255, bl = c & 255;
    return white ? (r > t && g > t && bl > t) : (r < t && g < t && bl < t);
  }
  // Crop to the map on a poster: map columns/rows are mostly non-background, margins and legends are not.
  public static Bitmap AutoCrop(Bitmap b, bool white, int t, int inset) {
    int w = b.Width, h = b.Height; var a = Px(b);
    int x0 = -1, x1 = -1, y0 = -1, y1 = -1;
    for (int x = 0; x < w; x++) { int n = 0; for (int y = 0; y < h; y++) if (!IsBg(a[y * w + x], white, t)) n++; if (n > h * 0.5) { if (x0 < 0) x0 = x; x1 = x; } }
    for (int y = 0; y < h; y++) { int n = 0; for (int x = x0; x <= x1; x++) if (!IsBg(a[y * w + x], white, t)) n++; if (n > (x1 - x0) * 0.6) { if (y0 < 0) y0 = y; y1 = y; } }
    return b.Clone(new Rectangle(x0 + inset, y0 + inset, x1 - x0 + 1 - 2 * inset, y1 - y0 + 1 - 2 * inset), PixelFormat.Format32bppArgb);
  }
  // Mercator (full width = 360°) to equirectangular; latitude limit read from the aspect ratio. Poles marked transparent.
  public static Bitmap MercatorToEquirect(Bitmap b, int outW) {
    int w = b.Width, h = b.Height, outH = outW / 2; var a = Px(b); var o = new int[outW * outH];
    for (int oy = 0; oy < outH; oy++) {
      double lat = (90 - (oy + 0.5) * 180.0 / outH) * Math.PI / 180;
      double sy = h / 2.0 - Math.Log(Math.Tan(Math.PI / 4 + lat / 2)) * w / (2 * Math.PI);
      for (int ox = 0; ox < outW; ox++) {
        int sx = Math.Min(w - 1, (int)((ox + 0.5) * w / outW)), iy = (int)sy;
        o[oy * outW + ox] = (iy >= 0 && iy < h) ? a[iy * w + sx] : 0;
      }
    }
    return FromPx(o, outW, outH);
  }
  // Fills unmapped pixels. Transparent pole bands (Mercator) get the average colour of the nearest mapped row, so
  // the poles shade smoothly. Near-black regions never imaged (blackIsHole) get one even average colour of the
  // whole mapped surface, since per-row averages there come out as uneven stripes.
  public static Bitmap FillHoles(Bitmap b, bool blackIsHole) {
    int w = b.Width, h = b.Height; var a = Px(b);
    Func<int, bool> hole = c => ((c >> 24) & 255) < 128 || (blackIsHole && ((c >> 16) & 255) < 10 && ((c >> 8) & 255) < 10 && (c & 255) < 10);
    if (blackIsHole) {
      long r = 0, g = 0, bl = 0, n = 0;
      foreach (int c in a) { if (hole(c)) continue; r += (c >> 16) & 255; g += (c >> 8) & 255; bl += c & 255; n++; }
      int mean = unchecked((int)0xFF000000) | (int)(r / n) << 16 | (int)(g / n) << 8 | (int)(bl / n);
      for (int i = 0; i < a.Length; i++) if (hole(a[i])) a[i] = mean;
      return FromPx(a, w, h);
    }
    var avg = new int[h]; var has = new bool[h];
    for (int y = 0; y < h; y++) {
      long r = 0, g = 0, bl = 0; int n = 0;
      for (int x = 0; x < w; x++) { int c = a[y * w + x]; if (hole(c)) continue; r += (c >> 16) & 255; g += (c >> 8) & 255; bl += c & 255; n++; }
      if (n > w / 20) { has[y] = true; avg[y] = unchecked((int)0xFF000000) | (int)(r / n) << 16 | (int)(g / n) << 8 | (int)(bl / n); }
    }
    for (int y = 0; y < h; y++) {
      int fill = 0;
      for (int d = 0; d < h && fill == 0; d++) { if (y - d >= 0 && has[y - d]) fill = avg[y - d]; else if (y + d < h && has[y + d]) fill = avg[y + d]; }
      for (int x = 0; x < w; x++) if (hole(a[y * w + x])) a[y * w + x] = fill;
    }
    return FromPx(a, w, h);
  }
  public static Bitmap Resize(Bitmap b, int w, int h) {
    var o = new Bitmap(w, h, PixelFormat.Format24bppRgb);
    using (var g = Graphics.FromImage(o)) { g.InterpolationMode = InterpolationMode.HighQualityBicubic; g.PixelOffsetMode = PixelOffsetMode.HighQuality; g.DrawImage(b, 0, 0, w, h); }
    return o;
  }
  public static void SaveJpeg(Bitmap b, string path, long q) {
    var enc = Array.Find(ImageCodecInfo.GetImageEncoders(), e => e.MimeType == "image/jpeg");
    var p = new EncoderParameters(1); p.Param[0] = new EncoderParameter(System.Drawing.Imaging.Encoder.Quality, q);
    b.Save(path, enc, p);
  }
}
'@

# name: source file, operation, output width
$jobs = @(
  @('io', 'io.jpg', 'plain', 1224), @('europa', 'europa.jpg', 'holes', 1024),
  @('ganymede', 'ganymede.jpg', 'mercator', 2048), @('callisto', 'callisto.jpg', 'holes', 1024),
  @('mimas', 'mimas.jpg', 'poster', 2048), @('enceladus', 'enceladus.jpg', 'poster', 2048),
  @('tethys', 'tethys.jpg', 'poster', 2048), @('dione', 'dione.jpg', 'poster', 2048),
  @('rhea', 'rhea.jpg', 'poster', 2048), @('iapetus', 'iapetus.jpg', 'poster', 2048),
  @('titan', 'titan.jpg', 'blackposter', 2048),
  @('phobos', 'phobos.jpg', 'plain', 1920), @('deimos', 'deimos.png', 'plain', 1024),
  @('miranda', 'miranda.jpg', 'holes', 1440), @('ariel', 'ariel.jpg', 'holes', 1440), @('umbriel', 'umbriel.jpg', 'holes', 1440),
  @('titania', 'titania.jpg', 'holes', 1440), @('oberon', 'oberon.jpg', 'holes', 1440),
  @('triton', 'triton.jpg', 'holes', 1920), @('charon', 'charon.jpg', 'holes', 1920)
)
foreach ($j in $jobs) {
  $name, $file, $op, $w = $j
  $img = New-Object System.Drawing.Bitmap (Join-Path $src $file)
  switch ($op) {
    'poster' { $img = [MapPrep]::AutoCrop($img, $true, 235, 4) }
    'blackposter' { $img = [MapPrep]::AutoCrop($img, $false, 20, 4) }
    'mercator' { $img = [MapPrep]::FillHoles([MapPrep]::MercatorToEquirect($img, $w), $false) }
    'holes' { $img = [MapPrep]::FillHoles($img, $true) }
  }
  $cropped = "{0}x{1}" -f $img.Width, $img.Height
  $out = [MapPrep]::Resize($img, $w, $w / 2)
  [MapPrep]::SaveJpeg($out, (Join-Path $root "textures/$name.jpg"), 85)
  Write-Host ("{0,-10} {1,-12} {2,-11} -> {3}x{4}  {5,6:N0} KB" -f $name, $op, $cropped, $w, ($w / 2), ((Get-Item (Join-Path $root "textures/$name.jpg")).Length / 1KB))
  $img.Dispose(); $out.Dispose()
}
