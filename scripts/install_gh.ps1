$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

$url = "https://github.com/cli/cli/releases/download/v2.62.0/gh_2.62.0_windows_amd64.msi"
$out = "D:\gh-cli.msi"

Write-Host "Downloading GitHub CLI..."
Invoke-WebRequest -Uri $url -OutFile $out -UseBasicParsing

Write-Host "Installing..."
Start-Process msiexec.exe -ArgumentList "/i", $out, "/quiet", "/norestart" -Wait

Write-Host "Done. Checking..."
$ghPath = "C:\Program Files\GitHub CLI\gh.exe"
if (Test-Path $ghPath) {
    & $ghPath --version
    Write-Host "SUCCESS"
} else {
    Write-Host "FAILED: gh.exe not found at $ghPath"
}
