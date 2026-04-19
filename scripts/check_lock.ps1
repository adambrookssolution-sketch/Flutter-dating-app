$files = @(
    'D:\app\assets\images\icon_help.png',
    'D:\app\assets\images\apple.svg',
    'D:\app\assets\images\forgot_password_code.png',
    'D:\app\assets\images\icon_security.png'
)
foreach ($f in $files) {
    try {
        $fs = [System.IO.File]::Open($f, 'Open', 'Read', 'None')
        Write-Host "FREE: $f"
        $fs.Close()
    } catch {
        Write-Host "LOCKED: $f - $($_.Exception.Message)"
    }
}
