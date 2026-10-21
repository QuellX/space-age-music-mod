# Draws icon variants in a "shattered planet" style (a burst of red and dark rock shards around a glowing core)
# with a music note: dist\thumbnail-variant-<n>.png (1024x1024) and dist\thumbnail-variant-<n>-144.png.
# Original artwork drawn with GDI+, no game assets.
#
#   .\make-thumbnail-variants.ps1
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$S = 1024; $C = $S / 2
$dist = Join-Path $PSScriptRoot 'dist'
New-Item -ItemType Directory -Force $dist | Out-Null

function Color([string]$hex, [int]$alpha = 255) {
  $c = [Drawing.ColorTranslator]::FromHtml($hex); [Drawing.Color]::FromArgb($alpha, $c.R, $c.G, $c.B)
}
function PF([double]$x, [double]$y) { New-Object Drawing.PointF ([float]$x), ([float]$y) }

function Radial($g, [double]$x, [double]$y, [double]$r, [Drawing.Color]$inner, [Drawing.Color]$outer) {
  $p = New-Object Drawing.Drawing2D.GraphicsPath
  $p.AddEllipse([float]($x - $r), [float]($y - $r), [float](2 * $r), [float](2 * $r))
  $b = New-Object Drawing.Drawing2D.PathGradientBrush $p
  $b.CenterColor = $inner; $b.SurroundColors = [Drawing.Color[]]@($outer)
  $g.FillPath($b, $p)
}

# One rock shard: irregular polygon lit from the core side, with a lighter facet and a hot rim.
function Shard($g, $rnd, [double]$x, [double]$y, [double]$s, [bool]$crystal, [double]$cx, [double]$cy) {
  $n = $rnd.Next(5, 8); $rot = $rnd.NextDouble() * 6.28; $pts = @()
  for ($i = 0; $i -lt $n; $i++) {
    $a = $rot + $i * 6.283 / $n + ($rnd.NextDouble() - 0.5) * 0.6
    $rr = $s * (0.55 + $rnd.NextDouble() * 0.6) * $(if ($i % 2) { 1 } else { 1.25 })
    $pts += PF ($x + $rr * [Math]::Cos($a)) ($y + 0.8 * $rr * [Math]::Sin($a))
  }
  $path = New-Object Drawing.Drawing2D.GraphicsPath; $path.AddPolygon([Drawing.PointF[]]$pts)
  $dx = $cx - $x; $dy = $cy - $y; $d = [Math]::Max(1, [Math]::Sqrt($dx * $dx + $dy * $dy))
  $lit = PF ($x + $dx / $d * $s) ($y + $dy / $d * $s); $dark = PF ($x - $dx / $d * $s) ($y - $dy / $d * $s)
  $heat = [Math]::Max(0, 1 - $d / 470)  # closer to the core = hotter
  if ($crystal) { $c1 = Color $(if ($heat -gt 0.45) { '#ff7a3c' } else { '#e8342a' }); $c2 = Color '#3d0606' }
  else { $c1 = Color $(if ($heat -gt 0.45) { '#c7704f' } else { '#6e5560' }); $c2 = Color '#120d12' }
  $g.FillPath((New-Object Drawing.Drawing2D.LinearGradientBrush($lit, $dark, $c1, $c2)), $path)
  # facet: a lighter triangle from the centre to two neighbouring corners on the lit side
  $k = $rnd.Next($n)
  $facet = New-Object Drawing.Drawing2D.GraphicsPath
  $facet.AddPolygon([Drawing.PointF[]]@((PF $x $y), $pts[$k], $pts[($k + 1) % $n]))
  $g.FillPath((New-Object Drawing.SolidBrush (Color '#ffffff' 28)), $facet)
  $g.DrawPath((New-Object Drawing.Pen (Color '#ff9a50' ([int](60 + 150 * $heat))), ([float]([Math]::Max(2, $s / 14)))), $path)
}

# The burst: dark smoky halo, glowing core, then shards from far to near.
function Burst($g, [int]$seed, [double]$cx, [double]$cy, [double]$R, [int]$count, [double]$inner = 0.3) {
  Radial $g $cx $cy ($R * 1.15) (Color '#1a0d0d' 150) (Color '#000000' 0)
  Radial $g $cx $cy ($R * 0.75) (Color '#ffb070' 240) (Color '#ff3a12' 0)
  Radial $g $cx $cy ($R * 0.3) (Color '#fff0c0' 255) (Color '#ff8040' 0)
  $rnd = New-Object Random $seed
  $shards = @()
  for ($i = 0; $i -lt $count; $i++) {
    $a = $rnd.NextDouble() * 6.283
    $d = $R * ($inner + (1 - $inner) * [Math]::Sqrt($rnd.NextDouble()))
    $shards += ,@(($cx + $d * [Math]::Cos($a)), ($cy + 0.92 * $d * [Math]::Sin($a)), (12 + 48 * ($d / $R) * (0.6 + 0.6 * $rnd.NextDouble())), ($rnd.NextDouble() -lt 0.6), $rnd.NextDouble())
  }
  foreach ($sh in ($shards | Sort-Object { $_[4] })) { Shard $g $rnd $sh[0] $sh[1] $sh[2] $sh[3] $cx $cy }
}

# Two beamed eighth notes, centred on (x, y), scale 1 = about 500 px tall.
function NotePath([double]$x, [double]$y, [double]$k) {
  $p = New-Object Drawing.Drawing2D.GraphicsPath; $p.FillMode = 'Winding'
  foreach ($h in @(@(-145, 175), @(145, 95))) {
    $e = New-Object Drawing.Drawing2D.GraphicsPath; $e.AddEllipse(-78, -54, 156, 108)
    $m = New-Object Drawing.Drawing2D.Matrix; $m.Translate($h[0], $h[1]); $m.Rotate(-22); $e.Transform($m); $p.AddPath($e, $false)
  }
  $p.AddRectangle((New-Object Drawing.RectangleF -97, -270, 34, 445))
  $p.AddRectangle((New-Object Drawing.RectangleF 193, -360, 34, 445))
  $p.AddPolygon([Drawing.PointF[]]@((PF -97 -270), (PF 227 -360), (PF 227 -260), (PF -97 -170)))
  $m = New-Object Drawing.Drawing2D.Matrix; $m.Translate($x, $y); $m.Scale($k, $k); $p.Transform($m)
  $p
}
function Glow($g, $path, [string]$hex, [int]$steps, [double]$width) {
  for ($i = $steps; $i -ge 1; $i--) {
    $pen = New-Object Drawing.Pen (Color $hex ([int](70 / $steps + 6))), ([float]($width * $i / $steps)); $pen.LineJoin = 'Round'
    $g.DrawPath($pen, $path)
  }
}

function New-Canvas { $b = New-Object Drawing.Bitmap $S, $S; $g = [Drawing.Graphics]::FromImage($b); $g.SmoothingMode = 'AntiAlias'; $g.Clear([Drawing.Color]::Transparent); @($b, $g) }
function Save($b, [int]$n) {
  $b.Save((Join-Path $dist "thumbnail-variant-$n.png"), [Drawing.Imaging.ImageFormat]::Png)
  $s = New-Object Drawing.Bitmap 144, 144; $gs = [Drawing.Graphics]::FromImage($s)
  $gs.InterpolationMode = 'HighQualityBicubic'; $gs.PixelOffsetMode = 'HighQuality'; $gs.DrawImage($b, 0, 0, 144, 144); $gs.Dispose()
  $s.Save((Join-Path $dist "thumbnail-variant-$n-144.png"), [Drawing.Imaging.ImageFormat]::Png); $s.Dispose(); $b.Dispose()
}

# 1: sound waves: equalizer bars glowing in the core, sound-wave arcs rippling out between the shards
$b, $g = New-Canvas
Burst $g 11 $C $C 470 95 0.45
Radial $g $C $C 260 (Color '#fff4d0' 255) (Color '#ff7a30' 0)
foreach ($w in 1..3) {
  $r = 120 + 75 * $w
  $pen = New-Object Drawing.Pen (Color '#ffd890' ([int](230 - 50 * $w))), ([float](26 - 5 * $w)); $pen.StartCap = 'Round'; $pen.EndCap = 'Round'
  $g.DrawArc($pen, [float]($C - $r), [float]($C - $r), [float](2 * $r), [float](2 * $r), -40, 80)
  $g.DrawArc($pen, [float]($C - $r), [float]($C - $r), [float](2 * $r), [float](2 * $r), 140, 80)
}
$bars = @(70, 140, 220, 290, 220, 150, 90)
for ($i = 0; $i -lt $bars.Count; $i++) {
  $x = $C - 3 * 36 + $i * 36 - 13; $h = $bars[$i]
  $bar = New-Object Drawing.Drawing2D.GraphicsPath; $bar.AddRectangle((New-Object Drawing.RectangleF ([float]$x), ([float]($C - $h / 2)), 26, ([float]$h)))
  Glow $g $bar '#ff9a40' 5 40
  $g.FillPath((New-Object Drawing.Drawing2D.LinearGradientBrush((PF 0 ($C - 150)), (PF 0 ($C + 150)), (Color '#ffffff'), (Color '#ffc060'))), $bar)
}
$g.Dispose(); Save $b 1

# 2: vinyl: the planet is a cracked record, shards breaking off its rim
$b, $g = New-Canvas
Burst $g 23 $C $C 480 80 0.62
$disc = New-Object Drawing.Drawing2D.GraphicsPath; $disc.AddEllipse([float]($C - 270), [float]($C - 270), 540, 540)
Glow $g $disc '#ff6a20' 8 90
$g.FillPath((New-Object Drawing.Drawing2D.LinearGradientBrush((PF ($C - 270) ($C - 270)), (PF ($C + 270) ($C + 270)), (Color '#2a2226'), (Color '#050405'))), $disc)
foreach ($r in 255, 232, 210, 188, 166, 144, 122) {
  $g.DrawEllipse((New-Object Drawing.Pen (Color '#5a4a50' 120), 3), [float]($C - $r), [float]($C - $r), [float](2 * $r), [float](2 * $r))
}
$g.FillPie((New-Object Drawing.SolidBrush (Color '#ffffff' 30)), [float]($C - 260), [float]($C - 260), 520, 520, 200, 40)
Radial $g $C $C 95 (Color '#fff0b0') (Color '#ff5a1a')
$g.FillEllipse((New-Object Drawing.SolidBrush (Color '#1a0a0a')), [float]($C - 12), [float]($C - 12), 24, 24)
$crack = New-Object Drawing.Pen (Color '#ffc070' 240), 8; $crack.LineJoin = 'Round'
$g.DrawLines($crack, [Drawing.PointF[]]@((PF ($C + 60) ($C - 70)), (PF ($C + 120) ($C - 140)), (PF ($C + 110) ($C - 200)), (PF ($C + 190) ($C - 250))))
$g.DrawLines($crack, [Drawing.PointF[]]@((PF ($C - 70) ($C + 50)), (PF ($C - 150) ($C + 90)), (PF ($C - 190) ($C + 170)), (PF ($C - 250) ($C + 200))))
$g.Dispose(); Save $b 2

# 3: treble clef cracked into a dark planet, glowing from the core, shards breaking off the edge
$b, $g = New-Canvas
Burst $g 37 $C $C 480 70 0.75
$planet = New-Object Drawing.Drawing2D.GraphicsPath; $planet.AddEllipse([float]($C - 300), [float]($C - 300), 600, 600)
Glow $g $planet '#ff5a20' 8 80
$pb = New-Object Drawing.Drawing2D.PathGradientBrush $planet
$pb.CenterPoint = PF ($C - 100) ($C - 110); $pb.CenterColor = Color '#8a2a22'; $pb.SurroundColors = [Drawing.Color[]]@(Color '#160707')
$g.FillPath($pb, $planet)
$clef = New-Object Drawing.Drawing2D.GraphicsPath
$fmt = New-Object Drawing.StringFormat; $fmt.Alignment = 'Center'; $fmt.LineAlignment = 'Center'
$clef.AddString([char]::ConvertFromUtf32(0x1D11E), (New-Object Drawing.FontFamily 'Segoe UI Symbol'), 0, 620, (PF $C ($C + 40)), $fmt)
$bounds = $clef.GetBounds()
$m = New-Object Drawing.Drawing2D.Matrix; $m.Translate([float]($C - ($bounds.X + $bounds.Width / 2)), [float]($C - ($bounds.Y + $bounds.Height / 2))); $clef.Transform($m)
Glow $g $clef '#ff7a30' 8 60
$g.FillPath((New-Object Drawing.Drawing2D.LinearGradientBrush((PF 0 ($C - 300)), (PF 0 ($C + 300)), (Color '#fff6d8'), (Color '#ff9a3a'))), $clef)
$g.Dispose(); Save $b 3

# 4: a Gleba-style pentapod: a pale note-head body with glowing spots, a long neck as the stem with a fin as the
# flag, and five spindly jointed legs standing on shards of the broken planet
$b, $g = New-Canvas
Burst $g 51 ($C + 40) ($C + 60) 430 70 0.4
$bx = $C - 40; $by = $C + 120
$legPen = New-Object Drawing.Pen (Color '#c9cf8f'), 18; $legPen.StartCap = 'Round'; $legPen.EndCap = 'Round'; $legPen.LineJoin = 'Round'
$legOut = New-Object Drawing.Pen (Color '#20240f'), 30; $legOut.StartCap = 'Round'; $legOut.EndCap = 'Round'; $legOut.LineJoin = 'Round'
$legs = @(@(-150, -120, -320, 40, -360, 280), @(-60, -150, -180, -60, -220, 300), @(70, -150, 210, -50, 240, 300), @(150, -100, 340, 20, 380, 270), @(10, -170, 30, 20, 10, 310))
foreach ($pass in $legOut, $legPen) {
  foreach ($l in $legs) { $g.DrawLines($pass, [Drawing.PointF[]]@((PF ($bx + $l[0] * 0.3) $by), (PF ($bx + $l[0] + 0) ($by + $l[1])), (PF ($bx + $l[2]) ($by + $l[3])), (PF ($bx + $l[4]) ($by + $l[5])))) }
}
foreach ($l in $legs) { $g.FillEllipse((New-Object Drawing.SolidBrush (Color '#ff9a3a')), [float]($bx + $l[2] - 14), [float]($by + $l[3] - 14), 28, 28) }
# neck (stem) and fin (flag)
$neck = New-Object Drawing.Drawing2D.GraphicsPath
$neck.AddBezier((PF ($bx + 120) ($by - 20)), (PF ($bx + 170) ($by - 200)), (PF ($bx + 120) ($by - 380)), (PF ($bx + 190) ($by - 520)))
$g.DrawPath((New-Object Drawing.Pen (Color '#20240f'), 52), $neck)
$g.DrawPath((New-Object Drawing.Pen (Color '#d9dfa0'), 34), $neck)
$fin = New-Object Drawing.Drawing2D.GraphicsPath
$fin.AddBezier((PF ($bx + 190) ($by - 520)), (PF ($bx + 330) ($by - 470)), (PF ($bx + 360) ($by - 330)), (PF ($bx + 280) ($by - 250)))
$fin.AddBezier((PF ($bx + 280) ($by - 250)), (PF ($bx + 300) ($by - 340)), (PF ($bx + 250) ($by - 410)), (PF ($bx + 180) ($by - 430)))
$fin.CloseFigure()
$g.DrawPath((New-Object Drawing.Pen (Color '#20240f'), 18), $fin)
$g.FillPath((New-Object Drawing.Drawing2D.LinearGradientBrush((PF ($bx + 190) ($by - 520)), (PF ($bx + 290) ($by - 250)), (Color '#e8f0a0'), (Color '#8fa040'))), $fin)
# body (note head)
$body = New-Object Drawing.Drawing2D.GraphicsPath; $body.AddEllipse(-170, -115, 340, 230)
$m = New-Object Drawing.Drawing2D.Matrix; $m.Translate($bx, $by); $m.Rotate(-22); $body.Transform($m)
$g.DrawPath((New-Object Drawing.Pen (Color '#20240f'), 24), $body)
$pb = New-Object Drawing.Drawing2D.PathGradientBrush $body
$pb.CenterPoint = PF ($bx - 50) ($by - 50); $pb.CenterColor = Color '#f2f5c8'; $pb.SurroundColors = [Drawing.Color[]]@(Color '#7f9440')
$g.FillPath($pb, $body)
$g.SetClip($body)
foreach ($sp in @(@(-90, 20, 46, '#5f6e2c'), @(40, 50, 34, '#5f6e2c'), @(100, -30, 24, '#5f6e2c'), @(-20, -45, 22, '#ffb040'), @(60, -10, 18, '#ffb040'), @(-110, -30, 16, '#ffb040'))) {
  if ($sp[3] -eq '#ffb040') { Radial $g ($bx + $sp[0]) ($by + $sp[1]) ($sp[2] * 1.8) (Color '#ffe080') (Color '#ff8a20' 0) }
  $g.FillEllipse((New-Object Drawing.SolidBrush (Color $sp[3])), [float]($bx + $sp[0] - $sp[2] / 2), [float]($by + $sp[1] - $sp[2] / 2), [float]$sp[2], [float]$sp[2])
}
$g.ResetClip()
$g.Dispose(); Save $b 4

# Side-by-side preview on a dark background
$sheet = New-Object Drawing.Bitmap 1080, 1080; $gs = [Drawing.Graphics]::FromImage($sheet)
$gs.Clear((Color '#2a2a2e')); $gs.InterpolationMode = 'HighQualityBicubic'; $gs.TextRenderingHint = 'AntiAlias'
$font = New-Object Drawing.Font 'Segoe UI', 22, ([Drawing.FontStyle]::Bold)
for ($n = 1; $n -le 4; $n++) {
  $img = [Drawing.Image]::FromFile((Join-Path $dist "thumbnail-variant-$n.png"))
  $x = 20 + (($n - 1) % 2) * 530; $y = 20 + [Math]::Floor(($n - 1) / 2) * 530
  $gs.DrawImage($img, [float]$x, [float]$y, 510, 510); $img.Dispose()
  $gs.DrawString("$n", $font, (New-Object Drawing.SolidBrush (Color '#ffffff')), [float]($x + 8), [float]($y + 4))
}
$gs.Dispose(); $sheet.Save((Join-Path $dist 'thumbnail-variants.png'), [Drawing.Imaging.ImageFormat]::Png); $sheet.Dispose()
'variants written to ' + $dist

# 5: variant 3's treble clef over the game's own Shattered Planet icon (Wube artwork, read from the installed game)
$b, $g = New-Canvas
$g.InterpolationMode = 'HighQualityBicubic'
$bgImg = [Drawing.Image]::FromFile('E:\games\steam\steamapps\common\Factorio\data\space-age\graphics\icons\starmap-shattered-planet.png')
$g.DrawImage($bgImg, 0, 0, $S, $S); $bgImg.Dispose()
Radial $g $C $C 330 (Color '#1a0505' 150) (Color '#000000' 0)  # darken the middle so the clef stands out
$clef = New-Object Drawing.Drawing2D.GraphicsPath
$fmt = New-Object Drawing.StringFormat; $fmt.Alignment = 'Center'; $fmt.LineAlignment = 'Center'
$clef.AddString([char]::ConvertFromUtf32(0x1D11E), (New-Object Drawing.FontFamily 'Segoe UI Symbol'), 0, 680, (PF $C $C), $fmt)
$bounds = $clef.GetBounds()
$m = New-Object Drawing.Drawing2D.Matrix; $m.Translate([float]($C - ($bounds.X + $bounds.Width / 2)), [float]($C - ($bounds.Y + $bounds.Height / 2))); $clef.Transform($m)
Glow $g $clef '#ff7a30' 10 90
$outline = New-Object Drawing.Pen (Color '#1a0505'), 22; $outline.LineJoin = 'Round'
$g.DrawPath($outline, $clef)
$cb = $clef.GetBounds()
$g.FillPath((New-Object Drawing.Drawing2D.LinearGradientBrush((PF 0 ($cb.Top - 2)), (PF 0 ($cb.Bottom + 2)), (Color '#fffaf0'), (Color '#ffb050'))), $clef)
$g.Dispose(); Save $b 5
'variant 5 written'
