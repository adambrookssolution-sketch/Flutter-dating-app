# Helper script: build APK and install it on LDPlayer via ADB.
#
# Usage:
#   powershell -ExecutionPolicy Bypass -File D:\app\scripts\install_to_ldplayer.ps1
#
# Requires:
#   - Flutter installed at D:\flutter
#   - LDPlayer running with ADB debugging enabled
#   - ADB available on PATH (LDPlayer ships with adb.exe; Android Studio also)

$ErrorActionPreference = "Stop"

# LDPlayer common ADB ports — try them in order until one connects.
$ports = @(5555, 5554, 5556, 5557, 5558, 5559, 5560, 5561, 5562, 5563, 7555)

# Find adb.exe
$adb = $null
$candidates = @(
  "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe",
  "$env:USERPROFILE\AppData\Local\Android\Sdk\platform-tools\adb.exe",
  "C:\Program Files\LDPlayer\LDPlayer9\adb.exe",
  "C:\LDPlayer\LDPlayer9\adb.exe",
  "D:\LDPlayer\LDPlayer9\adb.exe"
)
foreach ($c in $candidates) {
  if (Test-Path $c) { $adb = $c; break }
}
if (-not $adb) {
  $cmdAdb = (Get-Command adb -ErrorAction SilentlyContinue)
  if ($cmdAdb) { $adb = $cmdAdb.Source }
}
if (-not $adb) {
  Write-Host "ERROR: adb.exe not found. Install Android platform-tools or specify LDPlayer's adb path."
  exit 1
}
Write-Host "Using adb: $adb"

# Try to connect to LDPlayer
$connected = $null
foreach ($p in $ports) {
  Write-Host "Trying 127.0.0.1:$p ..."
  $result = & $adb connect "127.0.0.1:$p" 2>&1
  Write-Host "  $result"
  if ($result -match "connected to") {
    $connected = "127.0.0.1:$p"
    break
  }
}
if (-not $connected) {
  Write-Host "ERROR: Could not connect to LDPlayer ADB. Make sure LDPlayer is running and ADB debugging is enabled."
  exit 1
}
Write-Host "Connected to: $connected"

# Show devices
& $adb devices

# Build the APK
Write-Host ""
Write-Host "=== Building debug APK ==="
& "D:\flutter\bin\flutter.bat" build apk --debug
if ($LASTEXITCODE -ne 0) {
  Write-Host "ERROR: Flutter build failed."
  exit 1
}

$apkPath = "D:\app\build\app\outputs\flutter-apk\app-debug.apk"
if (-not (Test-Path $apkPath)) {
  Write-Host "ERROR: APK not found at $apkPath"
  exit 1
}
$apkSizeMB = [math]::Round((Get-Item $apkPath).Length / 1MB, 2)
Write-Host "Built APK: $apkPath ($apkSizeMB MB)"

# Install
Write-Host ""
Write-Host "=== Installing to $connected ==="
& $adb -s $connected install -r $apkPath
if ($LASTEXITCODE -ne 0) {
  Write-Host "ERROR: Install failed."
  exit 1
}

Write-Host ""
Write-Host "=== DONE ==="
Write-Host "Affinity is now installed on LDPlayer ($connected)."
Write-Host "Launch it from the LDPlayer home screen, or run:"
Write-Host "  $adb -s $connected shell am start -n com.affinitysocialclub.app/.MainActivity"
