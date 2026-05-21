# Converts the two iOS signing artifacts (distribution .p12 + .mobileprovision)
# into the base64 strings release-ipa.yml expects as GitHub Secrets.
# Optionally also handles the App Store Connect API .p8 key.
#
# Usage:
#   pwsh -File scripts/prep_ios_release_secrets.ps1 `
#     -P12Path "C:\path\to\distribution.p12" `
#     -ProfilePath "C:\path\to\affinity.mobileprovision" `
#     [-AscKeyPath "C:\path\to\AuthKey_XXXXXXXXXX.p8"]
#
# Output: prints the base64 values + names. Copy each into
#   Repo Settings → Secrets and variables → Actions
# matching the secret name on the left.

param(
    [Parameter(Mandatory=$true)]
    [string]$P12Path,

    [Parameter(Mandatory=$true)]
    [string]$ProfilePath,

    [string]$AscKeyPath
)

foreach ($path in @($P12Path, $ProfilePath)) {
    if (-not (Test-Path $path)) {
        Write-Host "::: Required file does not exist: $path" -ForegroundColor Red
        exit 1
    }
}

$P12Base64     = [Convert]::ToBase64String([IO.File]::ReadAllBytes($P12Path))
$ProfileBase64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes($ProfilePath))

Write-Host ""
Write-Host "::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::" -ForegroundColor Green
Write-Host "::: GitHub Secrets to paste at:" -ForegroundColor Green
Write-Host "::: https://github.com/adambrookssolution-sketch/Flutter-dating-app/settings/secrets/actions" -ForegroundColor Green
Write-Host "::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::" -ForegroundColor Green
Write-Host ""
Write-Host "IOS_DIST_CERT_P12_BASE64" -ForegroundColor Cyan
Write-Host $P12Base64
Write-Host ""
Write-Host "IOS_PROVISIONING_PROFILE_BASE64" -ForegroundColor Cyan
Write-Host $ProfileBase64
Write-Host ""
Write-Host "::: You also need to paste these manually (no base64 needed):" -ForegroundColor Cyan
Write-Host "  IOS_DIST_CERT_PASSWORD  — the password you set when exporting the .p12 from Keychain"
Write-Host "  IOS_TEAM_ID             — VTP3W3Y6FA (Affinity Apple Developer team)"
Write-Host ""

if ($AscKeyPath) {
    if (-not (Test-Path $AscKeyPath)) {
        Write-Host "::: ASC key path provided but does not exist: $AscKeyPath" -ForegroundColor Red
        exit 1
    }
    $AscBase64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes($AscKeyPath))
    $AscFileName = Split-Path $AscKeyPath -Leaf
    # filename pattern: AuthKey_<KEY_ID>.p8
    $AscKeyId = $null
    if ($AscFileName -match 'AuthKey_(.+)\.p8') {
        $AscKeyId = $Matches[1]
    }
    Write-Host "::: Optional — App Store Connect upload (enables TestFlight automation):" -ForegroundColor Green
    Write-Host ""
    Write-Host "APP_STORE_CONNECT_API_KEY_BASE64" -ForegroundColor Cyan
    Write-Host $AscBase64
    Write-Host ""
    if ($AscKeyId) {
        Write-Host "APP_STORE_CONNECT_KEY_ID" -ForegroundColor Cyan
        Write-Host $AscKeyId
        Write-Host ""
    }
    Write-Host "::: Also needed (from App Store Connect → Users and Access → Keys):" -ForegroundColor Cyan
    Write-Host "  APP_STORE_CONNECT_ISSUER_ID — UUID at the top of the Keys page"
    Write-Host ""
}

Write-Host "::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::" -ForegroundColor Yellow
Write-Host "::: Keep the .p12 + .mobileprovision + .p8 files OUT of the repo." -ForegroundColor Yellow
Write-Host "::: They are gitignored by pattern (*.p12, *.p8, *.mobileprovision)." -ForegroundColor Yellow
Write-Host "::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::" -ForegroundColor Yellow
