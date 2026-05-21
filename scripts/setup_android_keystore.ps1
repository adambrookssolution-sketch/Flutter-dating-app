# Generates the Affinity Android upload keystore + prints the four
# values that go into GitHub Secrets so release-aab.yml can sign the
# Play Store AAB. Run once on the operator's machine. Save the .jks
# file somewhere safe (1Password / backup drive) — if it's lost,
# Play Store will refuse all future updates to this app forever.
#
# Usage:
#   pwsh -File scripts/setup_android_keystore.ps1
#
# Output: prints the four secret values. Copy each line into
#   Repo Settings → Secrets and variables → Actions → New repository secret
# matching the secret name on the left.

param(
    [string]$KeystoreOutPath = "$HOME\affinity-upload.jks",
    [string]$KeyAlias = "affinity-upload",
    [string]$DistinguishedName = "CN=Affinity, O=Affinity Social Club, C=MX"
)

if (Test-Path $KeystoreOutPath) {
    Write-Host "::: A keystore already exists at $KeystoreOutPath." -ForegroundColor Yellow
    Write-Host "::: Delete it manually if you want to regenerate. Aborting to avoid clobbering the existing key." -ForegroundColor Yellow
    exit 1
}

# Strong random password — 32 hex chars, no shell-unsafe characters.
$bytes = New-Object byte[] 16
[System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
$KeystorePassword = -join ($bytes | ForEach-Object { '{0:x2}' -f $_ })

Write-Host "::: Generating keystore at $KeystoreOutPath ..." -ForegroundColor Cyan
$keytoolArgs = @(
    "-genkeypair", "-v",
    "-keystore", $KeystoreOutPath,
    "-alias", $KeyAlias,
    "-keyalg", "RSA", "-keysize", "2048", "-validity", "10000",
    "-storepass", $KeystorePassword,
    "-keypass",  $KeystorePassword,
    "-dname", $DistinguishedName
)
& keytool @keytoolArgs
if ($LASTEXITCODE -ne 0) {
    Write-Host "::: keytool failed. Make sure Java JDK 17+ is on PATH (try: keytool -help)." -ForegroundColor Red
    exit 1
}

$KeystoreBase64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes($KeystoreOutPath))

Write-Host ""
Write-Host "::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::" -ForegroundColor Green
Write-Host "::: GitHub Secrets to paste at:" -ForegroundColor Green
Write-Host "::: https://github.com/adambrookssolution-sketch/Flutter-dating-app/settings/secrets/actions" -ForegroundColor Green
Write-Host "::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::" -ForegroundColor Green
Write-Host ""
Write-Host "RELEASE_KEYSTORE_BASE64" -ForegroundColor Cyan
Write-Host $KeystoreBase64
Write-Host ""
Write-Host "RELEASE_KEYSTORE_PASSWORD" -ForegroundColor Cyan
Write-Host $KeystorePassword
Write-Host ""
Write-Host "RELEASE_KEY_ALIAS" -ForegroundColor Cyan
Write-Host $KeyAlias
Write-Host ""
Write-Host "RELEASE_KEY_PASSWORD" -ForegroundColor Cyan
Write-Host $KeystorePassword
Write-Host ""
Write-Host "::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::" -ForegroundColor Yellow
Write-Host "::: BACK UP $KeystoreOutPath NOW." -ForegroundColor Yellow
Write-Host "::: Losing it = Play Store refuses every future update of this app." -ForegroundColor Yellow
Write-Host "::: Recommended: copy to 1Password / encrypted USB, plus save the" -ForegroundColor Yellow
Write-Host "::: password above in the same vault." -ForegroundColor Yellow
Write-Host "::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::" -ForegroundColor Yellow

# Print the SHA-1 of the upload cert — needed if you ever register
# this keystore with Firebase (you usually don't, since the debug
# keystore is what Google Sign-In uses; but Play Console asks for it
# when registering for app signing).
Write-Host ""
Write-Host "::: Upload cert SHA-1 (for Play Console app-signing registration):" -ForegroundColor Cyan
$shaArgs = @("-list", "-v", "-keystore", $KeystoreOutPath, "-alias", $KeyAlias, "-storepass", $KeystorePassword)
(& keytool @shaArgs) -match "SHA1:" | ForEach-Object { Write-Host $_.Trim() }
