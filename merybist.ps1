
$downloadDir = "C:\Installers"
if (!(Test-Path $downloadDir)) {
    New-Item -ItemType Directory -Path $downloadDir | Out-Null
}

$apps = @(
    @{
        name = "Chrome"
        url = "https://dl.google.com/chrome/install/latest/chrome_installer.exe"
        args = "/silent /install"
        check = { Get-Command "chrome.exe" -ErrorAction SilentlyContinue }
    },
    @{
        name = "WinRAR"
        url = "https://www.rarlab.com/rar/winrar-x64-713uk.exe"
        args = "/S"
        check = { Get-Command "winrar.exe" -ErrorAction SilentlyContinue }
    },
    @{
        name = "Telegram"
        url = "https://telegram.org/dl/desktop/win"
        args = ""
        check = { Get-Command "telegram.exe" -ErrorAction SilentlyContinue }
    },
    @{
        name = "Dolphin Emulator"
        url = "https://dl.dolphin-emu.org/releases/dolphin-x64-latest.exe"
        args = "/S"
        check = { Get-Command "dolphin.exe" -ErrorAction SilentlyContinue }
    },
    @{
        name = "Visual Studio Code"
        url = "https://update.code.visualstudio.com/latest/win32-x64-user/stable"
        args = "/silent"
        check = { Get-Command "code.exe" -ErrorAction SilentlyContinue }
    },
    @{
        name = "Spotify"
        url = "https://download.scdn.co/SpotifySetup.exe"
        args = "/silent"
        check = { Get-Command "spotify.exe" -ErrorAction SilentlyContinue }
    }
)

foreach ($app in $apps) {
    $path = "$downloadDir\$($app.name).exe"

    if (& $app.check) {
        Write-Host "`nSkipping $($app.name), already installed."
        continue
    }

    if (Test-Path $path) {
        Write-Host "`nSkipping download for $($app.name), file already exists."
    }
    else {
        Write-Host "`nDownloading $($app.name)..."
        try {
            Invoke-WebRequest $app.url -OutFile $path -UseBasicParsing
            Write-Host "Downloaded $($app.name)."
        }
        catch {
            Write-Host "ERROR downloading $($app.name): $_"
            continue
        }
    }

    Write-Host "Installing $($app.name)..."
    try {
        if ($app.args -ne "") {
            Start-Process $path -ArgumentList $app.args -Wait
        }
        else {
            Start-Process $path -Wait
        }
    }
    catch {
        Write-Host "ERROR installing $($app.name): $_"
    }
}

Write-Host "`nAll tasks finished by merybist"
