Add-Type -AssemblyName System.Drawing

$root = Split-Path -Parent $PSScriptRoot
$outDir = Join-Path $root "docs"
$pngPath = Join-Path $outDir "kinesentry_component_architecture.png"
$jpgPath = Join-Path $outDir "kinesentry_component_architecture.jpg"

$width = 2400
$height = 1500

$bmp = New-Object System.Drawing.Bitmap $width, $height
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit

function Brush-Hex($hex) {
  New-Object System.Drawing.SolidBrush ([System.Drawing.ColorTranslator]::FromHtml($hex))
}

function Pen-Hex($hex, $width = 2) {
  New-Object System.Drawing.Pen ([System.Drawing.ColorTranslator]::FromHtml($hex), $width)
}

function RoundRect-Path([float]$x, [float]$y, [float]$w, [float]$h, [float]$r) {
  $path = New-Object System.Drawing.Drawing2D.GraphicsPath
  $d = $r * 2
  $path.AddArc($x, $y, $d, $d, 180, 90)
  $path.AddArc($x + $w - $d, $y, $d, $d, 270, 90)
  $path.AddArc($x + $w - $d, $y + $h - $d, $d, $d, 0, 90)
  $path.AddArc($x, $y + $h - $d, $d, $d, 90, 90)
  $path.CloseFigure()
  return $path
}

function Draw-Panel($title, $x, $y, $w, $h, $fill, $stroke) {
  $brush = Brush-Hex $fill
  $pen = Pen-Hex $stroke 3
  $path = RoundRect-Path $x $y $w $h 26
  $g.FillPath($brush, $path)
  $g.DrawPath($pen, $path)

  $font = New-Object System.Drawing.Font("Segoe UI", 22, [System.Drawing.FontStyle]::Bold)
  $textBrush = Brush-Hex "#0F172A"
  $g.DrawString($title, $font, $textBrush, $x + 18, $y + 12)
}

function Draw-Box($title, $items, $x, $y, $w, $h, $fill, $stroke) {
  $shadow = Brush-Hex "#12000000"
  $shadowPath = RoundRect-Path ($x + 5) ($y + 7) $w $h 18
  $g.FillPath($shadow, $shadowPath)

  $brush = Brush-Hex $fill
  $pen = Pen-Hex $stroke 2.2
  $path = RoundRect-Path $x $y $w $h 18
  $g.FillPath($brush, $path)
  $g.DrawPath($pen, $path)

  $titleFont = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
  $bodyFont = New-Object System.Drawing.Font("Segoe UI", 11)
  $titleBrush = Brush-Hex "#111827"
  $bodyBrush = Brush-Hex "#475569"

  $g.DrawString($title, $titleFont, $titleBrush, $x + 14, $y + 12)

  $lineY = $y + 42
  foreach ($item in $items) {
    $g.FillEllipse((Brush-Hex $stroke), $x + 15, $lineY + 6, 7, 7)
    $rect = New-Object System.Drawing.RectangleF ($x + 30), $lineY, ($w - 40), 32
    $g.DrawString($item, $bodyFont, $bodyBrush, $rect)
    $lineY += 31
  }
}

function Draw-Arrow($x1, $y1, $x2, $y2, $color, $label, $dashed = $false) {
  $pen = Pen-Hex $color 4
  if ($dashed) {
    $pen.DashStyle = [System.Drawing.Drawing2D.DashStyle]::Dash
  }
  $cap = New-Object System.Drawing.Drawing2D.AdjustableArrowCap 6, 8, $true
  $pen.CustomEndCap = $cap
  $g.DrawLine($pen, $x1, $y1, $x2, $y2)

  if ($label) {
    $font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
    $brush = Brush-Hex "#FFFFFF"
    $textBrush = Brush-Hex "#111827"
    $size = $g.MeasureString($label, $font)
    $bx = (($x1 + $x2) / 2) - ($size.Width / 2) - 10
    $by = (($y1 + $y2) / 2) - 20
    $path = RoundRect-Path $bx $by ($size.Width + 20) 32 10
    $g.FillPath($brush, $path)
    $g.DrawPath((Pen-Hex "#CBD5E1" 1.5), $path)
    $g.DrawString($label, $font, $textBrush, $bx + 10, $by + 6)
  }
}

$g.Clear([System.Drawing.ColorTranslator]::FromHtml("#F8FAFC"))
$g.FillEllipse((Brush-Hex "#E0F2FE"), -180, -60, 880, 420)
$g.FillEllipse((Brush-Hex "#F3E8FF"), 1750, 1080, 760, 360)

$headerFont = New-Object System.Drawing.Font("Segoe UI", 30, [System.Drawing.FontStyle]::Bold)
$subFont = New-Object System.Drawing.Font("Segoe UI", 13)
$g.DrawString("KineSentry Component and Data Architecture", $headerFont, (Brush-Hex "#0F172A"), 60, 28)
$g.DrawString("Section 5.1 view: components, sub-components, and end-to-end data connections", $subFont, (Brush-Hex "#475569"), 64, 82)

Draw-Panel "1. Wearable Smart Glove Unit" 50 140 520 1120 "#EFF6FF" "#60A5FA"
Draw-Panel "2. ESP32 Hub Unit" 640 140 520 1120 "#ECFDF5" "#4ADE80"
Draw-Panel "3. Flutter Mobile Application" 1230 140 560 1120 "#FAF5FF" "#C084FC"
Draw-Panel "4. Data Processing and Insight Layer" 1860 140 490 1120 "#FFF7ED" "#FB923C"

Draw-Box "Vital Sign Acquisition" @(
  "MAX30102 for Heart Rate",
  "MAX30102 for SpO2",
  "LM35 for Body Temperature"
) 85 220 450 150 "#FFF7E6" "#F59E0B"

Draw-Box "Motion Detection" @(
  "MPU6050 accelerometer and gyroscope",
  "Gesture recognition logic",
  "Fall detection logic"
) 85 410 450 150 "#FFF7E6" "#F59E0B"

Draw-Box "ESP32 Glove Controller" @(
  "Reads sensor values",
  "Builds outgoing data packet",
  "Controls local responses",
  "Sends data to hub using ESP-NOW"
) 85 600 450 180 "#DBEAFE" "#2563EB"

Draw-Box "Local User Feedback" @(
  "OLED health values display",
  "Buzzer feedback",
  "Status LED indication"
) 85 825 450 140 "#DCFCE7" "#16A34A"

Draw-Box "Power and Battery" @(
  "Battery level estimation",
  "Power state tracking",
  "Deep sleep capable operation"
) 85 1005 450 140 "#DCFCE7" "#16A34A"

Draw-Box "Communication Bridge" @(
  "ESP32 hub receives ESP-NOW packets",
  "BLE sends live data to mobile app",
  "Maintains glove to app link"
) 675 220 450 150 "#DBEAFE" "#2563EB"

Draw-Box "Connection Monitoring" @(
  "Checks glove link status",
  "Checks BLE client connection",
  "Keeps local device state updated"
) 675 410 450 150 "#E8F7EE" "#22C55E"

Draw-Box "Visual and Audible Indicators" @(
  "OLED summary display",
  "Connection LED",
  "Gesture LED",
  "Fall alert LED",
  "Buzzer warning output"
) 675 600 450 180 "#E8F7EE" "#22C55E"

Draw-Box "Device Coordination" @(
  "Receives app commands",
  "Synchronizes sleep mode",
  "Forwards control state to glove"
) 675 825 450 140 "#E8F7EE" "#22C55E"

Draw-Box "Local Status Interface" @(
  "Shows BPM, SpO2, Temperature",
  "Shows battery and connection state",
  "Works even without checking phone"
) 675 1005 450 140 "#FFFFFF" "#94A3B8"

Draw-Box "User Access" @(
  "Login and authenticated access",
  "Session handling",
  "Logout support"
) 1265 220 250 130 "#F3E8FF" "#9333EA"

Draw-Box "Bluetooth Module" @(
  "Scan for ESP32 hub",
  "Connect and disconnect",
  "Read notifications",
  "Send commands"
) 1530 220 225 150 "#F3E8FF" "#9333EA"

Draw-Box "Live Dashboard" @(
  "Vitals cards",
  "Fall and gesture status",
  "Battery and connection state",
  "Recent graphs"
) 1265 410 250 150 "#F3E8FF" "#9333EA"

Draw-Box "Alerts Interface" @(
  "Critical event visibility",
  "Caregiver facing alerts",
  "Notification support"
) 1530 410 225 150 "#F3E8FF" "#9333EA"

Draw-Box "Reports Module" @(
  "Session report",
  "Hourly report",
  "Daily report",
  "View and download"
) 1265 620 250 150 "#F3E8FF" "#9333EA"

Draw-Box "Settings and Controls" @(
  "Deep sleep synchronization",
  "Bluetooth options",
  "App level control settings"
) 1530 620 225 150 "#F3E8FF" "#9333EA"

Draw-Box "Health Rule Evaluation" @(
  "Stable classification",
  "Warning classification",
  "Critical classification"
) 1895 220 420 140 "#FFF1E6" "#EA580C"

Draw-Box "History Tracking" @(
  "Latest reading store",
  "Session history",
  "Recent graph history",
  "Alert history"
) 1895 395 420 150 "#FFF1E6" "#EA580C"

Draw-Box "Insight Generation" @(
  "Summary health observations",
  "Trend based interpretation",
  "Simple ML style scoring"
) 1895 585 420 140 "#FFF1E6" "#EA580C"

Draw-Box "Report Preparation" @(
  "Structured PDF data",
  "Stored report records",
  "Downloadable summaries"
) 1895 760 420 140 "#FFF1E6" "#EA580C"

Draw-Box "Session Management" @(
  "Active monitoring sessions",
  "Report history control",
  "Monitoring lifecycle flow"
) 1895 935 420 140 "#FFF1E6" "#EA580C"

Draw-Arrow 310 370 310 410 "#F59E0B" ""
Draw-Arrow 310 560 310 600 "#2563EB" ""
Draw-Arrow 310 780 310 825 "#16A34A" ""
Draw-Arrow 310 780 310 1005 "#16A34A" ""

Draw-Arrow 535 690 675 295 "#0EA5E9" "ESP-NOW Health Packet"
Draw-Arrow 1125 295 1530 295 "#7C3AED" "BLE Live Data"
Draw-Arrow 1530 705 1125 895 "#EC4899" "Control Commands" $true
Draw-Arrow 675 895 535 1075 "#22C55E" "Sleep Sync" $true

Draw-Arrow 1755 295 1895 285 "#F97316" "Parsed Values"
Draw-Arrow 1515 485 1895 470 "#F97316" "Events and State"
Draw-Arrow 1515 695 1895 830 "#F97316" "Report Requests"
Draw-Arrow 2105 360 1390 485 "#FB923C" "Status / Insight"
Draw-Arrow 2105 830 1390 695 "#FB923C" "Report Output"
Draw-Arrow 2105 1010 1645 695 "#FB923C" "Session Context"

$legendX = 70
$legendY = 1300
$legendFont = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$g.DrawString("Data Flow:", $legendFont, (Brush-Hex "#0F172A"), $legendX, $legendY)
$g.DrawString("Glove Sensors -> ESP32 Glove -> ESP-NOW -> ESP32 Hub -> BLE -> Flutter App -> Processing / Reports", (New-Object System.Drawing.Font("Segoe UI", 11)), (Brush-Hex "#334155"), $legendX + 95, $legendY + 1)
$g.DrawString("Control Flow:", $legendFont, (Brush-Hex "#0F172A"), $legendX, $legendY + 34)
$g.DrawString("Flutter Settings / Commands -> Hub -> Sleep / State Coordination -> Glove", (New-Object System.Drawing.Font("Segoe UI", 11)), (Brush-Hex "#334155"), $legendX + 105, $legendY + 35)

$pngCodec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq "image/png" }
$jpgCodec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq "image/jpeg" }

$pngParams = New-Object System.Drawing.Imaging.EncoderParameters 1
$pngParams.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter ([System.Drawing.Imaging.Encoder]::ColorDepth), 32L

$jpgParams = New-Object System.Drawing.Imaging.EncoderParameters 1
$jpgParams.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter ([System.Drawing.Imaging.Encoder]::Quality), 92L

$bmp.Save($pngPath, $pngCodec, $pngParams)
$bmp.Save($jpgPath, $jpgCodec, $jpgParams)

$g.Dispose()
$bmp.Dispose()

Write-Output "Created:"
Write-Output $pngPath
Write-Output $jpgPath
