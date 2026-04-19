# Installs Android NDK 28.2.13676358 via sdkmanager.
#
# Required by the `jni` Flutter plugin (transitive dep of path_provider_android).
# Gradle auto-download failed earlier because C drive had no space.

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

$sdkRoot = "C:\Users\Administrator\AppData\Local\Android\sdk"
$ndkTarget = "28.2.13676358"
$cmdlineZipUrl = "https://dl.google.com/android/repository/commandlinetools-win-11076708_latest.zip"
$cmdlineZipPath = "D:\cmdline-tools.zip"
$cmdlineTempDir = "D:\cmdline-tools-temp"
$cmdlineFinalDir = Join-Path $sdkRoot "cmdline-tools\latest"

Write-Host "=== Android NDK installer ==="
Write-Host "SDK root: $sdkRoot"
Write-Host "NDK target: $ndkTarget"

$ndkStub = Join-Path $sdkRoot "ndk\$ndkTarget"
if (Test-Path $ndkStub) {
    $files = Get-ChildItem $ndkStub -ErrorAction SilentlyContinue
    if (-not $files -or $files.Count -lt 5) {
        Write-Host "Removing corrupt NDK stub at $ndkStub..."
        Remove-Item -Recurse -Force $ndkStub
    }
}

if (-not (Test-Path (Join-Path $cmdlineFinalDir "bin\sdkmanager.bat"))) {
    if (-not (Test-Path $cmdlineZipPath)) {
        Write-Host "Downloading Android SDK command-line tools (about 170 MB)..."
        Invoke-WebRequest -Uri $cmdlineZipUrl -OutFile $cmdlineZipPath -UseBasicParsing
    } else {
        Write-Host "Reusing existing cmdline-tools zip at $cmdlineZipPath"
    }

    if (Test-Path $cmdlineTempDir) { Remove-Item -Recurse -Force $cmdlineTempDir }
    Write-Host "Extracting..."
    Expand-Archive -Path $cmdlineZipPath -DestinationPath $cmdlineTempDir -Force

    $extractedTools = Join-Path $cmdlineTempDir "cmdline-tools"
    if (-not (Test-Path $extractedTools)) {
        throw "Unexpected zip layout: cmdline-tools subdir not found"
    }

    New-Item -ItemType Directory -Force -Path (Join-Path $sdkRoot "cmdline-tools") | Out-Null
    if (Test-Path $cmdlineFinalDir) { Remove-Item -Recurse -Force $cmdlineFinalDir }
    Move-Item -Path $extractedTools -Destination $cmdlineFinalDir
    Remove-Item -Recurse -Force $cmdlineTempDir
    Write-Host "cmdline-tools installed at $cmdlineFinalDir"
} else {
    Write-Host "cmdline-tools already installed."
}

$sdkmanager = Join-Path $cmdlineFinalDir "bin\sdkmanager.bat"

Write-Host ""
Write-Host "=== Accepting SDK licenses ==="
$env:ANDROID_HOME = $sdkRoot
$env:ANDROID_SDK_ROOT = $sdkRoot
"y`ny`ny`ny`ny`ny`ny`ny`ny`ny`ny`ny`ny`ny`ny`n" | & $sdkmanager --licenses 2>&1 | Select-Object -Last 5

Write-Host ""
Write-Host "=== Installing NDK $ndkTarget (about 1 GB, takes a few minutes) ==="
& $sdkmanager --install "ndk;$ndkTarget" 2>&1 | Select-Object -Last 10

Write-Host ""
Write-Host "=== Verifying ==="
$srcProps = Join-Path $sdkRoot "ndk\$ndkTarget\source.properties"
if (Test-Path $srcProps) {
    Write-Host "SUCCESS: $srcProps exists."
    Get-Content $srcProps | Select-Object -First 5
} else {
    throw "FAILED: $srcProps missing."
}
