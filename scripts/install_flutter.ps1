$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

$version = "3.41.7"
$zipUrl  = "https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_${version}-stable.zip"
$zipPath = "D:\flutter_windows.zip"
$extractDir = "D:\"
$flutterDir = "D:\flutter"

if (Test-Path $flutterDir) {
    Write-Host "Removing existing $flutterDir for clean install..."
    Remove-Item -Recurse -Force $flutterDir
}

if (-not (Test-Path $zipPath)) {
    Write-Host "Downloading Flutter $version (about 1 GB)..."
    Invoke-WebRequest -Uri $zipUrl -OutFile $zipPath -UseBasicParsing
    Write-Host "Download complete."
} else {
    $sizeMB = [math]::Round((Get-Item $zipPath).Length / 1MB, 2)
    Write-Host "Existing zip found ($sizeMB MB) - reusing."
}

Write-Host "Extracting to $extractDir ..."
Expand-Archive -Path $zipPath -DestinationPath $extractDir -Force

if (-not (Test-Path "$flutterDir\bin\flutter.bat")) {
    throw "Extraction failed - flutter.bat not found at $flutterDir\bin\"
}

Write-Host ""
Write-Host "=== Verifying installation ==="
& "$flutterDir\bin\flutter.bat" --version

Write-Host ""
Write-Host "=== DONE ==="
Write-Host "Flutter installed at: $flutterDir"
Write-Host "Add to PATH: $flutterDir\bin"
