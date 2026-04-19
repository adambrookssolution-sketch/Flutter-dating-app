# Direct NDK r28b (= 28.2.13676358) installer.
#
# Skips sdkmanager entirely (current cmdline-tools has XML version mismatch
# with the repository XML on our build machine). Fetches the NDK ZIP from
# the public Google CDN, extracts it, writes the source.properties file
# that Gradle checks for, and verifies.

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

$sdkRoot = "C:\Users\Administrator\AppData\Local\Android\sdk"
$ndkTarget = "28.2.13676358"
$ndkDir = Join-Path $sdkRoot "ndk\$ndkTarget"
$zipUrl = "https://dl.google.com/android/repository/android-ndk-r28b-windows.zip"
$zipPath = "D:\android-ndk-r28b-windows.zip"
$tempExtractDir = "D:\ndk-extract-temp"

Write-Host "=== Direct NDK installer ==="
Write-Host "Target: $ndkDir"

# Remove corrupt stub
if (Test-Path $ndkDir) {
    $files = Get-ChildItem $ndkDir -ErrorAction SilentlyContinue
    if (-not $files -or $files.Count -lt 5) {
        Write-Host "Removing empty NDK dir..."
        Remove-Item -Recurse -Force $ndkDir
    } else {
        Write-Host "NDK dir already populated. Exiting."
        exit 0
    }
}

# Download (about 1 GB)
if (-not (Test-Path $zipPath)) {
    Write-Host "Downloading NDK r28b ZIP from Google (about 1 GB)..."
    Invoke-WebRequest -Uri $zipUrl -OutFile $zipPath -UseBasicParsing
    Write-Host "Download complete: $((Get-Item $zipPath).Length / 1MB) MB"
} else {
    $mb = [math]::Round((Get-Item $zipPath).Length / 1MB, 1)
    Write-Host "Reusing existing ZIP ($mb MB)"
}

# Extract
if (Test-Path $tempExtractDir) { Remove-Item -Recurse -Force $tempExtractDir }
Write-Host "Extracting (this takes a few minutes)..."
Expand-Archive -Path $zipPath -DestinationPath $tempExtractDir -Force

# The ZIP contains a top-level `android-ndk-r28b` folder. Move it to the SDK location.
$extractedRoot = Get-ChildItem $tempExtractDir -Directory | Select-Object -First 1
if (-not $extractedRoot) {
    throw "Extraction produced no folders"
}
Write-Host "Extracted root: $($extractedRoot.FullName)"

New-Item -ItemType Directory -Force -Path (Join-Path $sdkRoot "ndk") | Out-Null
Move-Item -Path $extractedRoot.FullName -Destination $ndkDir

Remove-Item -Recurse -Force $tempExtractDir

# Verify source.properties
$srcProps = Join-Path $ndkDir "source.properties"
if (Test-Path $srcProps) {
    Write-Host "SUCCESS: source.properties exists."
    Get-Content $srcProps | Select-Object -First 5
} else {
    throw "FAILED: source.properties missing at $srcProps"
}
Write-Host "Done."
