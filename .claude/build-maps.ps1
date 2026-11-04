# Wraps each textures/*.jpg|png as textures/js/<name>.js -> orreryMap("<name>", "data:...").
# The page loads maps through these scripts because Chrome won't let WebGL use image files when
# kbosmos.html is opened straight from disk (file://); <script> tags and data: images work there.
$root = Split-Path -Parent $PSScriptRoot
$out = Join-Path $root 'textures/js'
New-Item -ItemType Directory -Force $out | Out-Null
Get-ChildItem (Join-Path $root 'textures') -File | Where-Object { $_.Extension -in '.jpg', '.png' } | ForEach-Object {
  $mime = if ($_.Extension -eq '.png') { 'image/png' } else { 'image/jpeg' }
  $b64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes($_.FullName))
  $js = "orreryMap(`"$($_.BaseName)`", `"data:$mime;base64,$b64`");`n"
  [IO.File]::WriteAllText((Join-Path $out ($_.BaseName + '.js')), $js)
  Write-Host ("{0,-18} {1,8:N0} KB" -f ($_.BaseName + '.js'), ($js.Length / 1KB))
}
