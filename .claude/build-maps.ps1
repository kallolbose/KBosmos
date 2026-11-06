# Wraps each textures/*.jpg|png as textures/js/<name>.js -> orreryMap("<name>", "data:...").
# The page loads maps through these scripts because Chrome won't let WebGL use image files when
# kbosmos.html is opened straight from disk (file://); <script> tags and data: images work there.
# It also writes 1024 px copies to textures/js/sm/, which phones and tablets load instead (smaller download and
# GPU memory). Run it with Windows PowerShell (System.Drawing does the resizing).
Add-Type -AssemblyName System.Drawing
$root = Split-Path -Parent $PSScriptRoot
$out = Join-Path $root 'textures/js'
$sm = Join-Path $out 'sm'
New-Item -ItemType Directory -Force $out, $sm | Out-Null
$jpeg = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq 'image/jpeg' }
$q = New-Object System.Drawing.Imaging.EncoderParameters 1
$q.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter ([System.Drawing.Imaging.Encoder]::Quality), 85L
function Write-Map($dir, $name, $mime, [byte[]]$bytes) {
  $js = "orreryMap(`"$name`", `"data:$mime;base64,$([Convert]::ToBase64String($bytes))`");`n"
  [IO.File]::WriteAllText((Join-Path $dir ($name + '.js')), $js)
  return $js.Length
}
Get-ChildItem (Join-Path $root 'textures') -File | Where-Object { $_.Extension -in '.jpg', '.png' } | ForEach-Object {
  $png = $_.Extension -eq '.png'
  $mime = if ($png) { 'image/png' } else { 'image/jpeg' }
  $full = Write-Map $out $_.BaseName $mime ([IO.File]::ReadAllBytes($_.FullName))
  # Small copy: at most 1024 px wide, same aspect ratio. PNGs stay PNG (Saturn's rings need their transparency).
  $img = [System.Drawing.Image]::FromFile($_.FullName)
  if ($img.Width -le 1024) { # already small: copy as is
    $img.Dispose(); $small = Write-Map $sm $_.BaseName $mime ([IO.File]::ReadAllBytes($_.FullName))
    Write-Host ("{0,-18} {1,8:N0} KB   small {2,6:N0} KB (copied)" -f ($_.BaseName + '.js'), ($full / 1KB), ($small / 1KB)); return
  }
  $w = 1024; $h = [int][Math]::Round($img.Height * $w / $img.Width)
  $bmp = New-Object System.Drawing.Bitmap $w, $h
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $g.DrawImage($img, 0, 0, $w, $h); $g.Dispose(); $img.Dispose()
  $ms = New-Object IO.MemoryStream
  if ($png) { $bmp.Save($ms, [System.Drawing.Imaging.ImageFormat]::Png) } else { $bmp.Save($ms, $jpeg, $q) }
  $bmp.Dispose()
  $small = Write-Map $sm $_.BaseName $mime $ms.ToArray()
  Write-Host ("{0,-18} {1,8:N0} KB   small {2,6:N0} KB" -f ($_.BaseName + '.js'), ($full / 1KB), ($small / 1KB))
}
