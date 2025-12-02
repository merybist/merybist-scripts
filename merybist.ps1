$apps = @(
    @{
        name = "Chrome"
        url = "https://dl.google.com/chrome/install/latest/chrome_installer.exe"
        args = "/silent /install"
    },
    @{
        name = "WinRAR"
        url = "https://www.rarlab.com/rar/winrar-x64-713uk.exe"
        args = "/S"
    },
    @{
        name = "Dolphin Emulator"
        url = "https://dl.dolphin-emu.org/releases/dolphin-x64-latest.exe"
        args = "/S"
    },
    @{
        name = "Telegram"
        url = "https://telegram.org/dl/desktop/win"
        args = ""
    }
)

foreach ($app in $apps) {
    Write-Host "`nDownloading $($app.name)..."
    $path = "$env:TEMP\$($app.name).exe"
    
    try {
        Invoke-WebRequest $app.url -OutFile $path -UseBasicParsing
        Write-Host "Downloaded $($app.name)."
    }
    catch {
        Write-Host "ERROR downloading $($app.name): $_"
        continue
    }

    Write-Host "Installing $($app.name)..."

    try {
        if ($app.args -ne "") {
            Start-Process $path -ArgumentList $app.args -Wait
        }
        else {
            Start-Process $path
        }
    }
    catch {
        Write-Host "ERROR installing $($app.name): $_"
    }
}

Write-Host "`nAll tasks finished by merybist"
