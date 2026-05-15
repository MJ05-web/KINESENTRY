Add-Type -AssemblyName System.Drawing

$root = Split-Path -Parent $PSScriptRoot
$outDir = Join-Path $root "docs"
$pngPath = Join-Path $outDir "kinesentry_architecture.png"
$jpgPath = Join-Path $outDir "kinesentry_architecture.jpg"

$width = 2200
$height = 1400

$bmp = New-Object System.Drawing.Bitmap $width, $height
$graphics = [System.Drawing.Graphics]::FromImage($bmp)
$graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$graphics.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit

function New-Brush($hex) {
  return New-Object System.Drawing.SolidBrush ([System.Drawing.ColorTranslator]::FromHtml($hex))
}

function New-Pen($hex, $width = 2) {
  return New-Object System.Drawing.Pen ([System.Drawing.ColorTranslator]::FromHtml($hex), $width)
}

function Fill-RoundRect($g, $brush, [float]$x, [float]$y, [float]$w, [float]$h, [float]$r) {
  $path = New-Object System.Drawing.Drawing2D.GraphicsPath
  $d = $r * 2
  $path.AddArc($x, $y, $d, $d, 180, 90)
  $path.AddArc($x + $w - $d, $y, $d, $d, 270, 90)
  $path.AddArc($x + $w - $d, $y + $h - $d, $d, $d, 0, 90)
  $path.AddArc($x, $y + $h - $d, $d, $d, 90, 90)
  $path.CloseFigure()
  $g.FillPath($brush, $path)
  return $path
}

function Draw-Section($g, $title, $x, $y, $w, $h, $fill, $stroke) {
  $brush = New-Brush $fill
  $pen = New-Pen $stroke 3
  $path = Fill-RoundRect $g $brush $x $y $w $h 24
  $g.DrawPath($pen, $path)
  $titleFont = New-Object System.Drawing.Font("Segoe UI", 20, [System.Drawing.FontStyle]::Bold)
  $textBrush = New-Brush "#0F172A"
  $g.DrawString($title, $titleFont, $textBrush, $x + 22, $y + 16)
}

function Draw-Card($g, $title, $body, $x, $y, $w, $h, $fill, $stroke, $titleColor = "#0F172A") {
  $shadowBrush = New-Brush "#17000000"
  $cardBrush = New-Brush $fill
  $pen = New-Pen $stroke 2.2
  $textBrush = New-Brush "#334155"
  $titleBrush = New-Brush $titleColor

  Fill-RoundRect $g $shadowBrush ($x + 6) ($y + 8) $w $h 18 | Out-Null
  $path = Fill-RoundRect $g $cardBrush $x $y $w $h 18
  $g.DrawPath($pen, $path)

  $titleFont = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
  $bodyFont = New-Object System.Drawing.Font("Segoe UI", 11)

  $g.DrawString($title, $titleFont, $titleBrush, $x + 16, $y + 14)

  $rect = New-Object System.Drawing.RectangleF ($x + 16), ($y + 46), ($w - 30), ($h - 56)
  $format = New-Object System.Drawing.StringFormat
  $format.Trimming = [System.Drawing.StringTrimming]::Word
  $g.DrawString($body, $bodyFont, $textBrush, $rect, $format)
}

function Draw-Arrow($g, $x1, $y1, $x2, $y2, $color, $label = "", $dashed = $false) {
  $pen = New-Pen $color 4
  if ($dashed) {
    $pen.DashStyle = [System.Drawing.Drawing2D.DashStyle]::Dash
  }

  $cap = New-Object System.Drawing.Drawing2D.AdjustableArrowCap 6, 8, $true
  $pen.CustomEndCap = $cap

  $g.DrawLine($pen, $x1, $y1, $x2, $y2)

  if ($label -ne "") {
    $font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $brush = New-Brush "#0F172A"
    $labelBrush = New-Brush "#FFFFFF"

    $midX = ($x1 + $x2) / 2
    $midY = ($y1 + $y2) / 2

    $size = $g.MeasureString($label, $font)
    $boxW = $size.Width + 18
    $boxH = $size.Height + 8
    $boxX = $midX - ($boxW / 2)
    $boxY = $midY - ($boxH / 2) - 10

    $path = Fill-RoundRect $g $labelBrush $boxX $boxY $boxW $boxH 10
    $labelPen = New-Pen "#CBD5E1" 1
    $g.DrawPath($labelPen, $path)
    $g.DrawString($label, $font, $brush, $boxX + 9, $boxY + 4)
  }
}

function Draw-Note($g, $text, $x, $y, $w, $h) {
  $brush = New-Brush "#FFF7ED"
  $pen = New-Pen "#FB923C" 2
  $path = Fill-RoundRect $g $brush $x $y $w $h 18
  $g.DrawPath($pen, $path)

  $titleFont = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
  $bodyFont = New-Object System.Drawing.Font("Segoe UI", 10)
  $textBrush = New-Brush "#7C2D12"

  $g.DrawString("Main Flow", $titleFont, $textBrush, $x + 14, $y + 10)
  $rect = New-Object System.Drawing.RectangleF ($x + 14), ($y + 34), ($w - 24), ($h - 40)
  $g.DrawString($text, $bodyFont, $textBrush, $rect)
}

$graphics.Clear([System.Drawing.ColorTranslator]::FromHtml("#F8FAFC"))

$bgBrush1 = New-Brush "#E0F2FE"
$bgBrush2 = New-Brush "#F5F3FF"
$graphics.FillEllipse($bgBrush1, -120, -80, 900, 500)
$graphics.FillEllipse($bgBrush2, 1350, 920, 900, 520)

$headerFont = New-Object System.Drawing.Font("Segoe UI", 28, [System.Drawing.FontStyle]::Bold)
$subFont = New-Object System.Drawing.Font("Segoe UI", 13)
$darkBrush = New-Brush "#0F172A"
$mutedBrush = New-Brush "#475569"

$graphics.DrawString("KineSentry Overall System Architecture", $headerFont, $darkBrush, 70, 36)
$graphics.DrawString("Smart glove sensors -> ESP32 hub -> BLE mobile app -> alerts, analytics, and cloud reports", $subFont, $mutedBrush, 72, 86)

Draw-Section $graphics "1. Smart Glove" 60 150 610 1010 "#EFF6FF" "#60A5FA"
Draw-Section $graphics "2. Smart Hub" 790 150 610 1010 "#ECFDF5" "#4ADE80"
Draw-Section $graphics "3. Flutter App + Services" 1510 150 620 1010 "#FAF5FF" "#C084FC"

Draw-Card $graphics "MAX30102 Sensor" "Measures heart rate and SpO2 continuously from the patient." 95 230 250 120 "#FFF7E6" "#F59E0B"
Draw-Card $graphics "LM35 Sensor" "Reads body temperature for fever and thermal monitoring." 375 230 250 120 "#FFF7E6" "#F59E0B"
Draw-Card $graphics "MPU6050 Sensor" "Captures hand movement, tilt, gesture direction, and fall motion." 235 380 250 130 "#FFF7E6" "#F59E0B"
Draw-Card $graphics "ESP32 Glove Controller" "Collects all sensor data, detects water / washroom / food gestures, detects fall, estimates battery, and packages live readings." 145 580 430 170 "#DBEAFE" "#2563EB"
Draw-Card $graphics "Glove Output" "OLED display\nBuzzer alert\nStatus LED" 95 800 220 130 "#DCFCE7" "#16A34A"
Draw-Card $graphics "Power Saving" "Idle deep sleep mode to reduce glove power usage." 355 800 220 130 "#DCFCE7" "#16A34A"
Draw-Card $graphics "Patient Wearing Smart Glove" "The patient triggers live health readings and gesture-based help requests." 145 975 430 120 "#FFFFFF" "#94A3B8"

Draw-Card $graphics "ESP32 Hub Receiver" "Receives ESP-NOW packets from the glove and maintains the glove peer connection." 825 250 540 130 "#DBEAFE" "#2563EB"
Draw-Card $graphics "Hub Processing" "Stabilizes battery values, controls gesture / fall indicators, manages sleep state, and prepares outgoing BLE data." 825 450 540 150 "#DCFCE7" "#16A34A"
Draw-Card $graphics "BLE GATT Server" "Exposes notify and write characteristics so the app can receive vitals and send commands." 825 675 540 130 "#EDE9FE" "#7C3AED"
Draw-Card $graphics "Hub Output" "OLED screen\nConnection LED\nGesture LED\nFall LED\nBuzzer\nPair button" 825 875 255 180 "#FFFFFF" "#94A3B8"
Draw-Card $graphics "Hub Deep Sleep" "Enters power save mode when enabled and idle." 1110 875 255 180 "#FFFFFF" "#94A3B8"

Draw-Card $graphics "Bluetooth Layer" "Scans nearby hub devices, connects over BLE, listens to notifications, and sends control commands." 1545 225 255 150 "#F3E8FF" "#9333EA"
Draw-Card $graphics "Parser + Data Service" "Converts BLE payload into structured live data, stores history, session samples, and alert history." 1830 225 255 150 "#F3E8FF" "#9333EA"
Draw-Card $graphics "Health Rules + ML Insight" "Evaluates patient status, thresholds, risk score, and predicted next vital trends." 1545 430 255 150 "#F3E8FF" "#9333EA"
Draw-Card $graphics "UI Screens" "Dashboard\nAlerts\nBluetooth\nReports\nSettings\nLogin / Team" 1830 430 255 150 "#F3E8FF" "#9333EA"
Draw-Card $graphics "Alert Layer" "Voice alerts, sound alerts, and local notifications for fall, gesture, and battery events." 1545 650 255 145 "#F3E8FF" "#9333EA"
Draw-Card $graphics "Reports Layer" "Builds PDF reports and syncs saved report samples to Firebase Firestore." 1830 650 255 145 "#F3E8FF" "#9333EA"
Draw-Card $graphics "Settings + Session Control" "Deep sleep toggle, speaker handling, dummy data mode, logout flow, and BLE cleanup." 1688 865 255 150 "#F3E8FF" "#9333EA"

Draw-Card $graphics "Firebase Auth" "User login access control for the app." 1545 1085 255 90 "#FEE2E2" "#DC2626"
Draw-Card $graphics "Cloud Firestore" "Stores previous generated reports under users/{uid}/reports." 1830 1085 255 90 "#FEE2E2" "#DC2626"

Draw-Arrow $graphics 345 290 360 290 "#F59E0B"
Draw-Arrow $graphics 485 350 485 380 "#F59E0B"
Draw-Arrow $graphics 220 350 220 430 "#F59E0B"
Draw-Arrow $graphics 360 510 360 580 "#2563EB"
Draw-Arrow $graphics 280 750 205 800 "#16A34A"
Draw-Arrow $graphics 440 750 465 800 "#16A34A"

Draw-Arrow $graphics 575 665 825 315 "#0EA5E9" "ESP-NOW"
Draw-Arrow $graphics 1095 380 1095 450 "#16A34A"
Draw-Arrow $graphics 1095 600 1095 675 "#7C3AED"
Draw-Arrow $graphics 960 825 960 875 "#64748B"
Draw-Arrow $graphics 1230 825 1238 875 "#64748B"

Draw-Arrow $graphics 1365 740 1545 300 "#7C3AED" "BLE Notifications"
Draw-Arrow $graphics 1800 300 1830 300 "#7C3AED"
Draw-Arrow $graphics 1672 375 1672 430 "#9333EA"
Draw-Arrow $graphics 1958 375 1958 430 "#9333EA"
Draw-Arrow $graphics 1672 580 1672 650 "#9333EA"
Draw-Arrow $graphics 1958 580 1958 650 "#9333EA"
Draw-Arrow $graphics 1815 940 1815 1085 "#DC2626"
Draw-Arrow $graphics 1700 940 1672 1085 "#DC2626"
Draw-Arrow $graphics 1815 865 1365 740 "#EC4899" "SLEEP_MODE / SPEAKER_ACK / APP_LOGOUT" $true
Draw-Arrow $graphics 980 675 575 665 "#22C55E" "Deep Sleep Control" $true

Draw-Note $graphics "Glove sensors collect health + motion signals. The glove ESP32 detects gestures and falls, sends packets to the hub through ESP-NOW, the hub forwards live data to the Flutter app over BLE, and the app triggers alerts, analytics, and cloud report storage." 725 1210 760 120

$pngCodec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq "image/png" }
$jpgCodec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq "image/jpeg" }

$pngParams = New-Object System.Drawing.Imaging.EncoderParameters 1
$pngParams.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter ([System.Drawing.Imaging.Encoder]::ColorDepth), 32L

$jpgParams = New-Object System.Drawing.Imaging.EncoderParameters 1
$jpgParams.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter ([System.Drawing.Imaging.Encoder]::Quality), 92L

$bmp.Save($pngPath, $pngCodec, $pngParams)
$bmp.Save($jpgPath, $jpgCodec, $jpgParams)

$graphics.Dispose()
$bmp.Dispose()

Write-Output "Created:"
Write-Output $pngPath
Write-Output $jpgPath
